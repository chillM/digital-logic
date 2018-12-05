#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <fcntl.h> 
#include <sys/stat.h> 
#include <sys/types.h> 
#include <unistd.h> 
#include  <vpi_user.h>
#include "acc_user.h"
#include "veriuser.h"
#include <pthread.h>
#include <stdlib.h>

#include <string.h> 
#include <sys/types.h> 
#include <sys/socket.h> 
#include <arpa/inet.h> 
#include <netinet/in.h> 

#define SERVER_PORT 1182
#define SERVER_BUFFER_SIZE 2048
#define PACKET_TYPE_INPUT 1
#define PACKET_TYPE_DISPLAY 2

uint8_t mode_value;
uint8_t trigger_value;
uint8_t refill_value;
uint8_t target_value;

uint8_t fluid_value;
uint8_t tracer_value;
uint16_t energy_value;
uint8_t shoot_value;

pthread_mutex_t* button_mutex = NULL;

typedef struct
{
	uint8_t fluid;
	uint16_t energy;
	uint8_t tracer;
	uint8_t shoot;
	uint8_t mode;
	uint8_t targets;
}DisplayMessage;


typedef struct
{
	uint8_t mode;
	uint8_t trigger;
	uint8_t refill;
	uint8_t targets;
}ButtonMessage;

static int setDisplayInit(char*user_data)
{
	return 0;
}

static int setDisplay(char* user_data)
{
	pthread_mutex_lock(button_mutex);
	fluid_value = tf_getp(1);
	energy_value = tf_getp(2);
	tracer_value = tf_getp(3);
	pthread_mutex_unlock(button_mutex);
}

void setDisplayRegister()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.tfname    = "$setDisplay";
      tf_data.calltf    = setDisplay;
      tf_data.compiletf = setDisplayInit;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}
	
static int realTimeDelayInit(char*user_data)
{
	return 0;
}

static int realTimeDelay(char*user_data)
{
	int delay;
	delay = tf_getp(1);
	usleep(delay*1000);
	return 0;
}

void realTimeDelayRegister()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.tfname    = "$realTimeDelay";
      tf_data.calltf    = realTimeDelay;
      tf_data.compiletf = realTimeDelayInit;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}

static int getUserInputInit(char*user_data)
{
	return 0;
}

static int getUserInput(char*user_data)
{
	if(button_mutex != NULL)
	{
		pthread_mutex_lock(button_mutex);
		tf_putp(1,(int)mode_value);
		tf_putp(2,(int)trigger_value);
		tf_putp(3,(int)refill_value);
		tf_putp(4,(int)target_value);
		pthread_mutex_unlock(button_mutex);
	}
	//vpi_printf("BOOOOP\n");
}


void getUserInputRegister()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.tfname    = "$getUserInput";
      tf_data.calltf    = getUserInput;
      tf_data.compiletf = getUserInputInit;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}



void* networkThread(void* param)
{
	fluid_value = 64;
	const char* server_name = "localhost";
	char hello[] = "Hi";
	ButtonMessage button_message;
	DisplayMessage display_message;
	uint32_t i;
	uint32_t rx_length;
	int sockfd; 
    char buffer[SERVER_BUFFER_SIZE];
	struct sockaddr_in servaddr;
	struct  sockaddr_in cliaddr;
	vpi_printf("Starting server...\n"); 
	const socklen_t slen = sizeof(struct sockaddr_in);
	
	// Creating socket file descriptor 
    if ( (sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0 ) { 
        vpi_printf("Socket Error!\n");
        exit(EXIT_FAILURE); 
    } 
      
    memset(&servaddr, 0, sizeof(servaddr)); 
    memset(&cliaddr, 0, sizeof(cliaddr)); 
      
    // Filling server information 
    servaddr.sin_family    = AF_INET; // IPv4 
    inet_pton(AF_INET, server_name, &servaddr.sin_addr); 
    servaddr.sin_port = htons(SERVER_PORT);
      
    // Bind the socket with the server address 
    if ( bind(sockfd, (const struct sockaddr *)&servaddr,  
            sizeof(servaddr)) < 0 ) 
    { 
        vpi_printf("Bind Failed!\n"); 
        exit(EXIT_FAILURE); 
    } 
	
	vpi_printf("Socket Created. Server is up!\n");
	int len = sizeof(cliaddr);
	for(i = 0;; i++)
	{
		rx_length = recvfrom(sockfd, buffer, SERVER_BUFFER_SIZE, 0,( struct sockaddr *) &cliaddr, 
                &len);
		//vpi_printf("Got data! %d\n", buffer[0]);
		if(buffer[0] == PACKET_TYPE_INPUT)
		{
			memcpy(&button_message, 1 + buffer, sizeof(ButtonMessage));
			//vpi_printf("I got Mode %05X, refill %d, and trigger %d\n", button_message.mode, button_message.refill,
			//		   button_message.trigger);
			pthread_mutex_lock(button_mutex);
			mode_value = button_message.mode;
			trigger_value = button_message.trigger;
			refill_value = button_message.refill;
			target_value = button_message.targets;
			pthread_mutex_unlock(button_mutex);
			//vpi_printf("%x %s\n", cliaddr.sin_port, inet_ntoa(cliaddr.sin_addr));
		}
		else if(buffer[0] == PACKET_TYPE_DISPLAY)
		{
			fluid_value++;
			//vpi_printf("POOOOOOOOOOOOOOP\n");
			pthread_mutex_lock(button_mutex);
			display_message.fluid = fluid_value;
			display_message.energy = energy_value;
			display_message.tracer = tracer_value;
			display_message.shoot = shoot_value;
			display_message.mode = mode_value;
			display_message.targets = target_value;
			memcpy(buffer, &display_message, sizeof(DisplayMessage));
			pthread_mutex_unlock(button_mutex);
			//vpi_printf("%x %s\n", cliaddr.sin_port, inet_ntoa(cliaddr.sin_addr));
			usleep(30);
			len = sendto(sockfd, buffer,sizeof(DisplayMessage), 0, (const struct sockaddr *) &cliaddr, sizeof(cliaddr));
			//vpi_printf("FFFF %d\n", len);
		}
		usleep(10);
		
	}
}



//Init everything
static int startupInit(char*user_data)
{
	button_mutex = (pthread_mutex_t*)malloc(sizeof(pthread_mutex_t));
	pthread_mutex_init(button_mutex, NULL);
	pthread_t* thread = (pthread_t*)malloc(sizeof(pthread_t));
	vpi_printf("Starting Thread");
	pthread_create(thread, 0, networkThread, NULL);
	return 0;
}

static int startup(char*user_data)
{
	
	return 0;
}

void startUp()
{
	trigger_value = 0;
	mode_value = 0;
	refill_value = 0;
	target_value = 1;
	button_mutex = (pthread_mutex_t*)malloc(sizeof(pthread_mutex_t));
	pthread_mutex_init(button_mutex, NULL);
	pthread_t* thread = (pthread_t*)malloc(sizeof(pthread_t));
	vpi_printf("Starting Thread");
	pthread_create(thread, 0, networkThread, NULL);
}

void startupRegister()
{
	s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.tfname    = "$startup";
      tf_data.calltf    = startup;
      tf_data.compiletf = startupInit;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}

static int get_val_init(char*user_data)
{
	return 0;
}
static int get_val(char*user_data)
{
	int input;
	input = tf_getp(1);
	
	tf_putp(1,10);
	vpi_printf("value sent %d\n", input);
	return 0;
}

void get_register()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.tfname    = "$gv";
      tf_data.calltf    = get_val;
      tf_data.compiletf = get_val_init;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}

static int hello_compiletf(char*user_data)
{
      return 0;
}

static int hello_calltf(char*user_data)
{
      vpi_printf("Hel, World!\n");
      	sleep(1);
      	vpi_printf("Bye!\n");
      return 0;
}

void hello_register()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.tfname    = "$hello";
      tf_data.calltf    = hello_calltf;
      tf_data.compiletf = hello_compiletf;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}



void (*vlog_startup_routines[])() = {
    startUp,
	hello_register,
    get_register,
	getUserInputRegister,
	realTimeDelayRegister,
	setDisplayRegister,
    0
};


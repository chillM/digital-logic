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

#define SERVER_PORT 5125
#define SERVER_BUFFER_SIZE 2048

typedef struct
{
	uint8_t mode;
	uint8_t trigger;
	uint8_t refill;
}ButtonMessage;

void* inputThread(void* param)
{
	
}

void* networkThread(void* param)
{
	uint32_t i;
	int sockfd; 
    char buffer[SERVER_BUFFER_SIZE];
	struct sockaddr_in servaddr, cliaddr;
	
	
	// Creating socket file descriptor 
    if ( (sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0 ) { 
        perror("socket creation failed"); 
        exit(EXIT_FAILURE); 
    } 
      
    memset(&servaddr, 0, sizeof(servaddr)); 
    memset(&cliaddr, 0, sizeof(cliaddr)); 
      
    // Filling server information 
    servaddr.sin_family    = AF_INET; // IPv4 
    servaddr.sin_addr.s_addr = INADDR_ANY; 
    servaddr.sin_port = htons(SERVER_PORT); 
      
    // Bind the socket with the server address 
    if ( bind(sockfd, (const struct sockaddr *)&servaddr,  
            sizeof(servaddr)) < 0 ) 
    { 
        perror("bind failed"); 
        exit(EXIT_FAILURE); 
    } 
	
	
	for(i = 0;; i++)
	{
		vpi_printf("value %d\n", i);
		usleep(10);
		
	}
}



//Init everything
static int startupInit(char*user_data)
{
	pthread_t* thread = (pthread_t*)malloc(sizeof(pthread_t));
	vpi_printf("Starting Thread");
	pthread_create(thread, 0, networkThread, NULL);
	return 0;
}

static int startup(char*user_data)
{
	
	return 0;
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
    hello_register,
    get_register,
    startupRegister,
    0
};

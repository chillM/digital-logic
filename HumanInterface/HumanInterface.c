#include <stdio.h>
#include <stdint.h>
#include <string.h> 
#include <fcntl.h> 
#include <sys/stat.h> 
#include <sys/types.h> 
#include <unistd.h> 
#include <pthread.h>
#include <stdlib.h>

#include <string.h> 
#include <sys/types.h> 
#include <sys/socket.h> 
#include <arpa/inet.h> 
#include <netinet/in.h> 

#include "libenjoy.h"

#define SERVER_PORT 1182
#define SERVER_BUFFER_SIZE 2048
#define PACKET_TYPE_INPUT 0x01


const uint8_t FIRE_MODES[] = {0,1,3,7,6,4,5};

typedef struct
{
	uint8_t mode;
	uint8_t trigger;
	uint8_t refill;
	uint8_t targets;
}ButtonMessage;

typedef struct
{
	int16_t* axis;
	uint8_t* button;
	libenjoy_joystick* joy;
	libenjoy_context* ctx;
	
	
}GamePad;

GamePad* initGamePad(uint8_t buttons, uint8_t axes, libenjoy_joystick* joy, libenjoy_context* ctx)
{
	GamePad* result = (GamePad*)malloc(sizeof(GamePad));
	result->button = (uint8_t*)malloc(sizeof(uint8_t)*buttons);
	result->axis = (int16_t*)malloc(sizeof(uint8_t)*axes);
	result->joy = joy;
	result->ctx = ctx;
	return result;
}

void destroyGamePad(GamePad* game_pad)
{
	free(game_pad->button);
	free(game_pad->axis);
	free(game_pad);
}

void updateGamePad(GamePad* game_pad)
{
	int i;
	libenjoy_event ev;
	while(libenjoy_poll(game_pad->ctx, &ev))
	{
		
		switch(ev.type)
		{
		case LIBENJOY_EV_AXIS:
		{
			game_pad->axis[ev.part_id] = ev.data;
			//printf("%u: axis %d val %d\n", ev.joy_id, ev.part_id, ev.data);
		}break;
		case LIBENJOY_EV_BUTTON:
		{
			game_pad->button[ev.part_id] = ev.data;
			printf("%u: button %d val %d\n", ev.joy_id, ev.part_id, ev.data);
		}break;
		case LIBENJOY_EV_CONNECTED:
		{
			printf("%u: status changed: %d\n", ev.joy_id, ev.data);
		}break;
		}
	}
}


const uint8_t FIRE_BUTTON = 5;
const uint8_t RELOAD_BUTTON = 4;
const uint8_t NEXT_BUTTON = 1;
const uint8_t PREV_BUTTON = 0;
const uint8_t INC_BUTTON = 3;
const uint8_t DEC_BUTTON = 2;


int main()
{
	ButtonMessage button_message;
	uint32_t i;
	uint32_t rx_length;
	int8_t fire_mode = 0;
	uint8_t target_amount = 1;
	int sockfd; 
    char buffer[SERVER_BUFFER_SIZE];
	GamePad* game_pad = NULL;
	struct sockaddr_in servaddr, cliaddr;
	printf("Starting client...\n"); 
	const socklen_t slen = sizeof(struct sockaddr_in);
	
	// Creating socket file descriptor 
    if ( (sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0 ) { 
        printf("Socket Error!\n");
        exit(EXIT_FAILURE); 
    } 
      
    memset(&servaddr, 0, sizeof(servaddr)); 
    memset(&cliaddr, 0, sizeof(cliaddr)); 
      
    // Filling server information 
    servaddr.sin_family    = AF_INET; // IPv4 
    servaddr.sin_addr.s_addr = INADDR_ANY; 
    servaddr.sin_port = htons(SERVER_PORT); 
      
    //Bind the socket with the server address 
	
	//Set up controller
	 libenjoy_context *ctx = libenjoy_init(); // initialize the library
    libenjoy_joy_info_list *info;

    // Updates internal list of joysticks. If you want auto-reconnect
    // after re-plugging the joystick, you should call this every 1s or so
    libenjoy_enumerate(ctx);

    // get list with available joysticks. structs are
    // typedef struct libenjoy_joy_info_list {
    //     uint32_t count;
    //     libenjoy_joy_info **list;
    // } libenjoy_joy_info_list;
    //
    // typedef struct libenjoy_joy_info {
    //     char *name;
    //     uint32_t id;
    //     char opened;
    // } libenjoy_joy_info;
    //
    // id is not linear (eg. you should not use vector or array), 
    // and if you disconnect joystick and then plug it in again,
    // it should have the same ID
    info = libenjoy_get_info_list(ctx);
	
	
	if(info->count != 0) // just get the first joystick
    {
        libenjoy_joystick *joy;
        printf("Opening joystick %s...", info->list[0]->name);
        joy = libenjoy_open_joystick(ctx, info->list[0]->id);
        if(joy)
        {
			uint8_t last_next_state = 0;
			uint8_t last_prev_state = 0;
			uint8_t last_inc_state = 0;
			uint8_t last_dec_state = 0;
            printf("Success! GamePad found!\n");
            printf("Axes: %d btns: %d\n", libenjoy_get_axes_num(joy),libenjoy_get_buttons_num(joy));
			game_pad = initGamePad(libenjoy_get_buttons_num(joy),libenjoy_get_axes_num(joy), joy, ctx);
			sleep(1);
			while(1)
			{
				updateGamePad(game_pad);
				
				if(game_pad->button[NEXT_BUTTON] && game_pad->button[NEXT_BUTTON] != last_next_state)
				{
					if(fire_mode == 6) fire_mode = 0;
					else fire_mode++;
				}
				
				if(game_pad->button[PREV_BUTTON] && game_pad->button[PREV_BUTTON] != last_prev_state)
				{
					if(fire_mode == 0) fire_mode = 6;
					else fire_mode--;
				}
				
				if(game_pad->button[INC_BUTTON] && game_pad->button[INC_BUTTON] != last_inc_state)
				{
					if(target_amount < 16) target_amount++;
				}
				
				if(game_pad->button[DEC_BUTTON] && game_pad->button[DEC_BUTTON] != last_dec_state)
				{
					if(target_amount > 1) target_amount--;
				}
				
				last_next_state = game_pad->button[NEXT_BUTTON];
				last_prev_state = game_pad->button[PREV_BUTTON];
				
				last_inc_state = game_pad->button[INC_BUTTON];
				last_dec_state = game_pad->button[DEC_BUTTON];
				
				buffer[0] = 1;
				button_message.trigger = game_pad->button[5];
				//printf("%d\n", game_pad->button[4]);
				button_message.refill = game_pad->button[4];
				button_message.mode = FIRE_MODES[fire_mode];
				button_message.targets = target_amount;
				memcpy(1 + buffer, &button_message, sizeof(ButtonMessage));
				sendto(sockfd, buffer, 1 + sizeof(ButtonMessage), 0, (const struct sockaddr *) &servaddr, slen);
				usleep(100000);
			}
		}
	}
	
	//Network test
 
	
	buffer[0] = 1;
	button_message.mode = 0;
	button_message.trigger = 0;
	button_message.refill = 1;
	memcpy(1 + buffer, &button_message, sizeof(ButtonMessage));
	sendto(sockfd, buffer, 1 + sizeof(ButtonMessage), MSG_CONFIRM, (const struct sockaddr *) &servaddr, slen);
	usleep(100000);
	
	
	button_message.mode = 0;
	button_message.trigger = 0;
	button_message.refill = 0;
	memcpy(1 + buffer, &button_message, sizeof(ButtonMessage));
	sendto(sockfd, buffer, 1 + sizeof(ButtonMessage), MSG_CONFIRM, (const struct sockaddr *) &servaddr, slen);
	
	
	
	close(sockfd);
	return 0;
}
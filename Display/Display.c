#include <ncurses.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
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

typedef struct
{
	uint8_t fluid;
	uint16_t energy;
	uint8_t tracer;
	uint8_t shoot;
	uint8_t mode;
	uint8_t targets;
}DisplayMessage;

#define SERVER_PORT 1182
#define SERVER_BUFFER_SIZE 2048
#define PACKET_TYPE_INPUT 0x01

int main()
{
	initscr();			/* Start curses mode 		  */
	noecho(); // Don't echo any keypresses
	curs_set(FALSE); // Don't display a cursor
	const uint8_t display_buffer_size = 32;
	char display_buffer[display_buffer_size];
	uint32_t i;
	uint32_t rx_length;
	int8_t fire_mode = 0;
	uint8_t target_amount = 1;
	int sockfd; 
    char buffer[SERVER_BUFFER_SIZE];
	struct sockaddr_in servaddr, cliaddr;
	printf("Starting client...\n"); 
	socklen_t slen = sizeof(struct sockaddr_in);
	DisplayMessage display_message;
	
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
	
	
	//sleep(1);
	printf("Done\n");
	
	int len;
	while(1)
	{
		i++;
		//printf("BOOP\n");
		buffer[0] = 2;
		sendto(sockfd, buffer, 1, 0, (const struct sockaddr *) &servaddr, slen);
		//usleep(5);
		recvfrom(sockfd, buffer, sizeof(DisplayMessage),0, NULL, NULL);
		memcpy(&display_message, buffer, sizeof(DisplayMessage));
		//display resources
		move(0,0);
		sprintf(display_buffer, "Fluid:  %4d", display_message.fluid - 1);
		printw(display_buffer);
		move(1,0);
		sprintf(display_buffer, "Energy: %4d", display_message.energy);
		printw(display_buffer);
		move(2,0);
		sprintf(display_buffer, "Tracer: %4d", display_message.tracer);
		printw(display_buffer);
		
		refresh();
		usleep(66666);
	}
	getch();			/* Wait for user input */
	endwin();			/* End curses mode		  */

	return 0;
}


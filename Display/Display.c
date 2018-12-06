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




const char* MODE_NAMES[] = {"Swing", "Ricochet", "", "Splitter", "Rapid", "Tracer", "Taser", "Grenade"};

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

void shootTracer()
{
	usleep(16666);
	for(int i = 0; i < 20; i++)
	{
		move(8,19+i*2);
		printw("        __");
		move(9,19+i*2);
		printw("  ~~~~~|  |");
		move(10,19+i*2);
		printw("  ~~~~~|  |");
		move(11,19+i*2);
		printw("  ~~~~~|__|");
		usleep(16666);
		refresh();
	}
	move(8,19+38);
	printw("        __");
	move(9,19+38);
	printw("     ~~|  |~");
	move(10,19+38);
	printw("      ~|  |~~");
	move(11,19+38);
	printw("     ~~|__|~");
	refresh();
	usleep(33333);
	for(int i = 0; i < 3; i++)
	{
		move(10,19+38);
		printw("      ~|X-|~~");
		refresh();
		usleep(66666);
		move(10,19+38);
		printw("      ~|XX|~~");
		refresh();
		usleep(66666);
		move(10,19+38);
		printw("      ~|-X|~~");
		refresh();
		usleep(66666);
		move(10,19+38);
		printw("      ~|--|~~");
		refresh();
		usleep(66666);
	}
	move(8,19+38);
	printw("           ");
	move(9,19+38);
	printw("            ");
	move(10,19+38);
	printw("              ");
	move(11,19+38);
	printw("            ");
	refresh();
	usleep(33333);
	
}

void shootSplitter(uint8_t cnt)
{
	move(10,19);
	printw("~~~~~~~~#");
	refresh();
	usleep(16666);
	for(int i = 0; i < 20; i++)
	{
		move(10,19+i*2);
	printw("  ~~~~~~~~#");
	usleep(16666);
		refresh();
	}
	move(10,19+38);
	printw("           ");
	
	for(int i = 0; i < cnt; i++)
	{
		move(7 + 2*(i%4),58 + 2*(i/4));
		printw("X");
		refresh();
		usleep(33333);
	}
	usleep(100000);
	for(int i = 0; i < cnt; i++)
	{
		move(7 + 2*(i%4),58 + 2*(i/4));
		printw(" ");
		refresh();
		usleep(33333);
	}
	
}

void shootRapid()
{
	move(10,19);
	printw("~~~~~~~~#");
	refresh();
	usleep(16666);
	for(int i = 0; i < 20; i++)
	{
		move(10,19+i*2);
	printw("  ~~~~~~~~#");
	usleep(16666);
		refresh();
	}
	move(10,19+38);
	printw("           ");
	
	
}

void shootSwing()
{
	move(10,19);
	printw("#");
	for(int i = 0; i < 20; i++)
	{
		move(10, 19+i);
		printw("~#");
		refresh();
		usleep(16666);  
	}
	for(int i = 0; i < 21; i++)
	{
		move(10, 19+i);
		printw(" ");
		refresh();
		usleep(16666);  
	}
			   
}

void shootRic()
{
	move(10,19);
	printw("#");
	for(int i = 0; i < 8; i++)
	{
		move(10, 19+i);
		printw("~#");
		refresh();
		usleep(16666);  
	}
	for(int i = 0; i < 6; i++)
	{
		move(10+i, 27);
		printw("|");
		move(10+i+1, 27);
		printw("#");
		refresh();
		usleep(16666);  
	}
	for(int i = 0; i < 8; i++)
	{
		move(10, 19+i);
		printw(" ");
		refresh();
		usleep(16666);  
	}
	for(int i = 0; i < 7; i++)
	{
		move(10+i, 27);
		printw(" ");
		refresh();
		usleep(16666);  
	}
}

void shootTaser()
{
	char buffer[16];
	move(10,19);
	for(int i = 0; i < 8; i++)
	{
		buffer[i] = (rand()%(('z' - 'A'))) + 'A';
	}
	buffer[8] = '#';
	buffer[9] = 0;
	printw(buffer);
	refresh();
	usleep(33333);
	buffer[0] = ' ';
	buffer[1] = ' ';
	buffer[10] = '#';
	buffer[11] = 0;
	for(int i = 0; i < 19; i++)
	{
		move(10,19+i*2);
	for(int i = 0; i < 8; i++)
	{
		buffer[i + 2] = (rand()%(('z' - 'A'))) + 'A';
	}
	printw(buffer);
		refresh();
	usleep(33333);
		
	}
	move(10,19+38);
	printw("           ");
	
	
}

void drawShooter()
{
	char input_buffer[128];
	FILE* hand_file = fopen("HandAscii.txt", "r");
	if(hand_file == NULL)
	{
		move(7,0);
		printw("XxXxXxX");
		return;
	}
	for(int i = 0;fgets(input_buffer, 128, hand_file); i++)
	{
		move(7+i,0);
		printw(input_buffer);
	}
}

void shootGrenade()
{
	move(9,19);
	printw("  _  ");
	move(10,19);
	printw(" / \\ ");
	move(11,19);
	printw(" |X| ");
	move(12,19);
	printw("  V  ");
	refresh();
	usleep(16666);
	for(int i = 0; i < 5; i++)
	{
	move(9,19+i*4);
	printw("      _  ");
	move(10,19+i*4);
	printw("     / \\ ");
	move(11,19+i*4);
	printw("     |X| ");
	move(12,19+i*4);
	printw("      V  ");
	refresh();
	usleep(26666);
	}
	
	move(9,19+20);
	printw("*****");
	move(10,19+20);
	printw("*****");
	move(11,19+20);
	printw("*****");
	move(12,19+20);
	printw("*****");
	refresh();
	usleep(86666);
	
	move(9,19+20);
	printw(" *** ");
	move(10,19+20);
	printw("*****");
	move(11,19+20);
	printw("*****");
	move(12,19+20);
	printw(" *** ");
	refresh();
	usleep(86666);
	move(9,19+20);
	printw("  *  ");
	move(10,19+20);
	printw(" *** ");
	move(11,19+20);
	printw(" *** ");
	move(12,19+20);
	printw("  *  ");
	refresh();
	usleep(86666);
	
	move(9,19+20);
	printw("     ");
	move(10,19+20);
	printw("  *  ");
	move(11,19+20);
	printw("  *  ");
	move(12,19+20);
	printw("     ");
	refresh();
	usleep(86666);
	move(9,19+20);
	printw("     ");
	move(10,19+20);
	printw("     ");
	move(11,19+20);
	printw("     ");
	move(12,19+20);
	printw("     ");
	refresh();
	
	//move(10,19+38);
}

int main()
{
	srand(time(NULL));
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
	buffer[0] = 2;
	sendto(sockfd, buffer, 1, 0, (const struct sockaddr *) &servaddr, slen);
	recvfrom(sockfd, buffer, sizeof(DisplayMessage),0, NULL, NULL);
	memcpy(&display_message, buffer, sizeof(DisplayMessage));
	printf("Done\n");
	uint8_t prev_shoot = display_message.shoot;
	int len;
	drawShooter();
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
		sprintf(display_buffer, "Fluid:  %22d", display_message.fluid - 1);
		printw(display_buffer);
		move(1,0);
		sprintf(display_buffer, "Energy: %22d", display_message.energy);
		printw(display_buffer);
		move(2,0);
		sprintf(display_buffer, "Tracer: %22d", display_message.tracer);
		printw(display_buffer);
		move(3,0);
		sprintf(display_buffer, "Fire Mode: %19s", MODE_NAMES[display_message.mode]);
		printw(display_buffer);
		move(4,0);
		sprintf(display_buffer, "Target Count: %16d", display_message.targets);
		printw(display_buffer);
		if(display_message.shoot != prev_shoot)
		{
			switch(display_message.mode)
			{
				case 0:
				{
					shootSwing();
				}break;
				case 1:
				{
					shootRic();
				}break;
				case 3:
				{
					shootSplitter(display_message.targets);
				}break;
				case 4:
				{
					shootRapid();
				}break;
				case 5:
				{
					shootTracer();
				}break;
				case 7:
				{
					shootGrenade();
				}break;
				case 6:
				{
					shootTaser();
				}
			}
		}
		prev_shoot = display_message.shoot;
		
		refresh();
		usleep(66666);
	}
	getch();			/* Wait for user input */
	endwin();			/* End curses mode		  */

	return 0;
}


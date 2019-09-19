#include "address_map_arm.h"  
#include "stdbool.h" 
#include "exceptions.c"

void disable_A9_interrupts (void);
void set_A9_IRQ_stack (void);
void config_GIC (void);
void enable_A9_interrupts (void);
void display_title_screen (); 
void display_game_screen ();  
void clear_screen(); 
void wait_for_vsync();  
void config_KEYs();  
void plot_number_of_suit(int number_of_suit, int start_x, int start_y, short int color);  
void plot_number_of_card(int number_of_card, int start_x, int start_y, int width, int height, short int color); 
void draw_line (int x0, int y0, int x1, int y1, short int line_color);   
void plot_selector_pointer(int start_x, int start_y, short int color);  
void plot_pixel(int x, int y, short int line_color); 

void draw_game_board(int* player_hand, int player_size, int computer_size, bool* won_hands);

void initialize_deck(int *deck);
void deal_card(int *deck, int *deck_size, int *hand, int *hand_size);

bool computer_ask(int* opponent_hand, int* opponent_size, int* player_hand, int* player_size, bool* won_hands);
bool player_ask(int* opponent_hand, int* opponent_size, int* player_hand, int* player_size, bool* won_hands);
bool player_card_check(int* player_hand, int* player_size, int* player_score, bool* won_hands);

int get_card_suite(int card_num);
int get_card_value(int card_num); 

bool give_card_of_value(int asking_value, int* giving_hand, int* giving_size, int* taking_hand, int* taking_size); 

bool waiting_for_ISR;

extern short TITLE [240][320]; 
extern short MAIN_SCREEN [240][320];  

volatile int pixel_buffer_start;  
volatile int * pixel_ctrl_ptr; 

/* ********************************************************************************
 * This program demonstrates use of interrupts with C code.  The program responds 
 * to interrupts from the pushbutton KEY port in the FPGA.
 *
 * The interrupt service routine for the KEYs indicates which KEY has been pressed
 * on the LED display.
 ********************************************************************************/ 


int main(void)
{
	
	volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
	
	waiting_for_ISR = true;
	int game_state = 0;
	/*  STATE LIST
	0: Start
	1: Player Ask
	2: Check 1
	3: Computer Ask
	4: Check 2
	5: Player Win
	6: Computer Win
	*/
	bool won_hands[13];

	int game_deck[52];
	int deck_size = 52;

	int player_hand[52];
	int player_size = 0;
	int player_score = 0;

	int computer_hand[52];
	int computer_size = 0;
	int computer_score = 0;
	
	pixel_buffer_start = *pixel_ctrl_ptr;
	
	clear_screen(); 
	  
	wait_for_vsync();

	disable_A9_interrupts ();	// disable interrupts in the A9 processor
	set_A9_IRQ_stack ();			// initialize the stack pointer for IRQ mode
	config_GIC ();					// configure the general interrupt controller
	//config_KEYs ();				// configure pushbutton KEYs to generate interrupts
	enable_A9_interrupts ();	// enable interrupts in the A9 processor   
	 
	 volatile int * LED_ptr = (int *) LED_BASE;
	 *LED_ptr = 0b10;

	while (1) {
		switch (game_state) {
			case(0):
				for(int i = 0; i < 13; i++) {
					won_hands[i] = false;
				}

				initialize_deck(game_deck);

				// initialize hand
				for (int i = 0; i < 52; i++) {
					player_hand[i] = -1;
					computer_hand[i] = -1;
				}

				// deal cards to players
				for (int i = 0; i < 7; i++) {
					deal_card(game_deck, &deck_size, player_hand, &player_size);
					deal_card(game_deck, &deck_size, computer_hand, &computer_size);
				}

				display_title_screen();
				draw_game_board(player_hand, player_size, computer_size, won_hands);
				game_state = 1;
				break;
			case(1):
				if (!player_ask(computer_hand, &computer_size, player_hand, &player_size, won_hands)) // if no cards taken draw from deck
					deal_card(game_deck, &deck_size, player_hand, &player_size);
				game_state = 2;
				draw_game_board(player_hand, player_size, computer_size, won_hands);
				break;
			case(2):
				player_card_check(player_hand, &player_size, &player_score, won_hands);
				if (player_score + computer_score == 13) {
					game_state = player_score > computer_score ? 5 : 6;
				} else {
					game_state = 3;
				}
				draw_game_board(player_hand, player_size, computer_size, won_hands);
				break;
			case(3):
				if (!computer_ask(player_hand, &player_size, computer_hand, &computer_size, won_hands)) {
					deal_card(game_deck, &deck_size, computer_hand, &computer_size);
					game_state++;
				}
				draw_game_board(player_hand, player_size, computer_size, won_hands);
				break;
			case(4):
				player_card_check(computer_hand, &computer_size, &computer_score, won_hands);
				if (player_score + computer_score == 13) {
					game_state = player_score > computer_score ? 5 : 6;
				} else {
					game_state = 1;
				}
				draw_game_board(player_hand, player_size, computer_size, won_hands);
				break;
			case(5):
				//player_won_screen();
				game_state = 0;
				break;
			case(6):
				//computer_won_screen();
				game_state = 0;
				break;
			default:
				game_state = 0;
		}

}

bool player_card_check(int* player_hand, int* player_size, int* player_score, bool* won_hands) {
	int card_count [13]; 
	for (int i = 0; i < 13; i++) {
		card_count[i] = 0;
	}

	for (int i = 0; i < *player_size; i++) {
		int card_value = get_card_value(player_hand[i])-1;
		card_count[card_value] += 1;
		if (card_count[card_value] == 4) {
			won_hands[card_value] = true;
		}
	}

	for (int i = 0; i < 13; i++) {
		if (won_hands[i]) {	// remove all cards in that group of 4
			(*player_score)++;

			for (int j = 0; j < *player_size; j++) {
				if (get_card_value(player_hand[j]) == i+1) {

					(*player_size)--;
					for (int k = j; k < *player_size; k++) { // shift all remaining cards back one slot
						player_hand[k] = player_hand[k+1];
					}
					player_hand[*player_size] = -1;
					j--;
				}
			}
		}
	}
}

// take input from player to ask for card. Return true if card exists, else return false
bool player_ask(int* opponent_hand, int* opponent_size, int* player_hand, int* player_size, bool* won_hands) {
	if (*player_size == 0 || *opponent_size == 0) {
		return false;
	}

	int asking_value = 0; // 0 - 12, 0 is Ace, 12 is King
	int key_pressed = 0;

	bool enter_pressed = false;
	
	draw_game_board(player_hand, *player_size, *opponent_size, won_hands);
	plot_number_of_card(asking_value, 60, 60, 20, 20, 0);
	
	while (!enter_pressed) {
		volatile int * KEY_ptr = (int *) KEY_BASE;
		int press, LED_bits;

		press = *(KEY_ptr + 3);					// read the pushbutton interrupt register
		*(KEY_ptr + 3) = press;
		
		if (press & 0x1) {						// KEY0
			asking_value = (asking_value + 1) % 13;
			draw_game_board(player_hand, *player_size, *opponent_size, won_hands);
			plot_number_of_card(asking_value, 60, 60, 20, 20, 0);
		} else if (press & 0x2)	{				// KEY1
			asking_value = (asking_value == 0) ? 12 : asking_value - 1;
			draw_game_board(player_hand, *player_size, *opponent_size, won_hands);
			plot_number_of_card(asking_value, 60, 60, 20, 20, 0);
		} else if (press & 0x4) {
			enter_pressed = true;
			asking_value++;	// increase asking_value to go from 1 - 13 to line up with values from other functions
		} else if (press & 0x8) {
			enter_pressed = true;
			asking_value++;	// increase asking_value to go from 1 - 13 to line up with values from other functions
		}
	}

	return give_card_of_value(asking_value, opponent_hand, opponent_size, player_hand, player_size);
	
}

bool give_card_of_value(int asking_value, int* giving_hand, int* giving_size, int* taking_hand, int* taking_size) {
	bool found_card = false;
	for (int i = 0; i < *giving_size; i++) {
		if (get_card_value(giving_hand[i]) == asking_value) {

			found_card = true;
			taking_hand[*taking_size] = giving_hand[i];
			(*taking_size)++;
			(*giving_size)--;

			for (int j = i; j < *giving_size; j++) { // shift all remaining cards back one slot
				giving_hand[j] = giving_hand[j+1];
			}
			giving_hand[*giving_size] = -1;
			i--;
		}
	}
	return found_card;
}

bool computer_ask(int* opponent_hand, int* opponent_size, int* player_hand, int* player_size, bool* won_hands) {
	if (*player_size == 0 || *opponent_size == 0) {
		return false;
	}

	int asking_value = rand() % 13; // 0 - 12, 0 is Ace, 12 is King
	while (won_hands[asking_value]) {
		asking_value = (asking_value + 1) % 13;
	}
	asking_value++;

	return give_card_of_value(asking_value, opponent_hand, opponent_size, player_hand, player_size);	
}

// deal a card from deck to a hand
void deal_card(int *deck, int *deck_size, int *hand, int *hand_size) {
	if (*deck_size < 1)
		return;
	hand[*hand_size] = deck[(*deck_size) - 1]; // set new card in hand to top card of deck
	deck[(*deck_size) - 1] = -1;
	*hand_size += 1;
	*deck_size -= 1;
}

// pass in 0 - 51 to return card suite, 0-3 (Spade, Clubs, ...)
int get_card_suite(int card_num) {
	if (card_num < 13 && card_num > -1) {
		return 0;
	} else if (card_num < 26) {
		return 1;
	} else if (card_num < 39) {
		return 2;
	} else if (card_num < 52) {
		return 3;
	}

	return -1;
}

// pass in 0 - 51 to return card value, 1-13 (1 is Ace, 13 is King)
int get_card_value(int card_num) {
	return (card_num % 13) + 1;
}

// create a full, shuffled deck of cards
void initialize_deck(int *deck) {
	for (int i = 0; i < 52; i++) {
		deck[i] = -1;
	}
	for (int i = 0; i < 52; i++) {
		int cardIndex = rand() % 52;
		while (deck[cardIndex] != -1) {      // loop until we find a card slot that hasn't been assigned a card yet
			cardIndex = (cardIndex + 1) % 52;
		}
		deck[cardIndex] = i;
	}
}

void display_title_screen () {

	volatile short * pixelbuf = 0xc8000000;
    int i, j;
    for (i=0; i<240; i++)
        for (j=0; j<320; j++)
        *(pixelbuf + (j<<0) + (i<<9)) = TITLE[i][j];
	while (waiting_for_ISR) {
		volatile int * KEY_ptr = (int *) KEY_BASE;
		int press;
		press = *(KEY_ptr + 3);	
		if (press != 0) {
			waiting_for_ISR = false;
		}
	}
	//waiting_for_ISR = true;
    return;
}  

void display_game_screen () {

	//clear_screen(); 

	volatile short * pixelbuf = 0xc8000000;
    int i, j;
    for (i=0; i<240; i++)
        for (j=0; j<320; j++)
        *(pixelbuf + (j<<0) + (i<<9)) = MAIN_SCREEN[i][j];
   
  //  while (1);
    return;
} 

void wait_for_vsync() {
    pixel_ctrl_ptr = 0xFF203020; // pixel controller
    register int status;

    *pixel_ctrl_ptr = 1; // start the synchronization process

    status = *(pixel_ctrl_ptr + 3);

    while ((status & 0x01) != 0) {
        status = *(pixel_ctrl_ptr + 3);
    } 

}

void clear_screen() { 
	for (int i = 0; i <= 319; i++) {
		for (int j = 0; j <= 239; j++) {
			plot_pixel(i, j, 0x0);
		}
	}
}

/* setup the KEY interrupts in the FPGA */
void config_KEYs()
{
	volatile int * KEY_ptr = (int *) KEY_BASE;	// pushbutton KEY base address

	*(KEY_ptr + 2) = 0xF; 	// enable interrupts for the two KEYs
}

/****************************************************************************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * This routine checks which KEY has been pressed. It writes to the LEDs
 ***************************************************************************************/

void pushbutton_ISR( void )
{
	volatile int * KEY_ptr = (int *) KEY_BASE;
	volatile int * LED_ptr = (int *) LED_BASE;
	int press, LED_bits;

	press = *(KEY_ptr + 3);					// read the pushbutton interrupt register
	*(KEY_ptr + 3) = press;					// Clear the interrupt

	if (press & 0x1)							// KEY0
		LED_bits = 0b1;
	else if (press & 0x2)					// KEY1
		LED_bits = 0b10;
	else if (press & 0x4)
		LED_bits = 0b100;
	else if (press & 0x8)
		LED_bits = 0b1000;

	*LED_ptr = LED_bits;

	waiting_for_ISR = false;
	return; 

} 

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}  

void plot_selector_pointer(int start_x, int start_y, short int color) {
	for (int i = start_x; i <= 10 ; i++) {
		for (int j = start_y; j <= 10; j++) {
			plot_pixel(i, j, 0x0);
		}
	}  

	draw_line (start_x+10, start_y - 5, start_x + 15, start_y, 0xF800); // red line drawing first half of the arrow
	draw_line (start_x, start_y + 15, start_x +15, start_y, 0xF800); // red line drawing the second half of the arrow
} 

void draw_line (int x0, int y0, int x1, int y1, short int line_color) { 
	bool is_steep = abs(y1-y0) > abs(x1-x0); 

	if (is_steep) {
		int temp = x0;
		x0 = y0;
		y0 = temp;
		
		temp = x1; 
		x1 = y1;
		y1 = temp;
	} 

	if (x0 > x1) {  
		int temp = x0;
		x0 = x1;
		x1 = temp;

		temp = y0;
		y0 = y1;
		y1 = temp;
	} 

	int deltax = x1 - x0;  
	int deltay = abs(y1-y0); 
	float error = -(deltax/2);
	int y_step = 0; 
	int y = y0;  

	if ( y0 < y1) {
		y_step = 1;
	} else {
		y_step = -1; 
	} 
	int i = 0; 
	for (i = x0; i <= x1; i++) {
		if (is_steep) {
			plot_pixel(y,i,line_color); 
		} else {
			plot_pixel(i,y,line_color); 
			error = error + deltay; 
			if (error >= 0) {
				y = y + y_step;
				error = error - deltax; 
			}
		}
	} 
}

void draw_game_board(int* player_hand, int player_size, int computer_size, bool* won_hands) { 
	
	display_game_screen();
	
	//plot_number_of_card(5, 10, 10, 10, 10, 0);
	
	for (int i = 0; i < player_size; i++){
		if (i < 9) {
			plot_number_of_card(get_card_value(player_hand[i]) - 1, 25, 50+i*19, 7, 7, 0);
		} else {
			plot_number_of_card(get_card_value(player_hand[i]) - 1, 50, 50+(i-9)*19, 7, 7, 0);
		}
	}
	
	for (int i = 0; i < 13; i++){
		if (won_hands[i]) {
			if (i < 9) {
				plot_number_of_card(i, 130, 50+i*22, 9, 9, 0);
			} else {
				plot_number_of_card(i, 180, 50+(i-9)*22, 9, 9, 0);
			}
		}
	}
	
//get_card_value(int card_num) 
}

void plot_number_of_card(int number_of_card, int start_x, int start_y, int width, int height, short int color) { 
	
	if (number_of_card == 0) {						       // plotting the A for Ace
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i, start_y, 0x0);  
			plot_pixel(i, start_y+height, 0x0);  

		} 

		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i+height, 0x0); 
			plot_pixel(start_x, i, 0x0); 
			plot_pixel(start_x, i+height, 0x0);  
			plot_pixel(start_x+width, i, 0x0); 
		}
	} 
	
	if (number_of_card == 1) {							   // plotting the actual number 2
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i, start_y, 0x0);  
			plot_pixel(i, start_y+height, 0x0); 
			plot_pixel(i, start_y+(height*2), 0x0); 

		} 
		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i, 0x0); 
			plot_pixel(start_x, i+height, 0x0); 
		}
	} 

	if (number_of_card == 2) { 								// plotting the actual number 3
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i, start_y, 0x0);  
			plot_pixel(i, start_y+height, 0x0); 
			plot_pixel(i, start_y+(height*2), 0x0); 

		} 
		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i, 0x0); 
			plot_pixel(start_x+width, i+height, 0x0); 
		}
	} 

	if (number_of_card == 3) {								// plotting the actual number 4
		for (int i = start_x; i <= start_x + width; i++) {  
			plot_pixel(i, start_y+height, 0x0); 

		} 
		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i, 0x0); 
			plot_pixel(start_x, i, 0x0);  
			plot_pixel(start_x+width, i+height, 0x0); 
		}
	}

	if (number_of_card == 4) {							// plotting the actual number 5
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i, start_y, 0x0);  
			plot_pixel(i, start_y+height, 0x0); 
			plot_pixel(i, start_y+(height*2), 0x0); 

		} 
		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i+height, 0x0); 
			plot_pixel(start_x, i, 0x0); 
		}
	} 

	if (number_of_card == 5) {							// plotting the actual number 6
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i, start_y, 0x0);  
			plot_pixel(i, start_y+height, 0x0); 
			plot_pixel(i, start_y+(height*2), 0x0); 

		} 
		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i+height, 0x0); 
			plot_pixel(start_x, i, 0x0); 
			plot_pixel(start_x, i+height, 0x0); 
		}
	}

	if (number_of_card == 6) {							// plotting the actual number 7
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i, start_y, 0x0);   

		} 
		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i+height, 0x0); 
			plot_pixel(start_x+width, i, 0x0); 
		}
	}  

	if (number_of_card == 7) {							// plotting the actual number 8
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i, start_y, 0x0);  
			plot_pixel(i, start_y+height, 0x0); 
			plot_pixel(i, start_y+(height*2), 0x0); 

		} 
		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i+height, 0x0); 
			plot_pixel(start_x, i, 0x0); 
			plot_pixel(start_x, i+height, 0x0);  
			plot_pixel(start_x+width, i, 0x0); 
		}
	} 

	if (number_of_card == 8) {							   // plotting the actual number 9
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i, start_y, 0x0);  
			plot_pixel(i, start_y+height, 0x0);  

		} 
		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i+height, 0x0); 
			plot_pixel(start_x, i, 0x0);   
			plot_pixel(start_x+width, i, 0x0); 
		}
	}  

	if (number_of_card == 9) { 							// plotting the actual number 10 
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i+width, start_y, 0x0);  
			plot_pixel(i+width, start_y+(height*2), 0x0);  

		} 

		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+(width*2), i+height, 0x0); 
			plot_pixel(start_x, i, 0x0); 
			plot_pixel(start_x, i+height, 0x0);  
			plot_pixel(start_x+width, i, 0x0);  
			plot_pixel(start_x+(width*2), i, 0x0);  
			plot_pixel(start_x+width, i+height, 0x0); 

		}

	} 

	if (number_of_card == 10) {							// plotting a J for Jack
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i, start_y, 0x0);  
			plot_pixel(i+width, start_y, 0x0); 
			plot_pixel(i, start_y+(height*2), 0x0); 

		} 
		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i+height, 0x0); 
			plot_pixel(start_x, i+height, 0x0);  
			plot_pixel(start_x+width, i, 0x0); 
		}
	} 

	if (number_of_card == 11) {							// plotting a Q for Queen
		for (int i = start_x; i <= start_x + width; i++) {
			plot_pixel(i, start_y, 0x0);  
			plot_pixel(i, start_y+(height*2), 0x0); 

		} 
		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x+width, i+height, 0x0); 
			plot_pixel(start_x, i, 0x0); 
			plot_pixel(start_x, i+height, 0x0);  
			plot_pixel(start_x+width, i, 0x0); 
		}    

		draw_line (start_x+(width/2), start_y+(height/2), start_x+(width*2), start_y+(height*2), 0x0); //plotting that small line in Q 
	}  

	if (number_of_card == 12) {							// plotting a K for King

		for (int i = start_y; i <= start_y + height; i++) {
			plot_pixel(start_x, i, 0x0); 
			plot_pixel(start_x, i+height, 0x0);  
		}

		draw_line(start_x, start_y+height, start_x+width, start_y, 0x0); 
		draw_line(start_x, start_y+height, start_x+width, start_y+(height*2), 0x0); 

	} 
}

void plot_number_of_suit(int number_of_suit, int start_x, int start_y, short int color) {
	if (number_of_suit == 0) { 
		draw_line(start_x, start_y, start_x+5, start_y, 0x0); // black line for diamonds 		
	} 
	
	if (number_of_suit == 1) { 
		draw_line(start_x, start_y, start_x+5, start_y, 0x07E0); // green line for spades
 		
	} 
	
	if (number_of_suit == 2) { 
		draw_line(start_x, start_y, start_x+5, start_y, 0xF800); // red line for hearts 		
	} 
	
	if (number_of_suit == 3) { 
		draw_line(start_x, start_y, start_x+5, start_y, 0xF81F); // pink line for clubs 		
	}
}

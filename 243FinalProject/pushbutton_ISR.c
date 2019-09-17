#include "address_map_arm.h"

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
	return;
}

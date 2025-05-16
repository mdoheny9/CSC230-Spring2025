// These are included by the LCD driver code, so
// we don't need to include them here.
// #include <avr/io.h>
// #include <util/delay.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
// #include <stdbool.h>
#include <avr/interrupt.h>

#include "main.h"
#include "lcd_drv.h"

// timekeeping variables
// line one, clock
uint8_t hours1 = 0;
uint8_t minutes1 = 0;
uint8_t seconds1 = 0;
uint8_t sub_seconds1 = 0;
// line two, stop watch
uint8_t hours2 = 0;
uint8_t minutes2 = 0;
uint8_t seconds2 = 0;
uint8_t sub_seconds2 = 0;

// update display status
char current_time[13]; // hh:mm:ss:sss
uint8_t status = 0; // 0 = synced, 1 = paused

int main( void )
{
	// ************************ TIMER1_INIT ************************ //
	// set timer1 counter initial value to 0
	TCCR1A=0;
	// set timer1 prescaler to 64
	TCCR1B = (1 << CS11) | (1 << CS10);
	// lots of math to get:
	// set compare value for 1/1000 second interrupts
	OCR0A = 249;
	// enable timer compare match interrupt for Timer1
	TIMSK1 |=(1<<OCIE1A);
	// enable interrupts
	sei();

	// ************************ BUTTON_INIT ************************ //
	// enable ADC with prescaler 128
	ADCSRA = 0x87;
	ADMUX = 0x40;
	
	// ************************ LCD_INIT ************************ //
	lcd_init();
	
	for (;;)
	{
		check_button();
		display_time(0, hours1, minutes1, seconds1, sub_seconds1); // display line 1
		display_time(1, hours2, minutes2, seconds2, sub_seconds2); // display line 2
		
	}
}
 /* From the arduino example sketch, we have:
 *
 *  if (adc_key > 1000 )   return btnNONE;
 *  if (adc_key_in < 50)   return btnRIGHT;
 *  if (adc_key_in < 195)  return btnUP;
 *  if (adc_key_in < 380)  return btnDOWN;
 *  if (adc_key_in < 555)  return btnLEFT;
 *  if (adc_key_in < 790)  return btnSELECT;*/

void check_button() {
	// start conversion
	ADCSRA |= 0x40;

	// bit 6 in ADCSRA is 1 while conversion is in progress
	// 0b0100 0000
	// 0x40
	while (ADCSRA & 0x40);
	
	unsigned int val = ADCL;
	unsigned int val2 = ADCH;

	val += (val2 << 8);

	if (val > 555 && val < 790) { // btnSELECT pressed
		status = !status;
		
		if (!status) {
			// resume/sync line2 with current time 
			hours2 = hours1;
			minutes2 = minutes1;
			seconds2 = seconds1;
			sub_seconds2 = sub_seconds1;
		}
	}
	
}


void display_time(uint8_t line, uint8_t hours, uint8_t minutes, uint8_t seconds, uint8_t sub_seconds) {
	sprintf(current_time, "%d:%d:%d:%d", hours, minutes, seconds, sub_seconds);
	lcd_xy(0, line);
	lcd_puts(current_time);
}

// *********************TIM1_COMPA_vect** Interrupt Routines *********************** //
// timer1 compare match event A interrupt
ISR(TIMER1_COMPA_vect)
{
	sub_seconds1++;
	
	if (sub_seconds1 > 999) {
		sub_seconds1 = 0;
		seconds1 ++;
		
		if (seconds1 > 59) {
			seconds1 = 0;
			minutes1 ++;
			
			if (minutes1 > 59) {
				minutes1 = 0;
				hours1++;
				
				if (hours1 > 23) {
					hours1 = 0;
				}
			}
		}
	}
	if (!status) {
		sub_seconds2++;
		
		if (sub_seconds2 > 999) {
			sub_seconds2 = 0;
			seconds2 ++;
			
			if (seconds2 > 59) {
				seconds2 = 0;
				minutes2 ++;
				
				if (minutes2 > 59) {
					minutes2 = 0;
					hours2++;
					
					if (hours2 > 23) {
						hours2 = 0;
					}
				}
			}
		}
	}
}






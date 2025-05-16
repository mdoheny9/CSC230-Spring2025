/*
 * display_partD.asm
 *
 *  Created: 3/10/2025 4:45:51 PM
 *   Author: mdoheny
 */ 

 #define LCD_LIBONLY
 .include "lcd.asm"
.cseg

	; initialize the Analog to Digital conversion - ADC

		; enable the ADC & slow down the clock from 16mHz to ~125kHz, 16mHz/128
		ldi r16, 0x87  ;0x87 = 0b10000111
		sts ADCSRA_BTN, r16

		ldi r16, 0x00
		sts ADCSRB_BTN, r16 ; combine with MUX4:0 in ADMUX_BTN to select ADC0 p282

		; bits 7:6(REFS1:0) = 01: AVCC with external capacitor at AREF pin p.281
		; bit  5 (ADC Left Adjust Result) = 0: right adjustment the result
		; bits 4:0 (MUX4:0) = 00000: combine with MUX5 in ADCSRB_BTN ->ADC0 channel is used.
		ldi r16, 0x40  ;0x40 = 0b01000000
		sts ADMUX_BTN, r16

	; Initialize the LCD
	call lcd_init ; call lcd_init to Initialize the LCD
	call init_strings ; copy strings from program memory to data memory

	/*; detect if "RIGHT" button is pressed r1:r0 <- 0x032
	ldi r16, low(RIGHT);
	mov BOUNDARY_RL, r16
	ldi r16, high(RIGHT)
	mov BOUNDARY_RH, r16
	
	; detect if "LEFT" button is pressed r2:r3 <- 0x22B
	ldi r16, low(LEFT)
	mov BOUNDARY_LL, r16
	ldi r16, high(LEFT)
	mov BOUNDARY_LH, r16

	; detect if "UP" button is pressed r4:r5 <- 0x0C3
	ldi r16, low(UP);
	mov BOUNDARY_UL, r16
	ldi r16, high(UP)
	mov BOUNDARY_UH, r16

	; detect if "DOWN" button is pressed r6:r7 <- 0x17C
	ldi r16, low(DOWN);
	mov BOUNDARY_DL, r16
	ldi r16, high(DOWN)
	mov BOUNDARY_DH, r16*/

loop:
	rcall lcd_clr

	call check_button
	cpi  r23, 0
	breq loop ; if theres no input, keep checking 

	; determine which button is pressed
	cpi r23, 1
		breq display_right
	cpi r23, 2
		breq display_left
	cpi r23, 3
		breq display_up
	cpi r23, 4
		breq display_down

rjmp loop

; ========== DISPLAY RELATED SUBROUTINES ========== 
display_right:
	ldi r16, 0x00 ;display on row 0
	push r16
	ldi r16, 0xB ; display starting at column 11
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, high(right_msg)
	push r16
	ldi r16, low(right_msg)
	push r16
	call lcd_puts
	pop r16
	pop r16

	ret

display_left:
	ldi r16, 0x01 ;display on row 0
	push r16
	ldi r16, 0x00 ; display starting at column 0
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, high(left_msg)
	push r16
	ldi r16, low(left_msg)
	push r16
	call lcd_puts
	pop r16
	pop r16

	ret

display_up:
	ldi r16, 0x00 ;display on row 0
	push r16
	ldi r16, 0x00 ; display starting at column 0
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, high(up_msg)
	push r16
	ldi r16, low(up_msg)
	push r16
	call lcd_puts
	pop r16
	pop r16

	ret

display_down:
	ldi r16, 0x01 ;display on row 0
	push r16
	ldi r16, 0x0B ; display starting at column 0
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, high(down_msg)
	push r16
	ldi r16, low(down_msg)
	push r16
	call lcd_puts
	pop r16
	pop r16

	ret
; ========== END OF DISPLAY RELATED SUBROUTINES ========== 


;
; the function tests to see if the button
; RIGHT has been pressed
;
; on return, r23 is set to be: 0 if not pressed, 1 if pressed
;
; this function uses registers:
;	r16
;	r17
;	r24
;
; This function could be made much better.  Notice that the a2d
; returns a 2 byte value (actually 10 bits).
; 
; if you consider the word:
;	 value = (ADCH_BTN << 8) +  ADCL_BTN
; then:
;
; value > 0x3E8 - no button pressed
;
; Otherwise:
; value < 0x032 - right button pressed
; value < 0x0C3 - up button pressed
; value < 0x17C - down button pressed
; value < 0x22B - left button pressed
; value < 0x316 - select button pressed
;
; This function 'cheats' because I observed
; that ADCH_BTN is 0 when the right or up button is
; pressed, and non-zero otherwise.
; 
check_button:
	; start a2d
	lds	r16, ADCSRA_BTN 

	; bit 6 =1 ADSC (ADC Start Conversion bit), remain 1 if conversion not done
	; ADSC changed to 0 if conversion is done
	ori r16, 0x40 ; 0x40 = 0b01000000
	sts	ADCSRA_BTN, r16

	; wait for it to complete, check for bit 6, the ADSC bit
wait:	lds r16, ADCSRA_BTN
		andi r16, 0x40
		brne wait

		; read the value, use XH:XL to store the 10-bit result
		lds DATAL, ADCL_BTN
		lds DATAH, ADCH_BTN

		clr r23 

		; CHECK LEFT
		ldi r16, low(LEFT);
		mov BOUNDARY_L, r16
		ldi r16, high(LEFT)
		mov BOUNDARY_H, r16

		cp DATAL, BOUNDARY_L
		cpc DATAH, BOUNDARY_H
		brsh skip		
		ldi r23, 2

		; CHECK DOWN
		ldi r16, low(DOWN);
		mov BOUNDARY_L, r16
		ldi r16, high(DOWN)
		mov BOUNDARY_H, r16

		cp DATAL, BOUNDARY_L
		cpc DATAH, BOUNDARY_H
		brsh skip		
		ldi r23, 4

		; CHECK UP
		ldi r16, low(UP);
		mov BOUNDARY_L, r16
		ldi r16, high(UP)
		mov BOUNDARY_H, r16

		cp DATAL, BOUNDARY_L
		cpc DATAH, BOUNDARY_H
		brsh skip		
		ldi r23, 3

		; CHECK RIGHT
		ldi r16, low(RIGHT);
		mov BOUNDARY_L, r16
		ldi r16, high(RIGHT)
		mov BOUNDARY_H, r16

		cp DATAL, BOUNDARY_L
		cpc DATAH, BOUNDARY_H
		brsh skip		
		ldi r23, 1

		/*; CHECK LEFT
		cp DATAL, BOUNDARY_LL
		cpc DATAH, BOUNDARY_LH
		brsh skip		
		ldi r23, 2
		
		; CHECK DOWN
		cp DATAL, BOUNDARY_DL
		cpc DATAH, BOUNDARY_DH
		brsh skip
		ldi r23, 4

		; CHECK UP
		cp DATAL, BOUNDARY_UL
		cpc DATAH, BOUNDARY_UH
		brsh skip		
		ldi r23, 3
		
		; CHECK RIGHT
		cp DATAL, BOUNDARY_RL
		cpc DATAH, BOUNDARY_RH
		brsh skip
		ldi r23, 1*/

skip:	ret


init_strings: ; altered init_strings from lcd_example.asm
	push r16
	; copy strings from program memory to data memory
	; RIGHT
	ldi r16, high(right_msg)		; this the destination
	push r16
	ldi r16, low(right_msg)
	push r16
	ldi r16, high(right_msg_p << 1) ; this is the source
	push r16
	ldi r16, low(right_msg_p << 1)
	push r16
	call str_init			; copy from program to data
	pop r16					; remove the parameters from the stack
	pop r16
	pop r16
	pop r16

	; LEFT
	ldi r16, high(left_msg)		; this the destination
	push r16
	ldi r16, low(left_msg)
	push r16
	ldi r16, high(left_msg_p << 1) ; this is the source
	push r16
	ldi r16, low(left_msg_p << 1)
	push r16
	call str_init			; copy from program to data
	pop r16					; remove the parameters from the stack
	pop r16
	pop r16
	pop r16

	; UP
	ldi r16, high(up_msg)		; this the destination
	push r16
	ldi r16, low(up_msg)
	push r16
	ldi r16, high(up_msg_p << 1) ; this is the source
	push r16
	ldi r16, low(up_msg_p << 1)
	push r16
	call str_init			; copy from program to data
	pop r16					; remove the parameters from the stack
	pop r16
	pop r16
	pop r16

	; DOWN
	ldi r16, high(down_msg)		; this the destination
	push r16
	ldi r16, low(down_msg)
	push r16
	ldi r16, high(down_msg_p << 1) ; this is the source
	push r16
	ldi r16, low(down_msg_p << 1)
	push r16
	call str_init			; copy from program to data
	pop r16					; remove the parameters from the stack
	pop r16
	pop r16
	pop r16

	pop r16
	ret


right_msg_p:	.db "Right", 0	
left_msg_p:	.db "Left", 0	
up_msg_p:	.db "Up", 0	
down_msg_p:	.db "Down", 0	

.dseg

; Symbonic names for registers
.def DATAH=r25  ;DATAH:DATAL  store 10 bits data from ADC
.def DATAL=r24

.def BOUNDARY_L = r1 ; hold high byte value of the threshold for button
.def BOUNDARY_H = r0 ; hold low byte value of the threshold for button, r1:r0
/*.def BOUNDARY_RH=r1  ;hold high byte value of the threshold for button
.def BOUNDARY_RL=r0  ;hold low byte value of the threshold for button, r1:r0

.def BOUNDARY_LH=r3  ;hold high byte value of the threshold for button
.def BOUNDARY_LL=r2

.def BOUNDARY_UH=r5  ;hold high byte value of the threshold for button
.def BOUNDARY_UL=r4

.def BOUNDARY_DH=r7  ;hold high byte value of the threshold for button
.def BOUNDARY_DL=r6*/

; Definitions for using the Analog to Digital Conversion
.equ ADCSRA_BTN=0x7A
.equ ADCSRB_BTN=0x7B
.equ ADMUX_BTN=0x7C
.equ ADCL_BTN=0x78
.equ ADCH_BTN=0x79


; LCD keypad shield:
.equ RIGHT	= 0x032
.equ UP	    = 0x0c3 ; maybe 0x0b0   
.equ DOWN	= 0x17C ; maybe 0x160
.equ LEFT	= 0x22B
;
; The program copies the strings from program memory
; into data memory.  These are the strings
; that are actually displayed on the lcd
;
right_msg:	.byte 200
left_msg:	.byte 200
up_msg:	.byte 200
down_msg:	.byte 200




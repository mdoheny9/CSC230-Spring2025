/*
 * display_partC.asm
 *
 *  Created: 3/11/2025 5:08:52 PM
 *   Author: mdoheny
 */ 
.cseg
 .org 0
	jmp start
.org 0x22 ; Timer/Counter1 Compare Match A Interrupt (scroll)
	jmp timer1_isr

#define LCD_LIBONLY
.include "lcd.asm"
.cseg

; Using formula: TOP = int(0.5+(CLOCK/PRESCALE_DIV*DELAY))
.equ TOP1=int(0.5+(16.0e6/1024*1)) ; Used for Timer/Counter3, flash using polling
.equ TOP2=int(0.5+(16.0e6/1024*1)) ; Used for Timer/Counter1, scroll using Interrupt Service Routine

start:
	; initialize the Analog to Digital conversion - ADC
	ldi r16, 0x87
	sts ADCSRA_BTN, r16

	ldi r16, 0x00
	sts ADCSRB_BTN, r16 ; combine with MUX4:0 in ADMUX_BTN to select ADC0 p282

	ldi r16, 0x40  ;0x40 = 0b01000000
	sts ADMUX_BTN, r16

	call lcd_init ; Initialize the LCD
	call init_strings ; copy strings from program memory to data memory


	; ========= Configure Timer/Counter1 =========
	ldi r16, high(TOP2)
	sts OCR1AH, r16
	ldi r16, low(TOP2)
	sts OCR1AL, r16

	clr r16
	sts TCCR3A, r16

	ldi r16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
	sts TCCR1B, r16

	; enable output compare match A interrupt
	ldi r16, (1 << OCIE1A)
	sts TIMSK1, r16

	 ; ========= Configure Timer/Counter3 =========
	ldi r16, high(TOP1)
	sts OCR3AH, r16
	ldi r16, low(TOP1)
	sts OCR3AL, r16

	ldi r16, 0
	sts TCCR3A, r16 ; TCCR3A is set to 0, pg154 of datasheet

	ldi r16, (1 << WGM32) | (1 << CS32) | (1 << CS30)
	sts TCCR3B, r16 ; set register TCCR3B to 0b00001101

	; enable global interrupts
	sei

	rcall display_both

	clr r20

	display_msg: ; polling loop
		in r16, TIFR3
		sbrs r16, OCF3A
	rjmp display_msg
		; Load current status into r20
		lds r20, status

		ldi temp, 1<<OCF3A ;clear bit 1 in TIFR3 by writing logical one to its bit position, P163 of the Datasheet
		out TIFR3, temp

		inc r20
		cpi r20, 3 ; continuously loop through statuses (0, 1, 2)
			brne skip_clr
		ldi r20, 0 ; when status > 2, loop back to status = 0
		skip_clr:
			sts status, r20
		rcall update_msg ; update the displayed message accordingly

		rjmp display_msg

update_msg:
	;
	; Update status every 1s using timer3_isr to flash in desired pattern
	; status 0 -> display_both
	; status 1 -> display just msg1
	; status 2 -> display just msg2
	;
	rcall lcd_clr
	cpi r20, 0
		breq display_both
	cpi r20, 1
		breq display_msg1
	cpi r20, 2
		breq display_msg2
ret

; ========== DISPLAY RELATED SUBROUTINES ========== 
display_both:
; display message 1:
	ldi r16, 0x00
	push r16
	ldi r16, 0x00
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, high(msg1)
	push r16
	ldi r16, low(msg1)
	push r16
	call lcd_puts
	pop r16
	pop r16

; display message 2:
	ldi r16, 0x01
	push r16
	ldi r16, 0x00
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, high(msg2)
	push r16
	ldi r16, low(msg2)
	push r16
	call lcd_puts
	pop r16
	pop r16
ret
display_msg1:
	;display on row 0
	ldi r16, 0x00
	push r16
	ldi r16, 0x00
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, high(msg1)
	push r16
	ldi r16, low(msg1)
	push r16
	call lcd_puts
	pop r16
	pop r16

ret

display_msg2:
	;display on row 1
	ldi r16, 0x01
	push r16
	ldi r16, 0x00
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, high(msg2)
	push r16
	ldi r16, low(msg2)
	push r16
	call lcd_puts
	pop r16
	pop r16

ret
; ========== END OF DISPLAY RELATED SUBROUTINES ========== 

; ========== SCROLLING RELATED SUBROUTINES ========== 
shift_msg1_right:
	push r16
	push r17
	push ZH
	push ZL

	ldi ZH, high(msg1)
	ldi ZL, low(msg1)

	ld r16, Z ; store first character to r19

	shift_msg1_right_loop:
		adiw ZL, 1 ; inc Z
		ld r17, Z ; store next character in r17
		cpi r17, 0 ; if string has ended
			breq msg1_end
		st Z, r16
		mov r16, r17
	rjmp shift_msg1_right_loop

	msg1_end:
		ldi ZH, high(msg1)
		ldi ZL, low(msg1)
		st Z, r16 ; store last character in first position

		pop ZL
		pop ZH
		pop r17
		pop r16
	ret

shift_msg2_right:
	push r16
	push r17
	push ZH
	push ZL

	ldi ZH, high(msg2)
	ldi ZL, low(msg2)

	ld r16, Z ; store first character to r19

	shift_msg2_right_loop:
		adiw ZL, 1 ; increment Z
		ld r17, Z ; store "next" character in r17
		cpi r17, 0 ; if last character is reached
			breq msg2_end
		st Z, r16 ; store "current" character in "next" position
		mov r16, r17 ; "next" character is now "current" character
	rjmp shift_msg2_right_loop

	msg2_end:
		ldi ZH, high(msg2)
		ldi ZL, low(msg2)
		st Z, r16 ; store last character in first position

		pop ZL
		pop ZH
		pop r17
		pop r16
	ret


shift_msg1_left:
	push r16
	push ZH
	push ZL
	push YH
	push YL

	ldi ZH, high(msg1)
	ldi ZL, low(msg1)
	ldi YH, high(msg1 + 1)
	ldi YL, low(msg1 + 1)

	ld r19, Z ; store first character in r19

	shift_msg1_left_loop:
		ld r16, Y+ ; Load character at Z into r19, increment Z
		st Z+, r16 ; Store next character into current position
		ld r16, Y
		cpi r16, 0
			brne shift_msg1_left_loop ; loop until all characters are shifted
	st Z, r19 ; load original first character into last character slot

	pop YL
	pop YH
	pop ZL
	pop ZH
	pop r16  
	ret


shift_msg2_left:
	push r16
	push ZH
	push ZL
	push YH
	push YL

	ldi ZH, high(msg2)
	ldi ZL, low(msg2)
	ldi YH, high(msg2 + 1)
	ldi YL, low(msg2 + 1)

	ld r19, Z ; store first character in r19

	shift_msg2_left_loop:
		ld r16, Y+ ; Load character at Z into r19, increment Z
		st Z+, r16 ; Store next character into current position
		ld r16, Y
		cpi r16, 0
			brne shift_msg2_left_loop ; loop until all 16 characters are shifted
	st Z, r19 ; load original first character into last character slot

	pop YL
	pop YH
	pop ZL
	pop ZH
	pop r16
	ret

scroll_left:
	rcall shift_msg1_left
	rcall shift_msg2_left
	ret

scroll_right:
	rcall shift_msg1_right
	rcall shift_msg2_right
	ret
; ========== END OF SCROLLING RELATED SUBROUTINES ========== 

timer1_isr: ; SCROLLING ISR
;
; No scroll on startup (await button press)
; shift both messages left/right every 1s depending on which button is pressed
;
	push r16
    lds r16, SREG
    push r16
	
	call check_button
	cpi r23, 1
		breq scroll_right1
	cpi r23, 2
		breq scroll_left1
	jmp end_isr

	scroll_right1:
		call scroll_right
		jmp end_isr
	scroll_left1:
		call scroll_left
		jmp end_isr

end_isr:
	pop r16
	sts SREG, r16
	pop r16
reti

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

		; CHECK LEFT
		ldi r16, low(LEFT);
		mov BOUNDARY_L, r16
		ldi r16, high(LEFT)
		mov BOUNDARY_H, r16

		cp DATAL, BOUNDARY_L
		cpc DATAH, BOUNDARY_H
		brsh skip		
		ldi r23, 2

		; CHECK RIGHT
		ldi r16, low(RIGHT);
		mov BOUNDARY_L, r16
		ldi r16, high(RIGHT)
		mov BOUNDARY_H, r16

		cp DATAL, BOUNDARY_L
		cpc DATAH, BOUNDARY_H
		brsh skip		
		ldi r23, 1

skip:	ret

init_strings: ; from lcd_example.asm
	push r16
	; copy strings from program memory to data memory
	ldi r16, high(msg1)		; this the destination
	push r16
	ldi r16, low(msg1)
	push r16
	ldi r16, high(msg1_p << 1) ; this is the source
	push r16
	ldi r16, low(msg1_p << 1)
	push r16
	call str_init			; copy from program to data
	pop r16					; remove the parameters from the stack
	pop r16
	pop r16
	pop r16

	ldi r16, high(msg2)
	push r16
	ldi r16, low(msg2)
	push r16
	ldi r16, high(msg2_p << 1)
	push r16
	ldi r16, low(msg2_p << 1)
	push r16
	call str_init
	pop r16
	pop r16
	pop r16
	pop r16

	pop r16
ret

msg1_p:	.db "Megan Doheny    ", 0	
msg2_p: .db "CSC230: Spring 2025 ", 0

.dseg

; symbonic names for registers
.def DATAH=r25  ;DATAH:DATAL  store 10 bits data from ADC
.def DATAL=r24

.def BOUNDARY_H = r1 ; hold high byte value of the threshold for button
.def BOUNDARY_L = r0 ; hold low byte value of the threshold for button, r1:r0

; Definitions for using the Analog to Digital Conversion
.equ ADCSRA_BTN=0x7A
.equ ADCSRB_BTN=0x7B
.equ ADMUX_BTN=0x7C
.equ ADCL_BTN=0x78
.equ ADCH_BTN=0x79

; LCD keypad shield:
.equ RIGHT	= 0x032
.equ LEFT	= 0x22B
;
; The program copies the strings from program memory
; into data memory.  These are the strings
; that are actually displayed on the lcd
;
status: .byte 1
msg1:	.byte 200
msg2:	.byte 200
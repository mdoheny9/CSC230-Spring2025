/*
 * display_partA.asm
 *
 *  Created: 2025-03-09 6:42:21 PM
 *   Author: megan
 */ 
 
 .cseg
 .org 0
	jmp start
.org 0x40 ; Timer/Counter3 Compare Match A Interrupt
	jmp timer3_isr

#define LCD_LIBONLY
.include "lcd.asm"
.cseg

.equ TOP=int(0.5+(16.0e6/1024*1)) ; TOP = int(0.5+(CLOCK/PRESCALE_DIV*DELAY))


start:
	call lcd_init ; Initialize the LCD
	call init_strings ; copy strings from program memory to data memory

	; ========= Configure Timer/Counter3 =========
	ldi r16, high(TOP)
	sts OCR3AH, r16
	ldi r16, low(TOP)
	sts OCR3AL, r16

	clr r16
	sts TCCR3A, r16

	ldi r16, (1 << WGM32) | (1 << CS32) | (1 << CS30)
	sts TCCR3B, r16

	; enable output compare match A interrupt
	ldi r16, (1 << OCIE3A)
	sts TIMSK3, r16

	; enable global interrupts
	sei

	rcall display_both

	display_msg: ; infinite loop
		rjmp display_msg

update_msg:
	;
	; Update status every 1s using timer3_isr to flash in desired pattern
	; status 0 -> display_both
	; status 1 -> display just msg1
	; status 2 -> display just msg2
	;
	rcall lcd_clr
	cpi r16, 0
		breq display_both
	cpi r16, 1
		breq display_msg1
	cpi r16, 2
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
	ldi r16, 0x00 ; display on row 0
	push r16
	ldi r16, 0x00 ; display in on column 0
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
	ldi r16, 0x01 ; display on row 1
	push r16
	ldi r16, 0x00 ; display on column 0
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

timer3_isr: ; FLASHING ISR
	push r16
    lds r16, SREG ; preserve SREG
    push r16

    ; Load current status into r16
    lds r16, status
	inc r16
	cpi r16, 3 ; continuously loop through statuses (0, 1, 2)
		brne skip
	ldi r16, 0 ; when status > 2, loop back to status = 0
	skip:
		sts status, r16 ; store updated status in status variable
	
	call update_msg ; update the displayed message accordingly
	pop r16
	sts SREG, r16
	pop r16
reti

init_strings: ; from lcd_example.asm
	push r16
	; copy strings from program memory to data memory
	ldi r16, high(msg1) ; this the destination
	push r16
	ldi r16, low(msg1)
	push r16
	ldi r16, high(msg1_p << 1) ; this is the source
	push r16
	ldi r16, low(msg1_p << 1)
	push r16
	call str_init ; copy from program to data
	pop r16	; remove the parameters from the stack
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

msg1_p:	.db "Megan Doheny", 0	
msg2_p: .db "CSC230: Spring 2025", 0

.dseg
;
; The program copies the strings from program memory
; into data memory.  These are the strings
; that are actually displayed on the lcd
;
status: .byte 1
msg1:	.byte 200
msg2:	.byte 200

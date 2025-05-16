; A version of "hello, world!" where the
; exclamation mark blinks.

.cseg
.org 0 ; reset
	jmp start

.org 0x22
	jmp swap_chars_isr 


; The following file *must* be in the same
; directory as this "hello_world.asm". Writing
; programs made up of multiple assembly files
; is not nearly as easy or straightforward
; as writing Java programs with multiple classes.
; Note the files that are included: all assembly
; programs this term which use the LCD display
; must have these includes.
;
.include "lcd.asm"

; The next .cseg is needed because we can never
; assume that an included file ends with code
; in cseg (or even in dseg). Therefore we take
; absolutely not chances and indicate that we
; resume in the code segment. (We do not need
; to specific an origin address; the assembler
; will simply at the code which follows into
; the next available address in the code segment).
;
.cseg


; And so our program begins... and the *very*
; first thing we do is initialize the LCD
; display and all of the associated data
; needed for this display.
;
start:
	;initialize the LCD display
	rcall lcd_init

	;The following code configure the timer/counter1
	;When timer count up to 7800 (0x1E78), an interrupt happens.
	;Set the TOP value for timer1.
	;Note timer1 is a 16 bit timer, the max is 2^16 = 65,535.
	;You may set the TOP value for the timer at any number between 1 and 65,535.
	;In this lab, the TOP value is set at 7800.
	ldi r17, high(7800)
	ldi r16, low(7800)
	sts OCR1AH, r17
	sts OCR1AL, r16

	;configure the timer1, refer to the lab7 note
	ldi r16, 0
	sts TCCR1A, r16

	ldi r16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
	sts TCCR1B, r16

	;TIMSK was not used in lab7, but it is used in this lab. refer to the lab8 note
	;to enable timer1 interrupt, must set bit OCIE1A (bit 1) to 1 and 
	;set the I flag in Status Register to 1.
	ldi r16, (1 << OCIE1A)
	sts TIMSK1, r16
	sei

	;now display some characters
	;TODO: change the following code so that it starts at row 1, column 3.
	ldi r16, 0x01 ;row
	ldi r17, 0x03 ;column
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16

	;TODO: change the following code so that displays �Hello, world!�
	ldi r16, 'H'
	push r16
	rcall lcd_putchar
	pop r16

	ldi r16, 'e'
	push r16
	rcall lcd_putchar
	pop r16

	ldi r16, 'l'
	push r16
	rcall lcd_putchar
	pop r16

	ldi r16, 'l'
	push r16
	rcall lcd_putchar
	pop r16

	ldi r16, 'o'
	push r16
	rcall lcd_putchar
	pop r16

	ldi r16, ','
	push r16
	rcall lcd_putchar
	pop r16

	ldi r16, ' '
	push r16
	rcall lcd_putchar
	pop r16

	ldi r16, 'W'
	push r16
	rcall lcd_putchar
	pop r16

	ldi r16, 'o'
	push r16
	rcall lcd_putchar
	pop r16
	ldi r16, 'r'
	push r16
	rcall lcd_putchar
	pop r16
	ldi r16, 'l'
	push r16
	rcall lcd_putchar
	pop r16
	ldi r16, 'd'
	push r16
	rcall lcd_putchar
	pop r16
	ldi r16, '!'
	push r16
	rcall lcd_putchar
	pop r16


	; Our timer1 interrupt will swap these
	; two values at every interrupt. Our busy
	; loop, however, will simply write what
	; is in CHAR_ONE to the last position
	; on the LCD display
	;
	;TODO: change them to '!' and ' '
	ldi r16, '!'
	sts CHAR_ONE, r16

	ldi r16, ' '
	sts CHAR_TWO, r16


	; Constantly place into the last LCD
	; location the value in CHAR_ONE.
	;
blink_loop:
	;figure out the (row, column) of '!' and make a change
	ldi r16, 0x01 ; <- TODO: change the row
	ldi r17, 0x0F ; <- TODO: change the column
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16

	lds r16, CHAR_ONE
	push r16
	rcall lcd_putchar
	pop r16

	rjmp blink_loop
;end of the main program

;TODO: implement the interrupt service routine
;When interrupt happens, isr swap the two characters in data memory at CHAR_ONE and CHAR_TWO.
;the blink_loop in the main always displays the character in CHAR_ONE
swap_chars_isr:
	;how many registers you are going to use?
	;preserve the values on the stack
	;also save the status register
	push r16
	push r17
	lds r16, SREG ; save the status register
	push r16

	;read CHAR_ONE into, say, r16 and 
	lds r16, CHAR_ONE
	;read CHAR_TWO into, say r17
	lds r17, CHAR_TWO
	;store r16 in CHAR_TWO
	sts CHAR_TWO, r16
	;store r17 in CHAR_ONE <- now, they are swapped
	sts CHAR_ONE, r17

	;restore the status register and the registers that you used
	pop r16
	sts SREG, r16
	pop r17
	pop r16
	reti


.dseg
CHAR_ONE: .byte 1
CHAR_TWO: .byte 1

;
; a2.asm
;
; Created: 2025-02-09 1:01:31 PM
; Author : megan
;


; Replace with your application code
.cseg
.org 0

	; set PORTL and PORTB as output??
	out DDRB, r16
	sts DDRL, r16
configure_leds:
	sts PORTL, r16
	out PORTB, r16
;
; a1.asm
;
; Created: 2025-01-24 6:48:49 PM
; Author : megan
;


; Replace with your application code


    .cseg
    .org 0

; ==== END OF "DO NOT TOUCH" SECTION ==========

	; ldi R16, 0b01011100
	ldi r16, 0b10100100
	; ldi R16, 0b10110110


	; THE RESULT **MUST** END UP IN R17

; **** BEGINNING OF "STUDENT CODE" SECTION **** 

; Your solution here.

mov r17, r16 ; move values from r16 to r17

tst r17
breq end ; if r17 has no set bits go to end
brmi end ; if r17 has a negative value go to end

ldi r22, 0x08 ; initialize counter to 8
clr r21 ; initialize status to 0
ldi r20, 0x01 ; initialize mask to 0000 0001
; use r19 as temporary holder for mask so it remains un-altered

find_rightmost:
	mov r19, r20 ; move mask over to holder
	and r19, r17 ; compare maskholder and r17
	brne invert_bits ; if bit is set, invert all bits to the left

	dec r22 ; decrement counter
	breq end ; if counter reaches 0, go to end
	lsl r20 ; shift mask left

	rjmp find_rightmost ; else, continue loop

invert_bits:
	dec r22 ; decrement counter
	breq end ; if counter reaches 0, go to end
	lsl r20 ; shift mask left
	mov r19, r20 ; move mask over to holder
	eor r17, r19
	rjmp invert_bits

end:
	nop

	/*lsl r17              ; Shift r17 left (clearing bit 0 initially)
    sec                  ; Set carry flag to simulate NOT operation
    rol r16              ; Rotate left through carry (flipping bits)
    dec r18              ; Decrement counter
    brne invert_loop     ; Repeat until all bits are flipped

    ; Step 2: Add 1 using a loop (manual carry propagation)
    ldi r18, 1           ; Load 1 into r18 (to be added)
    clc                  ; Clear carry flag before addition*/



; **** END OF "STUDENT CODE" SECTION ********** 



; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
twos_complement_stop:
    rjmp twos_complement_stop


	#include p18f87k22.inc

; Globals section
global	    DMX_setup, DMX_output
	
; Reserving space in RAM

; Constants
constant    out_pin = 0
	
; Put this somewhere in Program memory
DMX	code

DMX_setup
	bcf	TRISC, out_pin    ; Pin 0 on C - output
	bsf	PORTC, out_pin	  ; Output 1 by default
	return

DMX_output
	call	DMX_output_byte
	return

; Writes 8 bits to PORTC from FSR0
DMX_output_byte
b0	btfsc	INDF0, 0    ; Test bit 0, skip if clear
	bra	b0_1	    ; Go to case that outputs 1 on PORTC pin
	nop
	bcf	PORTC, out_pin	; Clear PORTC output pin
	bra	b1		; Branch to outputting next bit
b0_1	bsf	PORTC, out_pin	; Set PORTC pin
	nop
	nop
	
b1	btfsc   INDF0, 1
	bra b1_1
	nop
	bcf PORTC, out_pin
	bra b2
b1_1	bsf PORTC, out_pin
	nop
	nop

b2	btfsc   INDF0, 2
	bra b2_1
	nop
	bcf PORTC, out_pin
	bra b3
b2_1	bsf PORTC, out_pin
	nop
	nop

b3	btfsc   INDF0, 3
	bra b3_1
	nop
	bcf PORTC, out_pin
	bra b4
b3_1	bsf PORTC, out_pin
	nop
	nop

b4	btfsc   INDF0, 4
	bra b4_1
	nop
	bcf PORTC, out_pin
	bra b5
b4_1	bsf PORTC, out_pin
	nop
	nop

b5	btfsc   INDF0, 5
	bra b5_1
	nop
	bcf PORTC, out_pin
	bra b6
b5_1	bsf PORTC, out_pin
	nop
	nop

b6	btfsc   INDF0, 6
	bra b6_1
	nop
	bcf PORTC, out_pin
	bra b7
b6_1	bsf PORTC, out_pin
	nop
	nop

b7	btfsc   INDF0, 7
	bra b7_1
	nop
	bcf PORTC, out_pin
	bra b8
b7_1	bsf PORTC, out_pin
	nop
	nop
b8	nop
	nop
	nop
	bsf PORTC, out_pin  ; restore output pin to original state
	return

end
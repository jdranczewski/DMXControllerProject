	#include p18f87k22.inc

; Globals section
global	    DMX_setup, DMX_output
	
; Reserving space in RAM
DMX_vars    udata_acs	; Reserve space somewhere (swhere) in access RAM
count0	res 1		; Counter up to 513 for reading memory
count0s	res 1		; Source variable for the counter
count1	res 1
count1s	res 1
delayb	res 1		; Counter for the bit delay
delaybs	res 1
startl	res 1		; Counter for the low period of start signal
startls	res 1
starth	res 1		; Counter for the high period of start signal
starths	res 1
	
; Constants
constant    out_pin = 0
	
; Put this somewhere in Program memory
DMX	code

DMX_setup
	bcf	TRISC, out_pin    ; Pin 0 on C - output
	bsf	PORTC, out_pin	  ; Output 1 by default
	movlw	0x2
	movwf	count0s
	movlw	0x0
	movwf	count1s
	movlw	.17
	movwf	delaybs
	movlw	.25
	movwf	startls
	movlw	.5
	movwf	starths
	return

DMX_output
	; Counter set to 0x200, so it repeats 513 times
	movff	count0s, count0
	movff	count1s, count1
	call	DMX_start_signal
DMXol		
	call	DMX_output_byte
	movlw	0
	decf	count1, f
	subwfb	count0, f
	bc	DMXol
	retfie


; Sends out the start signal
DMX_start_signal
	movff	startls, startl
	; Send low
	bcf	PORTC, out_pin
ssll	call	DMX_bit_delay		; ssll = start signal low loop
	decfsz	startl
	bra	ssll
	; Send high
	movff	starths, starth
	bsf	PORTC, out_pin
sshl	call	DMX_bit_delay		; sshl = start signal high loop
	decfsz	starth
	bra	sshl
	
	return
	
	
; Writes 8 bits to PORTC from FSR0
DMX_output_byte
	bcf	PORTC, out_pin	; send start bit
	nop
	nop
b0	call	DMX_bit_delay
	btfsc	INDF0, 0    ; Test bit 0, skip if clear
	bra	b0_1	    ; Go to case that outputs 1 on PORTC pin
	nop
	bcf	PORTC, out_pin	; Clear PORTC output pin
	bra	b1		; Branch to outputting next bit
b0_1	bsf	PORTC, out_pin	; Set PORTC pin
	nop
	nop
	
b1	call	DMX_bit_delay
	btfsc   INDF0, 1
	bra b1_1
	nop
	bcf PORTC, out_pin
	bra b2
b1_1	bsf PORTC, out_pin
	nop
	nop

b2	call	DMX_bit_delay
	btfsc   INDF0, 2
	bra b2_1
	nop
	bcf PORTC, out_pin
	bra b3
b2_1	bsf PORTC, out_pin
	nop
	nop

b3	call	DMX_bit_delay
	btfsc   INDF0, 3
	bra b3_1
	nop
	bcf PORTC, out_pin
	bra b4
b3_1	bsf PORTC, out_pin
	nop
	nop

b4	call	DMX_bit_delay
	btfsc   INDF0, 4
	bra b4_1
	nop
	bcf PORTC, out_pin
	bra b5
b4_1	bsf PORTC, out_pin
	nop
	nop

b5	call	DMX_bit_delay
	btfsc   INDF0, 5
	bra b5_1
	nop
	bcf PORTC, out_pin
	bra b6
b5_1	bsf PORTC, out_pin
	nop
	nop

b6	call	DMX_bit_delay
	btfsc   INDF0, 6
	bra b6_1
	nop
	bcf PORTC, out_pin
	bra b7
b6_1	bsf PORTC, out_pin
	nop
	nop

b7	call	DMX_bit_delay
	btfsc   POSTINC0, 7 ; increment the pointer
	bra b7_1
	nop
	bcf PORTC, out_pin
	bra b8
b7_1	bsf PORTC, out_pin
	nop
	nop
b8	call	DMX_bit_delay
	nop
	nop
	nop
	bsf PORTC, out_pin  ; send both end bytes
	call	DMX_bit_delay
	call	DMX_bit_delay
	nop
	nop
	nop
	return
	
DMX_bit_delay
	nop
	nop
	movff	delaybs, delayb
dbl	decfsz	delayb
	bra dbl
	return

end
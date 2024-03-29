	#include p18f87k22.inc

; Globals section
global	    DMX_setup, DMX_output

; Externals section
extern	    DMXdata

; Reserving space in RAM
DMX_vars    udata_acs		; Reserve space somewhere (swhere) in access RAM
count0	    res 1		; Counter up to 513 for reading memory
count0s	    res 1		; Source variable for the counter
count1	    res 1
count1s	    res 1
delayb	    res 1		; Counter for the bit delay
delaybs	    res 1
startl	    res 1		; Counter for the low period of start signal
startls	    res 1
starth	    res 1		; Counter for the high period of start signal
starths	    res 1

; Constants
constant    out_pin = 0
constant    out_pin_i = 1

; Interrupt
int_hi	code	0x0008
	btfss	INTCON,TMR0IF	; check that this is a timer0 interrupt
	retfie	FAST		; if not then return
	lfsr	FSR0, DMXdata	; Reset FSR0 to start of the data in RAM
	call	DMX_output	; Output the DMX signal
	bcf	INTCON,TMR0IF	; clear interrupt flag
	retfie	FAST		; fast return from interrupt

; Put this somewhere in Program memory
DMX	code

DMX_setup
	bcf	TRISC, out_pin    ; Pin 0 on C - output
	bsf	LATC, out_pin	  ; Output 1 by default
	bcf	TRISC, out_pin_i    ; Pin 1 on C - inverted output
	bcf	LATC, out_pin_i	  ; Output 0 by default

	; Set up counter defaults
	movlw	0x2
	movwf	count0s
	movlw	0x0
	movwf	count1s
	movlw	.17
	movwf	delaybs
	movlw	.50
	movwf	startls
	movlw	.16
	movwf	starths

	; Set timer0 to 16-bit, Fosc/4/16
	; 64MHz clock rate, 4 instructiosn, 16bit overflow,
	; 1:16 prescaler, gives 15.3Hz
	movlw	b'10000011'
	movwf	T0CON

	; Interrupt
	bsf	RCON, IPEN	; enables using interrupt priority
	bsf	INTCON, GIEH	; Enable all high-priority interrupts
	bsf	INTCON, TMR0IE	; Enable timer0 interrupt
	bsf	INTCON2, TMR0IP	; set priority to high

	return

DMX_output
	; Counter set to 0x200, so it repeats 513 times
	movff	count0s, count0
	movff	count1s, count1
	call	DMX_start_signal	; Send out the start signal first
DMXol
	; Output 513 bytes of data
	call	DMX_output_byte
	movlw	0
	decf	count1, f
	subwfb	count0, f
	bc	DMXol
	return


; Sends out the start signal
DMX_start_signal
	movff	startls, startl
	; Send low, note that out_pin and out_pin_i always set to opposite values
	bcf	LATC, out_pin
	bsf	LATC, out_pin_i
ssll	call	DMX_bit_delay		; ssll = start signal low loop
	decfsz	startl
	bra	ssll
	; Send high
	movff	starths, starth
	bsf	LATC, out_pin
	bcf	LATC, out_pin_i
sshl	call	DMX_bit_delay		; sshl = start signal high loop
	decfsz	starth
	bra	sshl

	return


; Writes 8 bits to PORTC from FSR0
DMX_output_byte
	bcf	LATC, out_pin	; send start bit
	bsf	LATC, out_pin_i
	nop
	nop
b0	call	DMX_bit_delay
	btfsc	INDF0, 0    ; Test bit 0, skip if clear
	bra	b0_1	    ; Go to case that outputs 1 on PORTC pin
	nop
	bcf	LATC, out_pin	; Clear PORTC output pin
	bsf	LATC, out_pin_i
	bra	b1		; Branch to outputting next bit
b0_1	bsf	LATC, out_pin	; Set PORTC output pin
	bcf	LATC, out_pin_i
	nop
	nop

; Repeat the above for all the other bits
b1	call	DMX_bit_delay
	btfsc	INDF0, 1
	bra	b1_1
	nop
	bcf	LATC,	out_pin
	bsf	LATC,	out_pin_i
	bra	b2
b1_1	bsf	LATC,	out_pin
	bcf	LATC,	out_pin_i
	nop
	nop

b2	call	DMX_bit_delay
	btfsc	INDF0,	2
	bra	b2_1
	nop
	bcf	LATC,	out_pin
	bsf	LATC,	out_pin_i
	bra	b3
b2_1	bsf	LATC,	out_pin
	bcf	LATC,	out_pin_i
	nop
	nop

b3	call	DMX_bit_delay
	btfsc	INDF0,	3
	bra	b3_1
	nop
	bcf	LATC,	out_pin
	bsf	LATC,	out_pin_i
	bra	b4
b3_1	bsf	LATC,	out_pin
	bcf	LATC,	out_pin_i
	nop
	nop

b4	call	DMX_bit_delay
	btfsc	INDF0, 4
	bra	b4_1
	nop
	bcf	LATC,	out_pin
	bsf	LATC,	out_pin_i
	bra	b5
b4_1	bsf	LATC,	out_pin
	bcf	LATC,	out_pin_i
	nop
	nop

b5	call	DMX_bit_delay
	btfsc	INDF0, 5
	bra	b5_1
	nop
	bcf	LATC, out_pin
	bsf	LATC, out_pin_i
	bra	b6
b5_1	bsf	LATC,	out_pin
	bcf	LATC,	out_pin_i
	nop
	nop

b6	call	DMX_bit_delay
	btfsc	INDF0, 6
	bra	b6_1
	nop
	bcf	LATC,	out_pin
	bsf	LATC,	out_pin_i
	bra	b7
b6_1	bsf	LATC, out_pin
	bcf	LATC, out_pin_i
	nop
	nop

b7	call	DMX_bit_delay
	btfsc	POSTINC0, 7 ;  this is the last bit, so increment FSR0 in time to point to next address
	bra	b7_1
	nop
	bcf	LATC,	out_pin
	bsf	LATC,	out_pin_i
	bra	b8
b7_1	bsf	LATC, out_pin
	bcf	LATC, out_pin_i
	nop
	nop
b8	call	DMX_bit_delay
	nop
	nop
	nop
	bsf	LATC, out_pin  ; send both end bytes
	bcf	LATC, out_pin_i
	call	DMX_bit_delay
	call	DMX_bit_delay
	nop
	nop
	nop
	return

; Delay that brings the bits up to 4us
DMX_bit_delay
	;nop
	nop
	movff	delaybs, delayb
dbl	decfsz	delayb
	bra	dbl
	return

end

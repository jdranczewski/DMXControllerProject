	#include p18f87k22.inc

; Globals section
global	DMXdata
; Externals section
extern	DMX_setup, DMX_output
extern  dial_setup, dial_read
	
; Reserving space in RAM
swhere  udata_acs	; Reserve space somewhere (swhere) in access RAM
count0	res 1
count1	res 1
inc_tmp	res 1
	
there	udata_acs .95	; Put the 0th byte of DMX data in access RAM
DMXdata res 1
 
shared	udata_shr	; Put the actual data across banks 0-2
d1u	udata	.96
d1	res	.160
d2u	udata	0x100
d2	res	.256
d3u	udata	0x200
d3	res	.96

; Constants

; Reset to 0	
rst	code	0
	goto	setup


; Put code somewhere in Program Memory
main	code
 
setup
	lfsr	FSR0, DMXdata
	call	write_some_data
	lfsr	FSR1, DMXdata
	incf	FSR1L, f
	call	DMX_setup
	call	dial_setup
	bra	$

; Write incrementing values to DMX data block
write_some_data
	; Counter set to 0x200, so it repeats 513 times
	movlw	0x2
	movwf	count0
	movlw	0x0
	movwf	count1
	movwf	inc_tmp
wsdl	movff	inc_tmp, POSTINC0    ; Move incrementing value to the DMX data
	incf	inc_tmp, f
	decf	count1, f
	subwfb	count0, f
	bc	wsdl
	return
	
	end

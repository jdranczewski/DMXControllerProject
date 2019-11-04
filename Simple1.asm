	#include p18f87k22.inc

; Externals section
	
; Reserving space in RAM
	; Put the 0th byte in access RAM for ease of access
	udata_acs	.95
DMXdata res 1
 
	; Put the actual data across banks 0-2 
	udata_shr
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
main code

setup
	bra $
	
	end

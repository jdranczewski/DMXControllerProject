	#include p18f87k22.inc

; Externals section
	
; Reserving space in RAM

; Constants

; Reset to 0	
rst	code	0
	goto	setup


; Put code somewhere in Program Memory
main code

setup
	bra $
	
	end

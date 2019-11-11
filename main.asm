	#include p18f87k22.inc

; Globals section
global	DMXdata
; Externals section
extern	DMX_setup, DMX_output
extern  dial_setup
extern	keyb_setup, keyb_read_code_change
extern	LCD_setup, LCD_Send_Byte_D, LCD_clear
	
; Reserving space in RAM
swhere  udata_acs	; Reserve space somewhere (swhere) in access RAM
count0	res 1
count1	res 1
inc_tmp	res 1
mode	res 1
; Buttons
F	res 1
_C	res 1
invalid	res 1
	
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
	
; Data
pdata	code	0x500    
;kcodes	db	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, .1, .2, .3, "F", 0xFF, .4, .5, .6, 0xFF, 0xFF, .7, .8, .9, 0xFF, 0xFF, 0xFF, .0, 0xFF, "C"
kcodes	db	0, 0, 0, 0, 0, 0, "1", "2", "3", "F", 0, "4", "5", "6", "E", 0, "7", "8", "9", "D", 0, "A", "0", "B", "C"

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
	call	keyb_setup
	call	LCD_setup
	
	movlw	0
	movwf	mode
	movwf	invalid
	
	movlw	.9
	movwf	F
	movlw	.24
	movwf	_C
	
	movlw	0
	movwf	TRISC
	bcf	LATC, 5
	

loop	movlw	.0
	cpfseq	mode
	bra	m1if
	bra	mode0
m1if	movlw	.1
	cpfseq	mode
	bra	loop
	bra	mode1	
	
mode0	call	keyb_read_code_change
	cpfseq	F
	bra	loop
	movlw	.1
	movwf	mode
	movlw	"C"
	call	LCD_Send_Byte_D
	call	number_input_setup
	bra	loop

mode1	movlw	low(kcodes)
	movwf	TBLPTRL
	call	keyb_read_code_change
	cpfseq	_C
	bra	m1cont0
	movlw	.0
	movwf	mode
	call	LCD_clear
	bra	loop
m1cont0	cpfseq	invalid
	bra	m1cont1
	bra	loop
m1cont1	addwf	TBLPTRL
	tblrd*
	movf	TABLAT, W
	call	LCD_Send_Byte_D
	
	bra	loop

	
number_input_setup
	movlw	upper(kcodes)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(kcodes)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(kcodes)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	return
	
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

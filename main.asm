	#include p18f87k22.inc

; Globals section
global	DMXdata
; Externals section
extern	DMX_setup, DMX_output
extern  dial_setup, dial_flag
extern	keyb_setup, keyb_read_code_change, keyb_read_raw
extern	LCD_setup, LCD_Write_Message_TBLPTR, LCD_Send_Byte_D, LCD_clear
extern	deci_setup, deci_keypress, deci_start, deci_bufferL, deci_bufferH
	
; Reserving space in RAM
swhere  udata_acs	; Reserve space somewhere (swhere) in access RAM
count0	res 1
count1	res 1
tmp	res 1
mode	res 1
; Buttons
F	res 1
_C	res 1
	
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
	
pdata_main code  
ch_str	data	"Channel:"
; Reset to 0	
rst	code	0
	goto	setup


; Put code somewhere in Program Memory
main	code
 
setup
	lfsr	FSR0, DMXdata	; Point FSR to DMX values for output
	call	write_some_data
	lfsr	FSR1, DMXdata	; Point FSR to DMX values for input
	incf	FSR1L, f	; Write to channel 1, as channel 0 consists of all zeroes
	call	DMX_setup
	call	dial_setup
	call	keyb_setup
	call	LCD_setup
	call	deci_setup
	
	movlw	0		
	movwf	mode		; Default mode 0
	
	
	; Keycodes for buttons 
	movlw	.9		
	movwf	F		; Channel select
	movlw	.24
	movwf	_C		; Enter
	
	; Set Port C as output
	movlw	0
	movwf	TRISC
	bcf	LATC, 5
	
; Main mode selection loop
loop	movlw	.0
	cpfseq	mode	; compare 0 to mode variable
	bra	m1if	; if not 0, go to other mode comparison
	bra	mode0	; if 0, branch to mode 0 implementation
m1if	movlw	.1
	cpfseq	mode
	bra	loop
	bra	mode1	
	
; Mode 0 implementation
mode0_init
	movlw	.0			    
	movwf	mode			
	call	LCD_clear
	
mode0	
	call	keyb_read_raw		    ; Check if D is pressed
	movwf	tmp
	movlw	0xED
	cpfseq	tmp
	bra	m0cont0
	bsf	ADCON0, GO		    ; If D is pressed, run the ADC conversion
m0cont0	call	keyb_read_code_change	    ; read in keyboard input
	cpfseq	F			    ; compare to "channel select" keycode
	bra	loop			    ; if F not pressed, go back to loop
	bra	mode1_init
	bra	loop

; Mode 1 implementation
mode1_init
	call	LCD_clear
	movlw	.1
	movwf	mode			    ;if F pressed, change mode variable to 1
	; Print out Channel on the LCD screen
	call	ch_dsp
	call	deci_start		    ; moves keycodes to program memory

mode1	
	call	keyb_read_code_change	    ; read keyboard input
	cpfseq	_C			    ; compare to "enter" keycode
	bra	m1cont0			    ; not enter - go to m1cont0
	; if enter - change channel and go back to mode 0
	call	change_channel
	bra	mode0_init
	bra	loop
m1cont0	cpfseq	F
	bra	m1cont1
	bra	mode1_init
m1cont1	call	deci_keypress
	bra	loop			   

change_channel
	lfsr	FSR1, DMXdata	    ; Reset FSR1
	; Limit the value to 512 (0x200)
	movlw	0x02		    ; Check if high byte is 0x02
	cpfseq	deci_bufferH
	bra	cccont0		    ; If not, go to next check
	movlw	0x00		    ; iF yes, check if low byte greater than 0
	cpfsgt	deci_bufferL
	bra	set_channel	    ; If not, set channel
	bra	limit_max	    ; If yes, limit
cccont0
	movlw	0x02		    ; If high byte greater than 0x02, always limit
	cpfsgt	deci_bufferH
	bra	set_channel	
limit_max
	movlw	0x02		    ; Load 512 into the buffers manually
	movwf	deci_bufferH
	movlw	0
	movwf	deci_bufferL
set_channel	
	movf	deci_bufferL, W	    ; Add to FSR1 remembering about carry bit
	addwf	FSR1L, f
	movf	deci_bufferH, W
	addwfc	FSR1H, f
	return
	
ch_dsp
	movlw	upper(ch_str)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(ch_str)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(ch_str)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	movlw	.8
	call	LCD_Write_Message_TBLPTR
	return	
	
; Write incrementing values to DMX data block
write_some_data
	; Counter set to 0x200, so it repeats 513 times
	movlw	0x2
	movwf	count0
	movlw	0x0
	movwf	count1
	movwf	tmp
wsdl	movff	tmp, POSTINC0    ; Move incrementing value to the DMX data
	incf	tmp, f
	decf	count1, f
	subwfb	count0, f
	bc	wsdl
	return
	
	end

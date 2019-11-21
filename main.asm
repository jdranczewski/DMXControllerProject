	#include p18f87k22.inc

; Globals section
global	DMXdata
; Externals section
extern	DMX_setup, DMX_output
extern  dial_setup
extern	keyb_setup, keyb_read_code_change, keyb_read_raw
extern	LCD_setup, LCD_Write_Message_TBLPTR, LCD_Send_Byte_D, LCD_clear, m16L, m16H, LCD_hextodec, LCD_goto_pos
extern	deci_setup, deci_keypress, deci_start, deci_bufferL, deci_bufferH

; Reserving space in RAM
swhere  udata_acs	; Reserve space somewhere (swhere) in access RAM
count0	res 1		; Counter for initialising dmx data
count1	res 1
tmp	res 1
mode	res 1		; This variable determines the current mode
chanH	res 1		; Current channel number (two bytes)
chanL	res 1
; Button codes
_F	res 1
_C	res 1
_N	res 1
_P	res 1
_R	res 1

there	udata_acs .95	; Put the 0th byte of DMX data in access RAM for easy access
DMXdata res 1

shared	udata_shr	; Put the actual data across banks 0-2, right after the DMXdata label
d1u	udata	.96
d1	res	.160
d2u	udata	0x100
d2	res	.256
d3u	udata	0x200
d3	res	.96

; Data
pdata_main code
ch_str	data	"Channel:"

; Reset to 0, call setup
rst	code	0
	goto	setup

; Put code somewhere in Program Memory
main	code

setup
	lfsr	FSR0, DMXdata	; Point FSR to DMX values for output
	lfsr	FSR2, DMXdata	; Point FSR to DMX values for resetting all channel values to 0
	call	write_some_data	; Write placeholder data to all DMX bytes in RAM
	lfsr	FSR1, DMXdata	; Point FSR to DMX values for input
	; Write to channel 1, as channel 0 consists of all zeroes
	; This is safe to do as we know FSR1 is 0x0060, so no overflow on increment
	incf	FSR1L, f
	; Call all the library setups
	call	DMX_setup
	call	dial_setup
	call	keyb_setup
	call	LCD_setup
	call	deci_setup

	movlw	0
	movwf	mode		; Default mode 0
	movwf	chanL		; Default channel is 1
	incf	chanL
	movwf	chanH

	; Keycodes for buttons
	movlw	.24
	movwf	_F		; Channel select
	movlw	.9
	movwf	_C		; Enter
	movlw	.8
	movwf	_N		; Next
	movlw	.6
	movwf	_P		; Previous
	movlw	.19
	movwf	_R		; Reset

	; Initialise mode 0
	bra	mode0_init

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
	; Set mode variable
	movlw	.0
	movwf	mode
	call	LCD_clear		; Clear LCD
	call	deci_start		; Initialise decimal input

	; Display channel numbers
	; Current
	movlw	0x05
	call	LCD_goto_pos
	; Channel number needs to be converted to decimal
	movff	chanL, m16L
	movff	chanH, m16H
	call	LCD_hextodec
	; Previous
	movlw	0x00
	call	LCD_goto_pos
	movlw	"c"	; Display a label for this row
	call	LCD_Send_Byte_D
	movlw	0
	decf	m16L
	subwfb	m16H
	call	LCD_hextodec
	; Next
	movlw	0x0D
	call	LCD_goto_pos
	movlw	0
	incf	m16L	;Increment twice to get to the 'next' channel starting from 'prev'
	addwfc	m16H
	incf	m16L
	addwfc	m16H
	call	LCD_hextodec

	; Display channel values
	movlw	0x45
	call	LCD_goto_pos
	; Low byte of channel value always 0
	movlw	0
	movwf	m16H
	; Cycle through channels and display
	; Current
	movff	POSTDEC1, m16L
	call	LCD_hextodec
	; Display arrow
	movlw	0xF9
	call	LCD_Send_Byte_D
	; Previous
	movlw	0x40
	call	LCD_goto_pos
	movlw	"v"	; Display a label for this row
	call	LCD_Send_Byte_D
	movff	POSTINC1, m16L
	call	LCD_hextodec
	; Next
	movlw	0x4D
	call	LCD_goto_pos
	movff	POSTINC1, m16L	; Increment FSR1, and then decrement back to current channel
	movff	POSTDEC1, m16L
	call	LCD_hextodec
	; Move cursor to input position
	movlw	0x49
	call	LCD_goto_pos

mode0
	; Check if D is pressed
	call	keyb_read_raw
	movwf	tmp
	movlw	0xEB
	cpfseq	tmp
	bra	m0cont0
	bsf	ADCON0, GO		    ; If D is pressed, start the ADC conversion
m0cont0
	call	keyb_read_code_change	    ; read in keyboard input on press
	cpfseq	_F			    ; compare to "channel select" keycode
	bra	m0cont1			    ; if F not pressed, continue
	bra	mode1_init
m0cont1
	cpfseq	_C			    ; compare to "enter" keycode
	bra	m0cont2			    ; not enter - go to m0cont2
	; if enter - change value and init mode 0 again
	call	change_value
	bra	mode0_init
m0cont2
	cpfseq	_N
	bra	m0cont3
	; If next is pressed, change channel and initialise mode0 again
	call next_channel
	bra	mode0_init
m0cont3
	cpfseq	_P
	bra m0cont4
	; If prev is pressed, change channel and initialise mode0 again
	call prev_channel
	bra	mode0_init
m0cont4
	cpfseq	_R
	bra m0cont5
	;If reset pressed, write zeroes to all channels
	call write_some_data
	bra	mode0_init
m0cont5
	; If no special keys pressed, handle the press as decimal input
	call	deci_keypress
	bra	loop

; Mode 1 implementation
mode1_init
	call	LCD_clear
	; Change mode variable
	movlw	.1
	movwf	mode
	; Print out Channel on the LCD screen
	call	ch_dsp
	call	deci_start		    ; Initialise decimal input

mode1
	call	keyb_read_code_change	    ; read keyboard input on press
	cpfseq	_C			    ; compare to "enter" keycode
	bra	m1cont0			    ; not enter - go to m1cont0
	; if enter - change channel and go back to mode 0
	call	change_channel
	bra	mode0_init
m1cont0	cpfseq	_F	; Check if "channel select" button pressed
	bra	m1cont1
	bra	mode1_init	; If yes, restart channel selection
m1cont1	call	deci_keypress	; Handle the keypress as decimal input
	bra	loop

; Set current channel value to value from deci_buffer
change_value
	movlw	0x00		    ; Compare to 255 (0xFF), the maximum
	cpfsgt	deci_bufferH
	bra	cvcont
	movlw	0xFF	; If first byte of provided value > 0, value > 0x0FF, set to 255
	movwf	deci_bufferL
cvcont
	movff	deci_bufferL, INDF1 ; Move value to address pointed to by FSR1
	return

; Set channel pointer to value from deci_buffer
change_channel
	lfsr	FSR1, DMXdata	    ; Reset FSR1
	; Check if value in buffer zero
	movlw	0
	cpfseq	deci_bufferH
	bra	cccont0
	cpfseq	deci_bufferL
	bra	cccont0
	movlw	.1		    ; Set to 1 if input is 0
	movwf	deci_bufferL
	bra	set_channel
	; Limit the value to 512 (0x200)
cccont0	movlw	0x02		    ; Check if high byte is 0x02
	cpfseq	deci_bufferH
	bra	cccont1		    ; If not, go to next check
	movlw	0x00		    ; If yes, check if low byte greater than 0
	cpfsgt	deci_bufferL
	bra	set_channel	    ; If not, set channel
	bra	limit_max	    ; If yes, limit
cccont1
	movlw	0x02		    ; If high byte greater than 0x02, always limit
	cpfsgt	deci_bufferH
	bra	set_channel
limit_max
	; Load 512 into the buffers manually
	movlw	0x02
	movwf	deci_bufferH
	movlw	0
	movwf	deci_bufferL
set_channel
	; Add buffer to FSR1 remembering about the carry bit
	movf	deci_bufferL, W
	addwf	FSR1L, f
	movwf	chanL		    ; Put channel number into the channel indicator as well
	movf	deci_bufferH, W
	addwfc	FSR1H, f	; Add W with carry
	movwf	chanH
	return

; Increment current channel by 1
next_channel
	; Move current channel to the deci_buffer (which is then used by change_channel)
	movff	chanL, deci_bufferL
	movff	chanH, deci_bufferH
	; Increment with carry
	movlw	0x00
	incf	deci_bufferL
	addwfc	deci_bufferH
	call	change_channel
	return

; Decrement current channel by 1
prev_channel
	movff	chanL, deci_bufferL
	movff	chanH, deci_bufferH
	; Decrement with borrow
	movlw	0x00
	decf	deci_bufferL
	subwfb	deci_bufferH
	call	change_channel
	return

; Display the string "Channel:" (stored in program memory)
ch_dsp
	; Move TBLPTR to message
	movlw	upper(ch_str)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(ch_str)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(ch_str)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	movlw	.8	; Length of message into W
	; Write message from TBLPTR
	call	LCD_Write_Message_TBLPTR
	return

; Write initial values to DMX data block
write_some_data
	lfsr	FSR2,DMXdata
	; Counter set to 0x201, so it repeats 514 times
	; (512 addresses + 1 byte of padding in both directions)
	movlw	0x2
	movwf	count0
	movlw	0x01
	movwf	count1
	movlw	0
	movwf	tmp
wsdl	movff	tmp, POSTINC2    ; Move value to the DMX data
	; Initially we wrote incrementing values to subsequent channels ot test date transmission.
	; Can be enabled by uncommenting line below
	;incf	tmp, f
	decf	count1, f	; Decrement two-byte counter, return when it runs out
	subwfb	count0, f
	bc	wsdl
	return

	end

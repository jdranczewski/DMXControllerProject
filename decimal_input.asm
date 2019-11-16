	#include p18f87k22.inc

; Globals section
global	    deci_setup, deci_start, deci_keypress, deci_bufferL, deci_bufferH, deci_counter

; Externals section
extern	    LCD_Send_Byte_D

; Reserving space in RAM
dwhere		    udata_acs
invalid		    res 1	; The number used to signify keys that are not decimal digits
keycode_temp	    res 1
deci_bufferL	    res 1	; Final value is put in the buffer
deci_bufferH	    res 1
deci_buffer_temp    res 1
deci_counter	    res	1

; Data - by setting it to start at 0x500, we avoid clashes with our code,
; as well as ensure that incrementing the low bit ot TBLPTR by 24 doesn't
; result in overflow
pdata	code	0x500
; Map keycodes (numbers 0-24) to numbers shown on the keyboard
kcodes	db	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, .0, 0xFF, 0xFF, 0xFF, .7, .8, .9, 0xFF, 0xFF, .4, .5, .6, 0xFF, 0xFF, .1, .2, .3, 0xFF
;kcodes	db	0, 0, 0, 0, 0, 0, "1", "2", "3", "F", 0, "4", "5", "6", "E", 0, "7", "8", "9", "D", 0, "A", "0", "B", "C"

; Put this somewhere in Program memory
deci	code

deci_setup
	movlw	0xFF
	movwf	invalid		; set invalid character value to be 0xFF
	return

deci_start
	; Set TBLPTR to point to the keycode mapping
	movlw	upper(kcodes)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(kcodes)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(kcodes)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL

	; reset buffers
	movlw	0
	movwf	deci_bufferL
	movwf	deci_bufferH

	; Allow inputing up to three characters
	movlw	.4
	movwf	deci_counter
	return

deci_reset
	movlw	low(kcodes)		    ; resetting table pointer to the start of the keycodes
	movwf	TBLPTRL
	retfie	FAST

; Takes in a keycode (0-24) in the working register
deci_keypress
	call	deci_reset, FAST
	addwf	TBLPTRL			    ; add keycode to TBLPTR, which will then point to the number the user typed
	; Read from program memory and move to W
	tblrd*
	movf	TABLAT, W
	cpfseq	invalid			    ; check if keyboard input is valid
	bra	dk_cont1
	return	; Return without further action if input invalid
dk_cont1
	movwf	keycode_temp
	; Decrement the counter, skip if zero
	decfsz	deci_counter
	bra	dk_cont2
	; Set the counter to 1 to avoid overflow when more than 3 ch. inputed
	movlw	.1
	movwf	deci_counter
	return
dk_cont2
	; multiply memory buffer by 10
	movlw	0xA
	movff	deci_bufferH, deci_buffer_temp
	mulwf	deci_bufferL	; multiply low byte
	movff	PRODL, deci_bufferL
	movff	PRODH, deci_bufferH
	mulwf	deci_buffer_temp	; multiply high byte and add to result
	movf	PRODL, W
	addwf	deci_bufferH, f

	; add the key pressed to the memory buffer
	movf	keycode_temp, W
	addwf	deci_bufferL
	movlw	0
	addwfc	deci_bufferH

	; convert number to ascii and display
	movlw	0x30			    ; add 0x30 to the key pressed
	addwf	keycode_temp, W
	call	LCD_Send_Byte_D		    ; print number on the LCD

	return



end

	#include p18f87k22.inc

; Globals section
global	    deci_setup, deci_start, deci_keypress
	
; Externals section
extern	    LCD_Send_Byte_D
	
; Reserving space in RAM
swhere		    udata_acs
invalid		    res 1
keycode_temp	    res 1
deci_bufferL	    res 1
deci_bufferH	    res 1	
deci_buffer_temp    res 1
deci_counter	    res	1
	
; Constants
;constant  
	
; Data
pdata	code	0x500  
kcodes	db	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, .1, .2, .3, "F", 0xFF, .4, .5, .6, 0xFF, 0xFF, .7, .8, .9, 0xFF, 0xFF, 0xFF, .0, 0xFF, "C"
;kcodes	db	0, 0, 0, 0, 0, 0, "1", "2", "3", "F", 0, "4", "5", "6", "E", 0, "7", "8", "9", "D", 0, "A", "0", "B", "C"
	
; Put this somewhere in Program memory
deci	code

deci_setup
	movlw	0xFF
	movwf	invalid		; set invalid character value to be FF
	return

deci_start
	movlw	upper(kcodes)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(kcodes)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(kcodes)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	
	; reset memory buffers
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
	
; Takes in a keycode in the working register
deci_keypress
	call	deci_reset, FAST
	addwf	TBLPTRL			    ; read keycode from program memory
	tblrd*
	movf	TABLAT, W
	cpfseq	invalid			    ; check if keyboard input is valid
	bra	dk_cont1
	return			   
dk_cont1
	movwf	keycode_temp
	; Decrement the counter
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
	mulwf	deci_bufferL
	movff	PRODL, deci_bufferL
	movff	PRODH, deci_bufferH
	mulwf	deci_buffer_temp
	movf	PRODL, W
	addwf	deci_bufferH, f
	
	; add the keypress to the memory buffer
	movf	keycode_temp, W
	addwf	deci_bufferL
	movlw	0
	addwfc	deci_bufferH
	
	; convert number to ascii and display
	movlw	0x30			    ; add 0x30 to the key pressed
	addwf	keycode_temp, W
	call	LCD_Send_Byte_D		    ; print valid numbers on the LCD
	
	return
	
	

end
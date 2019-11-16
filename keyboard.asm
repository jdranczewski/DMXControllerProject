    #include p18f87k22.inc

global keyb_setup, keyb_read_raw, keyb_read_code, keyb_read_code_change

acs0    udata_acs	    ; named variables in access ram
keyb_delay_counter  res 1
keyb_temp	    res 1 ; Some temporary variables
keyb_encode_temp    res 1
keyb_swap_temp	    res	1   ; Apparently swapf on W deosn't work
keyb_prev	    res 1   ; The previous character
kb_cnt_l	    res 1
kb_cnt_h	    res 1
kb_cnt_ms	    res 1

constant    delay = 0x0F

keyb	code

keyb_setup
	banksel	PADCFG1			; Select memory bank
	bsf	PADCFG1, REPU, BANKED	; Turn on pull-ups on E
	movlb	0x0			; Return to default bank
	clrf	LATE			; Clear the latch on E
	movlw	0x0			; Store 0 as the 'previous' char
	movwf	keyb_prev
	return

; Read just the pure row, column information into W
keyb_read_raw
	call	keyb_rows
	call	keyb_delay
	movff	PORTE, keyb_temp
	call	keyb_cols
	call	keyb_delay
	movf	PORTE, W
	iorwf	keyb_temp, W ; Combine row and column information into a single byte
	return

; Encode the keys into 25 different keycodes
keyb_read_code
	movlw	0x10
	call	kb_delay_ms

	call	keyb_rows		; Get the row
	call	keyb_delay
	movf	PORTE, W
	call	keyb_encode		; Encode row on a scale of 0-4
	movwf	keyb_temp		; Move code to temp to multiply
	movlw	.5
	mulwf	keyb_temp  ; Product stored in PRODH and PRODL registers

	call	keyb_cols		; Get the column
	call	keyb_delay
	movff	PORTE, keyb_swap_temp	; Swap the nibbles
	swapf	keyb_swap_temp, W
	call	keyb_encode		; Encode column on a scale of 0-4
	addwf	PRODL, W		; Add row code*5 and column code

	return

; Read in a character, but put 0 in W if no change
keyb_read_code_change
	movlw	0x10			; Delay 16ms at the start
	call	kb_delay_ms
; Check if previous raw keycode was 0x255. If yes, we're on a 'rising edge',
; the user has just pressed the key
	movlw	0xFF
	cpfseq	keyb_prev
	bra	no255
yes255	call	keyb_read_raw
	movwf	keyb_prev  ; Save the keycode for future reference
	movlw	0xFF
	cpfseq	keyb_prev ; Check if any button pressed currently
	bra	skip255
  ; If no button pressed, return 0
	movlw	0x0
	return
skip255	call	keyb_read_code ; If a button is pressed, return its keycode
	return
no255	call	keyb_read_raw  ; If previous value was not 0xFF, this is not a valid keypress
	movwf	keyb_prev  ; Save the raw keycode
  ; Return a zero (invalid keypress)
	movlw	0x0
	return

; Setup Port E for reading rows
keyb_rows
	movlw	0x0F
	movwf	TRISE
	return

; Setup Port E for reading columns
keyb_cols
	movlw	0xF0
	movwf	TRISE
	return

; Encode binary flags to row/column numbers
; 1110 (14) - 4
; 1101 (13) - 3
; 1011 (11) - 2
; 0111 (7) - 1
; anything else - 0
keyb_encode
	movwf	keyb_encode_temp
	movlw	.14
	cpfseq	keyb_encode_temp  ; Compare current raw keycode with 1110
	bra	kbe_13 ; If not matching, check next
	movlw	.4 ; If matching, return 4
	return
kbe_13	movlw	.13
	cpfseq	keyb_encode_temp
	bra	kbe_11
	movlw	.3
	return
kbe_11	movlw	.11
	cpfseq	keyb_encode_temp
	bra	kbe_7
	movlw	.2
	return
kbe_7	movlw	.7
	cpfseq	keyb_encode_temp
	bra	kbe_0
	movlw	.1
	return
; If raw keycode invalid (multiple keys pressed), return 0
kbe_0	movlw	.0
	return

; A delay to make sure inputs from pins are read correctly
keyb_delay
	movlw	delay
	movwf	keyb_delay_counter
kb_dl_b	decfsz keyb_delay_counter
	bra kb_dl_b
	return

; A delay to account for the time it takes for the voltage to drop when the button is pushed
kb_delay_x4us			; delay given in chunks of 4 microsecond in W
	movwf	kb_cnt_l	; now need to multiply by 16
	swapf   kb_cnt_l,F	; swap nibbles
	movlw	0x0f
	andwf	kb_cnt_l,W	; move low nibble to W
	movwf	kb_cnt_h	; then to kb_cnt_h
	movlw	0xf0
	andwf	kb_cnt_l,F	; keep high nibble in kb_cnt_l
	call	kb_delay
	return

kb_delay			; delay routine	4 instruction loop == 250ns
	movlw 	0x00		; W=0
kblp1	decf 	kb_cnt_l,F	; no carry when 0x00 -> 0xff
	subwfb 	kb_cnt_h,F	; no carry when 0x00 -> 0xff
	bc 	kblp1		; carry, then loop again
	return			; carry reset so return

kb_delay_ms		    ; delay given in ms in W
	movwf	kb_cnt_ms
lcdlp2	movlw	.250	    ; 1 ms delay
	call	kb_delay_x4us
	decfsz	kb_cnt_ms
	bra	lcdlp2
	return

end

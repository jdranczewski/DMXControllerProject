#include p18f87k22.inc

; Globals section
global  LCD_setup, LCD_Write_Message, LCD_Write_Message_TBLPTR, LCD_Send_Byte_D, LCD_goto_pos, LCD_clear,  m16L, m16H, LCD_hextodec

; Reserving space in RAM
acs0    udata_acs   ; named variables in access ram
LCD_cnt_l   res 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h   res 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms  res 1   ; reserve 1 byte for ms counter
LCD_tmp	    res 1   ; reserve 1 byte for temporary use
LCD_counter res 1   ; reserve 1 byte for counting through message

; Variables for multiplication
m8	    res	1
m8_2	    res 1
m16L	    res	1
m16H	    res 1
m24U	    res 1
m24H	    res 1
m24L	    res 1
m32L	    res 1
m32H	    res 1
m32U	    res 1
m32UU	    res 1

; Constants
constant    LCD_E=5	; LCD enable bit
constant    LCD_RS=4	; LCD register select bit

; Put this somewhere in Program memory
LCD	code

LCD_setup
	clrf    LATB
	movlw   b'11000000'	    ; RB0:5 all outputs
	movwf	TRISB
	movlw   .40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	movlw	b'00110000'	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	movlw	b'00101000'	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	movlw	b'00101000'	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	movlw	b'00001111'	; display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	movlw	b'00000001'	; display clear
	call	LCD_Send_Byte_I
	movlw	.2		; wait 2ms
	call	LCD_delay_ms
	movlw	b'00000110'	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	return

LCD_Write_Message	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter
LCD_Loop_message
	movf    POSTINC2, W
	call    LCD_Send_Byte_D
	decfsz  LCD_counter
	bra	LCD_Loop_message
	return

LCD_Write_Message_TBLPTR    ; Message stored at TBLPTR, length stored in W
	movwf   LCD_counter
LCD_Loop_message_TBLPTR
	tblrd*+
	movf    TABLAT, W
	call    LCD_Send_Byte_D
	decfsz  LCD_counter
	bra	LCD_Loop_message_TBLPTR
	return

LCD_goto_pos
	movwf	LCD_tmp
	movlw	b'10000000'
	iorwf	LCD_tmp, W ; Command for position is 1ppppppp, where p are bits describing position address
	call	LCD_Send_Byte_I
	movlw	.10		; wait 40us
	call	LCD_delay_x4us
	return

LCD_clear
	movlw	b'00000001'
	call	LCD_Send_Byte_I
	movlw	.2		; wait 2ms
	call	LCD_delay_ms
	return

LCD_Send_Byte_I		    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp
	swapf   LCD_tmp,W   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB	    ; output data bits to LCD
	bcf	LATB, LCD_RS	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit
	movf	LCD_tmp,W   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB	    ; output data bits to LCD
	bcf	LATB, LCD_RS    ; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit
	return

LCD_Send_Byte_D		    ; Transmits byte stored in W to data reg
	movwf   LCD_tmp
	swapf   LCD_tmp,W   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB	    ; output data bits to LCD
	bsf	LATB, LCD_RS	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit
	movf	LCD_tmp,W   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB	    ; output data bits to LCD
	bsf	LATB, LCD_RS    ; Data write set RS bit
        call    LCD_Enable  ; Pulse enable Bit
	movlw	.10	    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	    LATB, LCD_E	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	    LATB, LCD_E	    ; Writes data to LCD
	return

; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms		    ; delay given in ms in W
	movwf	LCD_cnt_ms
lcdlp2	movlw	.250	    ; 1 ms delay
	call	LCD_delay_x4us
	decfsz	LCD_cnt_ms
	bra	lcdlp2
	return

LCD_delay_x4us		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l   ; now need to multiply by 16
	swapf   LCD_cnt_l,F ; swap nibbles
	movlw	0x0f
	andwf	LCD_cnt_l,W ; move low nibble to W
	movwf	LCD_cnt_h   ; then to LCD_cnt_h
	movlw	0xf0
	andwf	LCD_cnt_l,F ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay			; delay routine	4 instruction loop == 250ns
	movlw 	0x00		; W=0
lcdlp1	decf 	LCD_cnt_l,F	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h,F	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return


mul8x16
	movf	m8,W
	mulwf	m16L
	movff	PRODL,m24L
	movff	PRODH,m24H
	mulwf	m16H
	movf	PRODL,W
	addwf	m24H,f
	movff	PRODH,m24U
	movlw	0
	addwfc	m24U,f
	return


; Hex to decimal conversion multiplication helper functions
mul16x16
	call	mul8x16
	movff	m24L,m32L
	movff	m24H,m32H
	movff	m24U,m32U
	movff	m8_2,m8
	call	mul8x16
	movf	m24L,W
	addwf	m32H,f
	movf	m24H,W
	addwfc  m32U,f
	movff	m24U,m32UU
	movlw	0
	addwfc  m32UU,f
	return

mul8x24
	movf	m8,W
	mulwf	m24L
	movff	PRODL,m32L
	movff	PRODH,m32H

	mulwf	m24H
	movf	PRODL,W
	addwf	m32H,f
	movff	PRODH,m32U
	movlw	0
	addwfc	m32U,f

	movf	m8,W
	mulwf	m24U
	movf	PRODL,W
	addwf	m32U
	movff	PRODH,m32UU
	movlw	0
	addwfc	m32UU,f

	return

; Convert and display a hexadecimal number in decimal
; Value to convert and display is stored in m16L and m16H
LCD_hextodec
	movlw	0x41
	movwf	m8_2
	movlw	0x8A
	movwf	m8
	call	mul16x16
	movf	m32UU,W
	; We don't need the first digit for this project (max decimal length is 3)
	;call	LCD_display_digit

	movlw	0x0A
	movwf	m8
	movff	m32U,m24U
	movff	m32H,m24H
	movff	m32L,m24L
	call	mul8x24
	movf	m32UU,W
	call	LCD_display_digit

	movlw	0x0A
	movwf	m8
	movff	m32U,m24U
	movff	m32H,m24H
	movff	m32L,m24L
	call	mul8x24
	movf	m32UU,W
	call	LCD_display_digit

	movlw	0x0A
	movwf	m8
	movff	m32U,m24U
	movff	m32H,m24H
	movff	m32L,m24L
	call	mul8x24
	movf	m32UU,W
	call	LCD_display_digit

	return

LCD_display_digit
  ; To go from int 1 to char "1" (etc) we need to add a 0x30 offset
	addlw	0x30
	call    LCD_Send_Byte_D
	return
    end

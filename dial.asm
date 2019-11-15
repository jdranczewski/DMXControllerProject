	#include p18f87k22.inc

; Globals section
global	dial_setup, dial_flag
; Externals section	
extern	m16L, m16H, LCD_hextodec, LCD_goto_pos
extern	deci_counter
	
; Reserving space in RAM
dialwhere   udata_acs
dial_flag   res 1
	
; Interrupt
int_lo	code	0x0018
	btfss	PIR1,ADIF	; check that this is ADC interrupt
	retfie	FAST		; if not then return
	bcf	PIR1, ADIF	; Clear interrupt flag
	movff	ADRESH, INDF1
	; Update the display
	movlw	0x45
	call	LCD_goto_pos
	movlw	0
	movwf	m16H
	movff	INDF1, m16L
	call	LCD_hextodec
	; Move cursor back to position determined by decimal input library
	movlw	0x4E
	clrc
	subfwb	deci_counter, W
	call	LCD_goto_pos
	retfie	FAST		; Fast return from interrupt
	
; Put code somewhere in Program Memory
dial	code

dial_setup
    bcf	    dial_flag, 0    ; Clear the 'enable dial' flag
	
    bsf	    TRISA,RA0	    ; use pin A0(==AN0) for input
    bsf	    ANCON0,ANSEL0   ; set A0 to analog
    movlw   0x01	    ; select AN0 for measurement
    movwf   ADCON0	    ; and turn ADC on
    movlw   0x30	    ; Select 4.096V positive reference
    movwf   ADCON1	    ; 0V for -ve reference and -ve input
    movlw   0x76	    ; Left justified output
    movwf   ADCON2	    ; Fosc/64 clock and acquisition times
    
    ; Interrupt
    bsf	    RCON, IPEN	    ; enables using interrupt priority
    bsf	    INTCON, GIEL    ; Enable all low-priority interrupts
    bsf	    PIE1, ADIE	    ; enable ADC interrupt
    bcf	    IPR1, ADIP	    ; set priority to low
    
    return
  
end
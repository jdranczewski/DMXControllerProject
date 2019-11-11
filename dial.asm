	#include p18f87k22.inc

; Globals section
global	dial_setup, dial_read
	
; Interrupt
int_lo	code	0x0018
	;btfss	PIR1,ADIF	; check that this is ADC interrupt
	;retfie	FAST		; if not then return
	movff	ADRESH, INDF1
	bcf	PIR1,ADIF	; clear interrupt flag
	bsf	ADCON0,GO	; Start conversion again
	retfie	FAST		; fast return from interrupt
	
; Put code somewhere in Program Memory
dial	code

dial_setup
    bsf	    TRISA,RA0	    ; use pin A0(==AN0) for input
    bsf	    ANCON0,ANSEL0   ; set A0 to analog
    movlw   0x01	    ; select AN0 for measurement
    movwf   ADCON0	    ; and turn ADC on
    movlw   0x30	    ; Select 4.096V positive reference
    movwf   ADCON1	    ; 0V for -ve reference and -ve input
    movlw   0x76	    ; Left justified output
    movwf   ADCON2	    ; Fosc/64 clock and acquisition times
    
    bsf	    RCON,IPEN	    ; enables using interrupt priority
    bcf	    PIR1,ADIF	    ; clear ADC interrupt flag
    bsf	    PIE1,ADIE	    ; enable ADC interrupt
    bsf	    INTCON,GIEL	    ; Enable all interrupts
    bcf	    IPR1,ADIP	    ; set priority to low
    bsf	    ADCON0,GO	    ; Start conversion
    return

dial_read
    bsf	    ADCON0,GO	    ; Start conversion
dial_loop
    btfsc   ADCON0,GO	    ; check to see if finished
    bra	    dial_loop
    return
  
end
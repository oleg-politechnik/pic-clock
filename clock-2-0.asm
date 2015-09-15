;***************************************************************************;
;						Digital clock listing, v 2.0						;
;						Author: Oleg TSaregorodtsev							;
;***************************************************************************;
;	MCU Ports connecting:													;
;***************************************************************************;
;	PORTA,0		2nd  pin	hour decads common								;
;	PORTA,1		3rd  pin	hour units common								;
;	PORTA,2		4th  pin	minute decads common							;
;	PORTA,3		5th  pin	minute units common								;
;	PORTA,4		6th  pin	low second point								;
;	PORTA,5		7th  pin	high second point								;
;	PORTC,0		11th pin	non connected									;
;	PORTC,1		12th pin	non connected									;
;	PORTC,2		13th pin	non connected									;
;	PORTC,3		14th pin	minute setting button, active low				;
;	PORTC,4		15th pin	non connected									;
;	PORTC,5		16th pin	non connected									;
;	PORTC,6		17th pin	non connected									;
;	PORTC,7		18th pin	non connected									;
;	PORTB,0		21th pin	hour setting button, active low					;
;	PORTB,1		22rd pin	c segments										;
;	PORTB,2		23th pin	d segments										;
;	PORTB,3		24th pin	a segments										;
;	PORTB,4		25th pin	b segments										;
;	PORTB,5		26th pin	f segments										;
;	PORTB,6		27th pin	e segments										;
;	PORTB,7		28th pin	g segments										;
;***************************************************************************;

		list p=pic16f873

	include	<pic16f873.inc>

__config _CP_ALL &_DEBUG_OFF &_CPD_OFF &_LVP_OFF &_BODEN_ON &_PWRTE_ON &_WDT_OFF &_HS_OSC

cblock 21h
 HOUR10
 HOUR
 MIN10
 MIN
 SEC10
 SEC
 FLAGS
 DEBOUNCE
 MODE
 OLD_MODE
; list of modes:
; MODE=xx000000 - normal,						<HH_MM>
; MODE=xx000010 - edit hour decads counter,		<_H:MM>
; MODE=xx000100 - edit hour units counter,		<H_:MM>
; MODE=xx001000 - edit minute decads counter,	<HH:_M>
; MODE=xx010000 - edit minute units counter,	<HH:M_>
; MODE=xx100000 - show seconds,					<MM:SS>
; 												*note: '_' means blinking
 COUNTER
 BLINKING_DIV
 POINTER
 AKKU
endc

constant	_KEY_DEBOUNCE = D'10'; &*RTC
constant	_ACCURACY = 0x3E

#define		SHIFT	STATUS,RP0	; bank select bit
#define		M_F		FLAGS,0		; mode key flag
#define		S_F		FLAGS,1		; set key flag
#define		CHANGE	FLAGS,2		; counters changing flag
#define		PT_F	FLAGS,3		;
#define		PT_L	PORTA,4		; low second point
#define		PT_H	PORTA,5		; high second point
#define		M_BTN	PORTB,0		; mode button press bit
#define		S_BTN	PORTC,3		; set button press bit

	org 0x000

		BSF		SHIFT			; bank 1
		MOVLW	B'11000000'
		MOVWF	OPTION_REG
		MOVLW	B'00000000'		
		MOVWF	TRISA
		MOVLW	B'00000001'
		MOVWF	TRISB
		MOVLW	B'00001000'
		MOVWF	TRISC
		CLRF	PIE1
		CLRF	PIE2
		MOVLW	D'7'
		MOVWF	ADCON1
		BCF		SHIFT			; bank 0
		CLRF	STATUS
		CLRF	PORTA
		CLRF	PORTB
		CLRF	PORTC
		CLRF	INTCON
		CLRF	PIR1
		CLRF	PIR2
		MOVLW	B'00000001'
		MOVWF	T1CON
		CLRF	CCP1CON
		CLRF	CCP2CON
		CLRF	ADCON0
		CLRF	TMR1H
		CLRF	TMR1L
		;
		CLRF	HOUR10
		CLRF	HOUR
		CLRF	MIN10
		CLRF	MIN
		CLRF	SEC10
		CLRF	SEC
		CLRF	FLAGS
		CLRF	DEBOUNCE
		CLRF	MODE
		MOVLW	B'00000001'
		MOVWF	OLD_MODE
		CLRF	COUNTER
		CLRF	BLINKING_DIV
		CLRF	POINTER
		;
		;======================== MAIN PROGRAM LOOP ========================
		;
LOOP	MOVLW	0xF6			;RTC=2,5msec
		ADDWF	TMR1H,F
		MOVLW	_ACCURACY
		ADDWF	TMR1L,F
		MOVLW	B'00110000'		;mask of digit commons
		ANDWF	PORTA,F
		CALL	POINT			;set common
		CALL	DECODE			
		MOVWF	PORTB			;set symbol
		;
		INCF	POINTER,F
		MOVLW	D'4'
		XORWF	POINTER,W
		BTFSC	STATUS,Z
		CLRF	POINTER
		;
		INCF	COUNTER,F
		MOVLW	D'200'
		XORWF	COUNTER,W
		BTFSS	STATUS,Z
		GOTO	MODE_5_CHECK
		CLRF	COUNTER
		;
		BCF		PT_L
		BCF		PT_H
		BTFSS	PT_F
		GOTO	$+.4
		BCF		PT_F
		CALL	INCR
		GOTO	MODE_5_CHECK
		;
		BSF		PT_F
		BTFSC	MODE,5			; in MM:SS mode dots blinking are disabled
		GOTO	MODE_5_CHECK
		BSF		PT_L
		BSF		PT_H
		;
MODE_5_CHECK
		BTFSS	MODE,5
		GOTO	MODE_0_CHECK
		;
		MOVF	OLD_MODE,W
		XORWF	MODE,W
		BTFSC	STATUS,Z
		GOTO	BUTTONS
		;
		CLRF	BLINKING_DIV
		BSF		SHIFT			; bank 1
		CLRF	TRISA
		BCF		SHIFT			; bank 0
		;
		MOVF	MODE,W
		MOVWF	OLD_MODE
		GOTO	BUTTONS
		;
MODE_0_CHECK
		MOVF	MODE,F
		BTFSS	STATUS,Z
		GOTO	MODE_BLINKING
		;
		MOVF	OLD_MODE,W
		XORWF	MODE,W
		BTFSC	STATUS,Z
		GOTO	BUTTONS
		;
		CLRF	BLINKING_DIV
		MOVF	HOUR10,F		;check to useless null
		BTFSS	STATUS,Z
		GOTO	$+.6
		BSF		SHIFT			; bank 1
		MOVLW	B'00000001'
		MOVWF	TRISA
		BCF		SHIFT			; bank 0
		GOTO	$+.4
		BSF		SHIFT			; bank 1
		CLRF	TRISA
		BCF		SHIFT			; bank 0
		;
		MOVF	MODE,W
		MOVWF	OLD_MODE
		;
		GOTO	BUTTONS
		;
MODE_BLINKING
		MOVF	OLD_MODE,W
		XORWF	MODE,W
		BTFSC	STATUS,Z
		GOTO	$+.6
		CLRF	BLINKING_DIV
		BSF		SHIFT			; bank 1
		CLRF	TRISA
		BCF		SHIFT			; bank 0		
		GOTO	$+.7
		;
		INCF	BLINKING_DIV,F
		MOVLW	D'50'
		XORWF	BLINKING_DIV,W
		BTFSS	STATUS,Z
		GOTO	BUTTONS
		CLRF	BLINKING_DIV
		;
		RRF		MODE,W
		MOVWF	AKKU
		BSF		SHIFT			; bank 1
		COMF	TRISA,W
		BCF		SHIFT			; bank 0
		ANDWF	AKKU,W
		;
		BSF		SHIFT			; bank 1
		MOVWF	TRISA
		BCF		SHIFT			; bank 0
		;
		MOVF	MODE,W
		MOVWF	OLD_MODE
BUTTONS
		;
		BTFSC	M_F
		GOTO	M_PRESS
		;
		BTFSC	S_F
		GOTO	S_PRESS
		;
NEXT_M	BTFSC	M_BTN				;mode button press check
		GOTO	$+.3
		BSF		M_F
		GOTO	M_PRESS
		;
NEXT_S	BTFSC	S_BTN				;setting button press check
		GOTO	$+.3
		BSF		S_F
		GOTO	S_PRESS
		;
MAIN	BTFSS	PIR1,TMR1IF
		GOTO	$-1
		BCF		PIR1,TMR1IF
		GOTO	LOOP
		;
		;====================== END MAIN PROGRAM LOOP ======================
		;
DECODE	ADDWF	PCL,1			;digit symbols table
		RETLW	B'10000000'		;0
		RETLW	B'11101100'		;1
		RETLW	B'00100010'		;2
		RETLW	B'01100000'		;3
		RETLW	B'01001100'		;4
		RETLW	B'01010000'		;5
		RETLW	B'00010000'		;6
		RETLW	B'11100100'		;7
		RETLW	B'00000000'		;8
		RETLW	B'01000000'		;9
		;
POINT	BTFSC	MODE,5
		GOTO	MM_SS
		;
		MOVF	POINTER,W
		ADDWF	PCL,1
		;
		goto	$+.4
		goto	$+.6
		goto	$+.8
		goto	$+.10
		;
		BSF		PORTA,0
		MOVF	HOUR10,0
		RETURN
		;
		BSF		PORTA,1
		MOVF	HOUR,0
		RETURN
		;
		BSF		PORTA,2
		MOVF	MIN10,0
		RETURN
		;
		BSF		PORTA,3
		MOVF	MIN,0
		RETURN
		;
MM_SS	BCF		PT_L
		BCF		PT_H
		MOVF	POINTER,W
		ADDWF	PCL,1
		;
		goto	$+.4
		goto	$+.6
		goto	$+.8
		goto	$+.10
		;
		BSF		PORTA,0
		MOVF	MIN10,0
		RETURN
		;
		BSF		PORTA,1
		MOVF	MIN,0
		RETURN
		;
		BSF		PORTA,2
		MOVF	SEC10,0
		RETURN
		;
		BSF		PORTA,3
		MOVF	SEC,0
		RETURN
		;
M_PRESS	MOVLW	_KEY_DEBOUNCE
		SUBWF	DEBOUNCE,W
		BTFSC	STATUS,C		;
		GOTO	$+.3
		;
		INCF	DEBOUNCE,F
		GOTO	MAIN
		;
		BTFSS	M_BTN
		GOTO	$+.4
		;
		BCF		M_F
		CLRF	DEBOUNCE
		GOTO	NEXT_S
		;
		BTFSS	STATUS,Z
		GOTO	$+.3
		;
		CALL	M_EVENT
		INCF	DEBOUNCE,F
		GOTO	MAIN
		;
M_EVENT	MOVF	MODE,F
		BTFSS	STATUS,Z
		GOTO	$+.3
		BSF		MODE,1
		RETURN
		;
		MOVLW	B'00010000'
		SUBWF	MODE,W
		BTFSC	STATUS,C		;
		GOTO	$+.3
		RLF		MODE,F
		RETURN
		;
		BTFSC	MODE,5
		GOTO	$+.3
		CLRF	MODE
		RETURN
		;
		MOVLW	D'3'
		SUBWF	SEC10,W
		BTFSC	STATUS,C		;@@
		CALL	INC_M
		CLRF	SEC10
		CLRF	SEC
		CLRF	COUNTER
		RETURN
		;
S_PRESS	MOVLW	_KEY_DEBOUNCE
		SUBWF	DEBOUNCE,W
		BTFSC	STATUS,C		;
		GOTO	$+.3
		;
		INCF	DEBOUNCE,F
		GOTO	MAIN
		;
		BTFSS	S_BTN
		GOTO	$+.4
		;
		BCF		S_F
		CLRF	DEBOUNCE
		GOTO	NEXT_S
		;
		BTFSS	STATUS,Z
		GOTO	$+.3
		;
		CALL	S_EVENT
		INCF	DEBOUNCE,F
		GOTO	MAIN
		;
S_EVENT	MOVF	MODE,F
		BTFSS	STATUS,Z
		GOTO	$+.3
		BSF		MODE,5
		RETURN
		;
		BTFSS	MODE,1
		GOTO	$+.5
		;
		BSF		CHANGE
		CALL	INC_H10
		BCF		CHANGE
		RETURN
		;
		BTFSS	MODE,2
		GOTO	$+.5
		;
		BSF		CHANGE
		CALL	INC_H
		BCF		CHANGE
		RETURN
		;
		BTFSS	MODE,3
		GOTO	$+.5
		;
		BSF		CHANGE
		CALL	INC_M10
		BCF		CHANGE
		RETURN
		;
		BTFSS	MODE,4
		GOTO	$+.5
		;
		BSF		CHANGE
		CALL	INC_M
		BCF		CHANGE
		RETURN
		;
		CLRF	MODE
		RETURN
		;
INCR	MOVLW	D'9'			;increment second units counter
		SUBWF	SEC,W
		BTFSC	STATUS,C
		GOTO	$+.3
		INCF	SEC,F
		RETURN
		CLRF	SEC
		;
		MOVLW	D'5'			;increment second decads counter
		SUBWF	SEC10,W
		BTFSC	STATUS,C
		GOTO	$+.3
		INCF	SEC10,F
		RETURN
		CLRF	SEC10
		;
INC_M	MOVLW	D'9'			;increment minute units counter
		SUBWF	MIN,W
		BTFSC	STATUS,C
		GOTO	$+.3
		INCF	MIN,F
		RETURN
		CLRF	MIN
		;
		BTFSS	MODE,4
		GOTO	$+.3
		BTFSC	CHANGE
		RETURN
		;
INC_M10	MOVLW	D'5'			;increment minute decads counter
		SUBWF	MIN10,W
		BTFSC	STATUS,C
		GOTO	$+.3
		INCF	MIN10,F
		RETURN
		CLRF	MIN10
		;
		BTFSS	MODE,3
		GOTO	$+.3
		BTFSC	CHANGE
		RETURN
		;
INC_H	MOVLW	D'2'			;if HOUR10=2, max HOUR=3
		SUBWF	HOUR10,W
		BTFSS	STATUS,C
		GOTO	$+.3
		MOVLW	D'3'
		GOTO	$+.2
		;
		MOVLW	D'9'			;increment hour units counter
		SUBWF	HOUR,W
		BTFSC	STATUS,C
		GOTO	$+.3
		INCF	HOUR,F
		RETURN
		CLRF	HOUR
		;
		BTFSS	MODE,2
		GOTO	$+.3
		BTFSC	CHANGE
		RETURN
		;
INC_H10	MOVLW	D'2'			;increment hour decads counter
		SUBWF	HOUR10,W
		BTFSC	STATUS,C
		GOTO	$+.6
		INCF	HOUR10,F
		BSF		SHIFT			; bank 1
		BCF		TRISA,0
		BCF		SHIFT			; bank 0
		RETURN
		;
		CLRF	HOUR10
		BSF		SHIFT			; bank 1
		BSF		TRISA,0
		BCF		SHIFT			; bank 0
		RETURN
		;
	END

;***************************************************************************;
;						Digital clock listing, v 1.1						;
;						Author: Oleg Tsaregorodtsev							;
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

cblock 20h
 HOUR10
 HOUR
 MIN10
 MIN
 SEC10
 SEC
 FLAGS
 MODE_KEY_DEBOUNCE
 MODE_KEY_DELAY
 MODE_KEY_SPEED
 SET_KEY_DEBOUNCE
 SET_KEY_DELAY
 SET_KEY_SPEED
 MODE
 COUNTER
 POINTER
endc

constant	_KEY_DEBOUNCE = D'4';*RTC
constant	_KEY_DELAY = D'100'	;*RTC
constant	_KEY_SPEED = D'50'	;*RTC

#define		SHIFT	STATUS,RP0	;bank select bit
#define		DIVx2	FLAGS,1		;division by :2 flag bit
#define		PT_L	PORTA,4		;low second point
#define		PT_H	PORTA,5		;high second point
#define		M_BTN	PORTB,0		;mode button press bit
#define		S_BTN	PORTC,3		;set button press bit

	org 0x000

		BSF		SHIFT			;BANK 1
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
		MOVLW	0x07
		MOVWF	ADCON1
		BCF		SHIFT			;BANK 0
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
		CLRF	HOUR10
		CLRF	HOUR
		CLRF	MIN10
		CLRF	MIN
		CLRF	SEC10
		CLRF	SEC
		CLRF	FLAGS
		CLRF	MODE_KEY_DEBOUNCE
		CLRF	MODE_KEY_DELAY
		CLRF	MODE_KEY_SPEED
		CLRF	SET_KEY_DEBOUNCE
		CLRF	SET_KEY_DELAY
		CLRF	SET_KEY_SPEED
		CLRF	MODE
		CLRF	COUNTER
		CLRF	POINTER
		;
		;======================== MAIN PROGRAM LOOP ========================
		;
LOOP	MOVLW	0xF6			;RTC=2,5msec
		ADDWF	TMR1H,F
		MOVLW	0x3B
		ADDWF	TMR1L,F
		MOVLW	B'00110000'		;mask of digit commons
		ANDWF	PORTA,F
		CALL	POINT			;set common
		CALL	DECODE			
		MOVWF	PORTB			;set symbol
		;
		INCF	POINTER,F
		MOVF	POINTER,W
		XORLW	4
		BTFSC	STATUS,Z
		CLRF	POINTER
		;
		MOVLW	D'200'
		XORWF	COUNTER,W
		BTFSC	STATUS,Z
		GOTO	$+3
		INCF	COUNTER,F
		GOTO	BUTTONS
		CLRF	COUNTER
		;
		BTFSS	PT_L
		GOTO	$+5
		BCF		PT_L
		BCF		PT_H
		;
		CALL	INCR
		;
		GOTO	$+3
		BSF		PT_L
		BSF		PT_H
		MOVF	MODE,F
		BTFSS	STATUS,Z
		GOTO	MODE_1
		GOTO	BUTTONS
		;
MODE_1	MOVLW	1
		XORWF	MODE,W
		BTFSS	STATUS,Z
		GOTO	MODE_2_3
		;
		BTFSS	S_BTN
		GOTO	$+5
		BSF		SHIFT
		BTFSS	TRISA,1
		GOTO	$+5
		BSF		SHIFT
		BCF		TRISA,0
		BCF		TRISA,1
		BCF		SHIFT
		GOTO	BUTTONS
		BSF		TRISA,0
		BSF		TRISA,1
		BCF		SHIFT
		GOTO	BUTTONS
		;
MODE_2_3
;		MOVLW	4
;		SUBWF	MODE,W
;		BTFSS	STATUS,C
		GOTO	BUTTONS
		;
		BTFSS	S_BTN
		GOTO	$+5
		BSF		SHIFT
		BTFSS	TRISA,3
		GOTO	$+5
		BSF		SHIFT
		BCF		TRISA,2
		BCF		TRISA,3
		BCF		SHIFT
		GOTO	BUTTONS
		BSF		TRISA,2
		BSF		TRISA,3
		BCF		SHIFT
		GOTO	BUTTONS
		;
BUTTONS	;BTFSS	S_BTN				;setting button press check
		;GOTO	S_PRESS
		;CLRF	SET_KEY_DEBOUNCE
		;CLRF	SET_KEY_DELAY
		;CLRF	SET_KEY_SPEED
		;
		BTFSS	M_BTN				;mode button press check
		GOTO	M_PRESS
		CLRF	MODE_KEY_DEBOUNCE
		CLRF	MODE_KEY_DELAY
		CLRF	MODE_KEY_SPEED
		;
MAIN	BTFSS	PIR1,TMR1IF
		GOTO	$-1
		BCF		PIR1,TMR1IF
		GOTO	LOOP
		;
		;====================== END MAIN PROGRAM LOOP ======================
		;
POINT	MOVLW	2
		SUBWF	MODE,W
		BTFSC	STATUS,C
		GOTO	MM_SS
		;
		MOVF	HOUR10,F		;check to useless null
		BTFSS	STATUS,Z		;active on HH:MM set
		GOTO	$+5
		BSF		SHIFT			;BANK 1
		BSF		TRISA,0
		BCF		SHIFT			;BANK 0
		GOTO	$+4
		BSF		SHIFT			;BANK 1
		BCF		TRISA,0
		BCF		SHIFT			;BANK 0
		;
		MOVF	POINTER,W
		ADDWF	PCL,1
		;
		goto	$+0x4
		goto	$+0x6
		goto	$+0x8
		goto	$+0xA
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
MM_SS	BSF		SHIFT
		BCF		TRISA,0
		BCF		TRISA,1
		BCF		TRISA,2
		BCF		TRISA,3
		BCF		SHIFT
		;
		MOVF	POINTER,W
		ADDWF	PCL,1
		;
		goto	$+0x4
		goto	$+0x6
		goto	$+0x8
		goto	$+0xA
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
M_PRESS	MOVLW	_KEY_DEBOUNCE
		SUBWF	MODE_KEY_DEBOUNCE,W
		BTFSC	STATUS,C
		GOTO	$+3
		INCF	MODE_KEY_DEBOUNCE,F
		GOTO	MAIN
		BTFSS	STATUS,Z
		GOTO	$+4
		CALL	M_EVENT
		INCF	MODE_KEY_DEBOUNCE,F
		GOTO	MAIN
		;
;		MOVLW	_KEY_DELAY
;		SUBWF	MODE_KEY_DELAY,W
;		BTFSS	STATUS,C
;		GOTO	$+5
;		INCF	MODE_KEY_DELAY,F
;		BTFSC	STATUS,Z				;@@@@@@@@@@@@@@@@@
;		CALL	M_EVENT
;		GOTO	MAIN
;		;
;		MOVLW	_KEY_SPEED
;		SUBWF	MODE_KEY_SPEED,W
;		BTFSS	STATUS,Z
;		GOTO	$+4
;		CALL	M_EVENT
;		CLRF	MODE_KEY_SPEED
;		GOTO	MAIN
;		INCF	MODE_KEY_SPEED,F
		GOTO	MAIN
		;
;S_PRESS	MOVLW	_KEY_DEBOUNCE
;		SUBWF	SET_KEY_DEBOUNCE,W
;		BTFSS	STATUS,C
;		GOTO	$+5
;		INCF	SET_KEY_DEBOUNCE,F
;		BTFSC	STATUS,Z				;@@@@@@@@@@@@@@@@@
;		CALL	S_EVENT
;		GOTO	MAIN
;		;
;		MOVLW	_KEY_DELAY
;		SUBWF	SET_KEY_DELAY,W
;		BTFSS	STATUS,C
;		GOTO	$+5
;		INCF	SET_KEY_DELAY,F
;		BTFSC	STATUS,Z				;@@@@@@@@@@@@@@@@@
;		CALL	S_EVENT
;		GOTO	MAIN
;		;
;		MOVLW	_KEY_SPEED
;		SUBWF	SET_KEY_SPEED,W
;		BTFSS	STATUS,Z
;		GOTO	$+4
;		CALL	S_EVENT
;		CLRF	SET_KEY_SPEED
;		GOTO	MAIN
;		INCF	SET_KEY_SPEED,F
;		GOTO	MAIN
		;
M_EVENT	MOVLW	4
		SUBWF	MODE,W
		BTFSC	STATUS,C
		GOTO	$+3
		INCF	MODE,F
		RETURN
		CLRF	MODE
		RETURN
		;
;S_EVENT	MOVF	MODE,F
;		BTFSC	STATUS,Z
;		INCF	MODE,F
;		;
;		MOVLW	1
;		XORWF	MODE,W
;		BTFSS	STATUS,Z
;		GOTO	$+3
;		CALL	INC_H
;		RETURN
;		;
;		MOVLW	2
;		XORWF	MODE,W
;		BTFSS	STATUS,Z
;		GOTO	$+3
;		CALL	INC_M
;		RETURN
;		;
;		MOVLW	3
;		XORWF	MODE,W
;		BTFSS	STATUS,Z
;		GOTO	$+D'8'
;		MOVLW	3			;30 sec
;		SUBWF	SEC10,W
;		BTFSC	STATUS,Z
;		CALL	INC_M
;		CLRF	SEC
;		CLRF	SEC10
;		RETURN
;		;
;		CLRF	MODE
;		RETURN
		;
INCR	MOVLW	0x09			;increment second units counter
		SUBWF	SEC,0
		BTFSC	STATUS,Z
		GOTO	$+3
		INCF	SEC,1
		RETURN
		CLRF	SEC
		;
		MOVLW	0x05			;increment second decads counter
		SUBWF	SEC10,0
		BTFSC	STATUS,Z
		GOTO	$+3
		INCF	SEC10,1
		RETURN
		CLRF	SEC10
		;
INC_M	MOVLW	0x09			;increment minute units counter
		SUBWF	MIN,0
		BTFSC	STATUS,Z
		GOTO	$+3
		INCF	MIN,1
		RETURN
		CLRF	MIN
		;
		MOVLW	0x05			;increment minute decads counter
		SUBWF	MIN10,0
		BTFSC	STATUS,Z
		GOTO	$+3
		INCF	MIN10,1
		RETURN
		CLRF	MIN10
		MOVLW	2
		XORWF	MODE,W
		BTFSC	STATUS,Z
		RETURN
		;
INC_H	MOVLW	0x02			;if HOUR10=2, max HOUR=3
		SUBWF	HOUR10,0
		BTFSS	STATUS,Z
		GOTO	$+3
		MOVLW	0x03
		GOTO	$+2
		;
		MOVLW	0x09			;increment hour units counter
		SUBWF	HOUR,0
		BTFSC	STATUS,Z
		GOTO	$+3
		INCF	HOUR,1
		RETURN
		CLRF	HOUR
		;
		MOVLW	0x02			;increment hour decads counter
		SUBWF	HOUR10,0
		BTFSC	STATUS,Z
		GOTO	$+3
		INCF	HOUR10,1
		RETURN
		CLRF	HOUR10
		RETURN
		;
	END

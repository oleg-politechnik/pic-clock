;	Digital clock listing, 1.0 Version

;	MCU Ports connecting:

;	MCLR		1st  pin	connect with Vdd througth 1,5 kOhm resister
;	PORTA,0		2nd  pin	hour decads common
;	PORTA,1		3rd  pin	hour units common
;	PORTA,2		4th  pin	minute decads common
;	PORTA,3		5th  pin	minute units common
;	PORTA,4		6th  pin	low second point
;	PORTA,5		7th  pin	high second point
;	PORTC,0		11th pin	non connected
;	PORTC,1		12th pin	non connected
;	PORTC,2		13th pin	non connected
;	PORTC,3		14th pin	minute setting button, active low
;	PORTC,4		15th pin	non connected
;	PORTC,5		16th pin	non connected
;	PORTC,6		17th pin	non connected
;	PORTC,7		18th pin	non connected
;	PORTB,0		21th pin	hour setting button, active low
;	PORTB,1		22rd pin	c segments
;	PORTB,2		23th pin	d segments
;	PORTB,3		24th pin	a segments
;	PORTB,4		25th pin	b segments
;	PORTB,5		26th pin	f segments
;	PORTB,6		27th pin	e segments
;	PORTB,7		28th pin	g segments

		list p=pic16f873
			
	Include	<p16f873.inc>		

__config _CP_ALL &_DEBUG_OFF &_CPD_OFF &_LVP_OFF &_BODEN_ON &_PWRTE_ON &_WDT_OFF &_HS_OSC 	

HOUR10		EQU		21h
HOUR		EQU		22h
MIN10		EQU		23h
MIN			EQU		24h
SEC10		EQU		25h
SEC			EQU		26h
FLAGS		EQU		27h
M_COUNT		EQU		28h
S_COUNT		EQU		29h
COUNTER		EQU		2Ah
POINTER		EQU		2Bh

CONSTANT	DEBOUNCE=0x05		;debounce value definition: delay=DEB*2,5msec

#define		SHIFT	STATUS,RP0	;bank select bit
#define		NULL	STATUS,Z	;arithmetic operation zero bit
#define		CARE	STATUS,C	;rotate operation bit
#define		OVER	FLAGS,0		;overflow of counter incrementation
#define		DIVx2	FLAGS,1		;division by :2 flag bit
#define		DIVx4	FLAGS,2		;division by :4 flag bit
#define		PT_L	PORTA,4		;low second point
#define		PT_H	PORTA,5		;high second point
#define		M_B		PORTB,0		;mode button press bit
#define		S_B		PORTC,3		;setting button press bit

	org 0x000
					
RESET	BSF		SHIFT			;BANK 1
		MOVLW	B'11000000'
		MOVWF	OPTION_REG
		MOVLW	B'00000000'		
		MOVWF	TRISA
		MOVLW	B'00000001'
		MOVWF	TRISB
		MOVLW	B'00001000'
		MOVWF	TRISC
		CLRF	PIE1
		CLRF	PIE1
		MOVLW	0x07
		MOVWF	ADCON1
		BCF		SHIFT			;BANK 0
		CLRF	STATUS
		CLRF	PORTA
		CLRF	PORTB
		CLRF	PORTC
		CLRF	INTCON
		CLRF	PIR1
		CLRF	PIR1
		MOVLW	B'00001001'
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
		CLRF	M_COUNT
		CLRF	S_COUNT
		CLRF	COUNTER
		CLRF	POINTER
		;
		;======================== MAIN PROGRAM LOOP ========================
		;
HS_LOOP	MOVLW	0x65			;COUNTER=200, comply to 1/4 second period
		MOVWF	COUNTER
		;
DISP	MOVLW	0xF6			;RTCC=2,5msec (CF2C) for 20MHz
		ADDWF	TMR1H,1
		MOVLW	0x3C
		ADDWF	TMR1L,1
		MOVLW	B'00110000'		;mask of digit commons (clear least half-byte)
		ANDWF	PORTA,1
		CALL	POINT			;set common
		CALL	DECODE			
		MOVWF	PORTB			;set symbol
		;
		INCF	POINTER,1		;next point
		MOVF	POINTER,0
		SUBLW	0x04
		BTFSC	NULL			;point=4 ?
		CLRF	POINTER			;yes, clear
		;
CH_TM	BTFSC	PIR1,TMR1IF		;timer1=2,5msec ?
		GOTO	CHECK			;yes, clear flag
		;
		BTFSS	S_B				;setting button press check
		CALL	S_PR
		CLRF	S_COUNT
		;
		BTFSS	M_B				;mode button press heck
		CALL	M_PR
		CLRF	M_COUNT
		;
		GOTO	CH_TM			;no, loop
		;
CHECK	BCF		PIR1,TMR1IF
		DECFSZ	COUNTER,1		;1/4 second period complete ?
		GOTO	DISP			;no, loop
		CALL	BLINK			;yes, blinking dots & commons, division freq by :4
		CALL	INCR			;incrementation
		GOTO	HS_LOOP
		;
		;====================== END MAIN PROGRAM LOOP ======================
		;
AD_CH	BTFSC	PIR1,TMR1IF		;adding 2,5msec loop
		GOTO	CHECK			;yes, clear flag
		GOTO	AD_CH			;no, loop
		;
POINT	MOVF	HOUR10,1		;check to useless null
		BTFSS	NULL			;active on HH:MM set
		GOTO	$+5
		BSF		SHIFT			;BANK 1
		BSF		TRISA,0
		BCF		SHIFT			;BANK 0
		GOTO	$+4
		BSF		SHIFT			;BANK 1
		BCF		TRISA,0
		BCF		SHIFT			;BANK 0
		;
		MOVF	POINTER,0		
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
BLINK	BTFSC	DIVx2			;division freq by :2
		GOTO	$+3
		BSF		DIVx2
		GOTO	HS_LOOP
		BCF		DIVx2
		;
		BTFSC	DIVx4			;division freq by :4
		GOTO	$+5
		BSF		DIVx4
		BCF		PT_L
		BCF		PT_H
		RETURN
		BCF		DIVx4
		BSF		PT_L			;blink dots
		BSF		PT_H
		GOTO	HS_LOOP
		;
INCR	MOVLW	0x09			;increment second units counter
		SUBWF	SEC,0
		BTFSC	NULL
		GOTO	$+3
		INCF	SEC,1
		RETURN
		CLRF	SEC
		;
		MOVLW	0x05			;increment second decads counter
		SUBWF	SEC10,0
		BTFSC	NULL
		GOTO	$+3
		INCF	SEC10,1
		RETURN
		CLRF	SEC10
		;
M		MOVLW	0x09			;increment minute units counter
		SUBWF	MIN,0
		BTFSC	NULL
		GOTO	$+3
		INCF	MIN,1
		RETURN
		CLRF	MIN
		;
M10		MOVLW	0x05			;increment minute decads counter
		SUBWF	MIN10,0
		BTFSC	NULL
		GOTO	$+3
		INCF	MIN10,1
		RETURN
		CLRF	MIN10
		BTFSC	OVER
		RETURN
		;
H		MOVLW	0x02			;if HOUR10=2, max HOUR=3
		SUBWF	HOUR10,0
		BTFSS	NULL
		GOTO	$+3
		MOVLW	0x03
		GOTO	$+2
		;
		MOVLW	0x09			;increment hour units counter
		SUBWF	HOUR,0
		BTFSC	NULL
		GOTO	$+3
		INCF	HOUR,1
		RETURN
		CLRF	HOUR
		;
H10		MOVLW	0x02			;increment hour decads counter
		SUBWF	HOUR10,0
		BTFSC	NULL
		GOTO	$+3
		INCF	HOUR10,1
		RETURN
		CLRF	HOUR10
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
S_PR	MOVLW	DEBOUNCE		;constant equ maximum S_COUNT rating
		SUBWF	S_COUNT,0
		BTFSC	NULL			;skip, if S_COUNT not equ maximum
		GOTO	AD_CH			;if S_COUNT equ maximum rating, debounce have already had called, do nothing
		;
		INCF	S_COUNT,1
		MOVLW	DEBOUNCE		;check for maximum S_COUNT rating
		SUBWF	S_COUNT,0
		BTFSS	NULL			;skip, if S_COUNT equ maximum
		GOTO	AD_CH
		;
		BSF		OVER
		CALL	M
		BCF		OVER
		GOTO	AD_CH
		;
M_PR	MOVLW	DEBOUNCE		;constant equ maximum M_COUNT rating
		SUBWF	M_COUNT,0
		BTFSC	NULL			;skip, if M_COUNT not equ maximum
		GOTO	AD_CH			;if M_COUNT equ maximum rating, debounce have already had called, do nothing
		;
		INCF	M_COUNT,1
		MOVLW	DEBOUNCE		;check for maximum M_COUNT rating
		SUBWF	M_COUNT,0
		BTFSS	NULL			;skip, if M_COUNT equ maximum
		GOTO	AD_CH
		;
		BSF		OVER
		CALL	H
		BCF		OVER
		GOTO	AD_CH
		;
	END

.include "m8def.inc"
.include "macros.inc"
 
; Register definition
.def Null	= r15								; := 0
.def temp1  = r16                             	
.def temp2	= r17
.def temp3	= r18
.def char 	= r19                              	; recieved char    
.def Flag   = r20
 
.def SubCount = r21
.def Sekunden = r22
.def Minuten  = r23
.def Stunden  = r24 
 
; Constants
.equ F_CPU 	= 16000000                          ; System clock (Hz)
.equ BAUD  	= 9600                              ; Baudrate

.equ cesc	= 0x1B								; ESCAPE character
.equ ccr	= 0x0D								; Carriage return character 
.equ clf	= 0x0A								; Line feed character
.equ cnull	= 0x00

; Baudrate calculations
.equ UBRR_VAL   = ((F_CPU+BAUD*8)/(BAUD*16)-1)  ; round
.equ BAUD_REAL  = (F_CPU/(16*(UBRR_VAL+1)))     ; real Baudrate
.equ BAUD_ERROR = ((BAUD_REAL*1000)/BAUD-1000)  ; error (Promille)
 
.equ CMDBUFFSIZE 	= 10
.equ COUNTERSIZE	= 2

; Data
.dseg
CmdBuffer: 			.byte CMDBUFFSIZE				; Usart receiver buffer
TimerCallbackFlags:	.byte 1
Counter:			.byte COUNTERSIZE


.if ((BAUD_ERROR>10) || (BAUD_ERROR<-10))       ; max. +/-10 Promille error
  .error "Systematischer Fehler der Baudrate grösser 1 Prozent und damit zu hoch!"
.endif



.cseg

.org 0x0000
        rjmp    Reset             ; Reset Handler
.org OC1Aaddr
        rjmp    timer1_compare   ; Timer Compare Handler
.org OVF0addr
        rjmp    timer0_overflow   ; Timer overflow
.org URXCaddr                                   ; Usart Interruptvector
        rjmp URX_INT

 
;
; Initialization
;
Reset:
	clr		Null
	clr		temp1
	clr		temp2
	clr		temp3
	clr		char
    ldi     temp1, HIGH(RAMEND)
    out     SPH, temp1
    ldi     temp1, LOW(RAMEND)  ; Stackpointer initialisieren
    out     SPL, temp1


	ldi		r16,low(SRAM_Size)		; SRAM löschen (definieren)
	clr		r17
	ldi		zl,low(SRAM_Start)
	ldi		zh,high(SRAM_Start)


L014:
	st	z+,r17
	dec	r16
	brne	L014

		;*** PORTS ***
								; PORTD initialisieren
	ldi     temp1, 0b11111011
    out     DDRD, temp1
	ldi     temp1, 0x00
    out     PORTD, temp1

    ldi     r16,0x00
    out     PORTD,r16
 	
	;*** USART ***				; Baudrate einstellen

    ldi     temp1, HIGH(UBRR_VAL)
    out     UBRRH, temp1
    ldi     temp1, LOW(UBRR_VAL)
    out     UBRRL, temp1 
    							; Frame-Format: 8 Bit

    ldi     temp1, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
    out     UCSRC, temp1

    sbi     UCSRB,TXEN          ; TX aktivieren
	sbi     UCSRB, RXCIE                ; enable Usart interrupt
    sbi     UCSRB, RXEN                 ; enable RX
 
 	;*** Timer ***	 
                                ; Vergleichswert 
    ldi     temp1, high( 40000 - 1 )
    out     OCR1AH, temp1
    ldi     temp1, low( 40000 - 1 )
    out     OCR1AL, temp1
                                ; CTC Modus einschalten
                                ; Vorteiler auf 1
    ldi     temp1, ( 1 << WGM12 ) | ( 1 << CS11 )
    out     TCCR1B, temp1
	
	ldi		temp1, (1 << CS02) | (1 << CS00)
	out		TCCR0, temp1

    ldi     temp1, (1 << OCIE1A) | (1 << TOIE0)  ; OCIE1A: Interrupt bei Timer Compare
    out     TIMSK, temp1


    clr     Minuten             ; Die Uhr auf 0 setzen
    clr     Sekunden
    clr     Stunden
    clr     SubCount
    clr     Flag                ; Flag löschen



; Command Buffer initialization
	
	Vector	x, CmdBuffer				; set X Pointer to CmdBuffer
	clr		char						; clear char
	
	; clear output and send startup text
	
	ZTab	TxtStart, Null				; Startup text
	rcall	UsartTxtOut	

    sei

;*********************************************************************************************

;
; Main programm
;
Main:
	cpi		char, ccr					; check if carriage return (13) received?
	brne	Main
;rcall TestSetCmd
	rcall	Cmd							; check received command
	clr		char
	rjmp	Main
 


;***********************************************************************************






SerOutTime:
	push	temp1
	push	temp2
	push	char

	mov		temp1,Stunden
	rcall 	Bin2Ascii8
	mov		char, temp2
	rcall	UsartOut
	mov		char, temp1
	rcall	UsartOut

	ldi		char, ':'
	rcall	UsartOut

	mov		temp1,Minuten
	rcall 	Bin2Ascii8
	mov		char, temp2
	rcall	UsartOut
	mov		char, temp1
	rcall	UsartOut
	
	ldi		char, ':'
	rcall	UsartOut

	mov		temp1,Sekunden
	rcall 	Bin2Ascii8
	mov		char, temp2
	rcall	UsartOut
	mov		char, temp1
	rcall	UsartOut


	ldi     char, 10
    rcall   UsartOut
    ldi     char, 13
    rcall   UsartOut

	pop		char
	pop		temp2
	pop		temp1
	ret



;
; String table
;

Txt1:
	.db "excute Command on", clf, ccr, cnull

Txt2:
	.db "excute Command off", clf, ccr, cnull

TxtStart:
	.db  cesc,'[','H',cesc,'[','J' ; ANSI Clear screen
	.db "*** AVR Alarm Clock Test ***", clf, ccr, cnull


TestSetCmd:
	Vector	z, CmdBuffer
	ldi		temp1,'c'
	st		z+, temp1
	ldi		temp1,'l'
	st		z+, temp1
	ldi		temp1,'r'
	st		z+, temp1
	;ldi		temp1,'e'
	;st		z+, temp1
	ldi		temp1,'\r'
	st		z+, temp1
	ret



;***************************************************************************
;* Include Subroutine
;***************************************************************************

.include "stdlib.asm"
.include "usart.asm"
.include "cmd.asm"
.include "timer0.asm"
.include "timer1.asm"

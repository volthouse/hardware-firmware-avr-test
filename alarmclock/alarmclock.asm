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
 
; Data
.dseg
CmdBuffer: .BYTE 10 							; Usart receiver buffer


.if ((BAUD_ERROR>10) || (BAUD_ERROR<-10))       ; max. +/-10 Promille error
  .error "Systematischer Fehler der Baudrate grösser 1 Prozent und damit zu hoch!"
.endif



.cseg

.org 0x0000
        rjmp    Reset             ; Reset Handler
.org OC1Aaddr
        rjmp    timer1_compare   ; Timer Compare Handler
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
 
 	;*** Timer 1 ***	 
                                ; Vergleichswert 
    ldi     temp1, high( 40000 - 1 )
    out     OCR1AH, temp1
    ldi     temp1, low( 40000 - 1 )
    out     OCR1AL, temp1
                                ; CTC Modus einschalten
                                ; Vorteiler auf 1
    ldi     temp1, ( 1 << WGM12 ) | ( 1 << CS11 )
    out     TCCR1B, temp1

    ldi     temp1, 1 << OCIE1A  ; OCIE1A: Interrupt bei Timer Compare
    out     TIMSK, temp1

    clr     Minuten             ; Die Uhr auf 0 setzen
    clr     Sekunden
    clr     Stunden
    clr     SubCount
    clr     Flag                ; Flag löschen

; Command Buffer initialization
	
	Vector	x, CmdBuffer				; set X Pointer to CmdBuffer
	clr		char						; clear char
    sei									; enable interrups
	
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

	rcall	Cmd							; check received command
	clr		char
	rjmp	Main

;loop:
		
;        cpi     flag,0
;        breq    loop                ; Flag im Interrupt gesetzt?
;        ldi     flag,0              ; Flag löschen
 
;		rcall	SerOutTime
;		rcall	LineFeed
;	    rcall   sync                        

;        rjmp    loop
 


;***********************************************************************************

timer1_compare:                     ; Timer 1 Output Compare Handler
 
        push    temp1               ; temp1 1 sichern
		push	temp2
        in      temp1,sreg          ; SREG sichern
 
        inc     SubCount            ; Wenn dies nicht der 100. Interrupt
        cpi     SubCount, 50       ; ist, dann passiert gar nichts
        brne    end_isr
 
		in		temp2, PORTD
		com		temp2
		out		PORTD, temp2

                                    ; Überlauf
        clr     SubCount            ; SubCount rücksetzen
        inc     Sekunden            ; plus 1 Sekunde
        cpi     Sekunden, 60        ; sind 60 Sekunden vergangen?
        brne    Ausgabe             ; wenn nicht kann die Ausgabe schon
                                    ; gemacht werden
 
                                    ; Überlauf
        clr     Sekunden            ; Sekunden wieder auf 0 und dafür
        inc     Minuten             ; plus 1 Minute
        cpi     Minuten, 60         ; sind 60 Minuten vergangen ?
        brne    Ausgabe             ; wenn nicht, -> Ausgabe
 
                                    ; Überlauf
        clr     Minuten             ; Minuten zurücksetzen und dafür
        inc     Stunden             ; plus 1 Stunde
        cpi     Stunden, 24         ; nach 24 Stunden, die Stundenanzeige
        brne    Ausgabe             ; wieder zurücksetzen
 
                                    ; Überlauf
        clr     Stunden             ; Stunden rücksetzen
 
Ausgabe:
        ldi     flag,1              ; Flag setzen, LCD updaten
 
end_isr:
 
        out     sreg,temp1          ; sreg wieder herstellen
		pop		temp2
        pop     temp1
        reti                        ; das wars. Interrupt ist fertig




SerOutTime:
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

LineFeed:
	ldi     char, 10
    rcall   UsartOut
    ldi     char, 13
    rcall   UsartOut
	ret

;
; Commands
;
Cmd1:
	ZTab 	Txt1, Null
	rcall	UsartTxtOut
	sbi		DDRD, 7
	ret

Cmd2:
	ZTab 	Txt2, Null
	rcall	UsartTxtOut
	cbi		DDRD, 7
	ret

Cmd3:
	ZTab 	TxtStart, Null
	rcall	UsartTxtOut
	ret

Cmd4:
	ldi		temp1, 42
	rcall	Bin2Ascii8
	mov		char, temp2
	rcall	UsartOut
	mov		char, temp1
	rcall	UsartOut
	ret

Cmd5:
	rcall	SerOutTime
	ret

;
; Command table
;

CmdTable:
	.db "set",ccr .dw Cmd1
	.db "del",ccr .dw Cmd2
	.db "clr",ccr .dw Cmd3
	.db "num",ccr .dw Cmd4
	.db "tim",ccr .dw Cmd5
	.db	cnull

;
; String table
;

Txt1:
	.db "excute Command set", clf, ccr, cnull

Txt2:
	.db "excute Command del", clf, ccr, cnull

TxtStart:
	.db  cesc,'[','H',cesc,'[','J' ; ANSI Clear screen
	.db "*** AVR Alarm Clock Test ***", clf, ccr, cnull



;***************************************************************************
;* Include Subroutine
;***************************************************************************

.include "stdlib.asm"
.include "usart.asm"
.include "cmd.asm"

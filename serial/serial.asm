.include "m8def.inc"
.include "macros.inc"

.def Null	= R15								; := 0
.def temp1  = r16                             	; Register für kleinere Arbeiten
.def temp2	= r17
.def temp3	= r18
.def char 	= r19                              	; in diesem Register wird das Zeichen an die
                                                ; Ausgabefunktion übergeben

.equ F_CPU 	= 16000000                          ; Systemtakt in Hz
.equ BAUD  	= 9600                              ; Baudrate

.equ cesc	= 0x1B								; ESCAPE character
.equ ccr	= 0x0D								; Carriage return character 
.equ clf	= 0x0A								; Line feed character
.equ cnull	= 0x00

; Berechnungen
.equ UBRR_VAL   = ((F_CPU+BAUD*8)/(BAUD*16)-1)  ; clever runden
.equ BAUD_REAL  = (F_CPU/(16*(UBRR_VAL+1)))     ; Reale Baudrate
.equ BAUD_ERROR = ((BAUD_REAL*1000)/BAUD-1000)  ; Fehler in Promille
 

.dseg
CmdBuffer: .BYTE 10 							; Usart Empfangspuffer


.if ((BAUD_ERROR>10) || (BAUD_ERROR<-10))       ; max. +/-10 Promille Fehler
  .error "Systematischer Fehler der Baudrate grösser 1 Prozent und damit zu hoch!"
.endif
 
.cseg

.org 0x0000
        rjmp Reset
 
.org URXCaddr                                   ; Interruptvektor für UART-Empfang
        rjmp URX_INT

;
; Initialisierung
;
Reset:
	clr		Null
	clr		temp1
	clr		temp2
	clr		temp3
	clr		char

    ; Stackpointer initialisieren
 
    ldi     temp1, HIGH(RAMEND)
    out     SPH, temp1
    ldi     temp1, LOW(RAMEND)
    out     SPL, temp1

    ; Baudrate einstellen
 
    ldi     temp1, HIGH(UBRR_VAL)
    out     UBRRH, temp1
    ldi     temp1, LOW(UBRR_VAL)
    out     UBRRL, temp1
 
    ; Frame-Format: 8 Bit
 
    ldi     temp1, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
    out     UCSRC, temp1
 
    sbi     UCSRB, TXEN                 ; TX aktivieren
	sbi     UCSRB, RXCIE                ; Interrupt bei Empfang
    sbi     UCSRB, RXEN                 ; RX (Empfang) aktivieren
    
	Vector	x, CmdBuffer				; Zeiger auf Command Buffer setzten
	clr		char						; Zeichen löschen
    sei									; Interrupts global aktivieren


	ZTab	TxtStart, Null					; Start Text ausgeben
	rcall	UsartTxtOut	

;
; Hauptprogramm
;
Main:
	cpi		char, ccr
	brne	Main

	rcall	Cmd
	clr		char
	rjmp	Main
  


;
; Befehle
;
Cmd1:
	ZTab 	Txt1, Null
	rcall	UsartTxtOut
	ret

Cmd2:
	ZTab 	Txt2, Null
	rcall	UsartTxtOut
	ret

Cmd3:
	ZTab 	TxtStart, Null
	rcall	UsartTxtOut
	ret

Cmd4:
	ldi		temp1, 42
	rcall	Bin2Asc8
	mov		char, temp2
	rcall	UsartOut
	mov		char, temp1
	rcall	UsartOut
	ret








;***************************************************************************
;*
;* Tabelle der Befehle
;*
;***************************************************************************

CmdTable:
	.db "set",ccr .dw Cmd1
	.db "del",ccr .dw Cmd2
	.db "clr",ccr .dw Cmd3
	.db "num",ccr .dw Cmd4
	.db	cnull

;
; Tabellen mit Texten
;
Txt1:
	.db "excute Command set", clf, ccr, cnull

Txt2:
	.db "excute Command del", clf, ccr, cnull

TxtStart:
	.db  cesc,'[','H',cesc,'[','J' ; ANSI Clear screen
	.db "*** AVR Serial Test ***", clf, ccr, cnull
/*	.db "* Available Commands: *", clf, ccr
	.db "* set                 *", clf, ccr
	.db "* del				   *", clf, ccr
	.db "* clr				   *", clf, ccr
	.db "* *********************", clf, ccr
	.db cnull
*/


;***************************************************************************
;* Include Subroutine
;***************************************************************************

.include "stdio.asm"
.include "usart.asm"
.include "cmd.asm"

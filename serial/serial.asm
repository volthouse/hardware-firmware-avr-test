.include "m8def.inc"
.include "macros.inc"

.def temp1  = r16                             	; Register für kleinere Arbeiten
.def temp2	= r17
.def char 	= r18                              	; in diesem Register wird das Zeichen an die
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
    
	vectorR	x, CmdBuffer				; Zeiger auf Command Buffer setzten
	clr		char						; Zeichen löschen
    sei									; Interrupts global aktivieren


	vector	z, TxtStart					; Start Text ausgeben
	rcall	TxtOut	

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
; Uart Rx Interrupt
;
URX_INT:
    push    temp1						; temp1 auf dem Stack sichern
	in      temp1, sreg					; SREG sichern
    push    temp1

    in      char, UDR                   ; empfangenes Byte lesen,
					                    ; dadurch wird auch der Interrupt gelöscht
    ; TODO: auf Puffer Ende Prüfen !!!!!!!
	st		x+, char					; Zeichen auf dem Empfangspuffer ablegen
	rcall	SerialOut					; Zeichen Echo
	
	cpi		char, ccr					; wurde Return empfangen?
	brne	URX_INT_Exit				; wenn nicht dann Interrupt verlassen
	
	mov		temp1, char					; Zeichen sichern
	ldi		char, clf					; Linefeed laden
	rcall	SerialOut					; und ausgeben
	mov		char, temp1					; Zeichen wiederherstellen

URX_INT_Exit:	  
	pop     temp1
    out     sreg, temp1					; SREG wiederherstellen
    pop     temp1						; temp1 wiederherstellen
    reti   

;
; Sendet null-terminierten Text vom Prg-Spreicher auf den Z zeigt
;
TxtOut:
	lpm		char, z+
	cpi		char, cnull
	breq	TxTOutExit
	rcall	SerialOut
	rjmp	Txtout
TxTOutExit:
	rcall   SerialSync
	ret

;
; Sendet das Zeichen > char < auf dem Uart
;
SerialOut:
    sbis    UCSRA,UDRE                  ; Warten bis UDR für das nächste
                                        ; Byte bereit ist
    rjmp    SerialOut
    out     UDR, char
    ret                                 ; zurück zum Hauptprogramm

;
; kleine Pause zum Synchronisieren des Empfängers, falls zwischenzeitlich
; das Kabel getrennt wurde
;                                 
SerialSync:
    ldi     r16,0
SerialSync_1:
    ldi     r17,0
SerialSync_loop:
    dec     r17
    brne    SerialSync_loop
    dec     r16
    brne    SerialSync_1  
    ret

;
; Befehle die über den Uart empfangen wurden bearbeiten
;
Cmd:
	vector	z, CmdTable
	vectorR	x, CmdBuffer
CmdCheckChar:	
	lpm		temp1, z+
	ld		temp2, x+
	cpi		temp1, cnull		
	breq	CmdExit
	cpi		temp1, ccr
	breq	CmdMatch
	cp		temp1, temp2
	brne	CmdNext
	rjmp	CmdCheckChar

CmdMatch:
	vectorR	x, CmdBuffer
	lpm     temp1,z+                    ; Low Byte laden und Pointer erhöhen
    lpm     zh,z                        ; zweites Byte laden
    mov     zl,temp1                    ; erstes Byte in Z-Pointer kopieren
    ijmp

CmdNext:
	vectorR	x, CmdBuffer
	adiw	zl, 5
	rjmp	CmdCheckChar

CmdExit:
	vectorR	x, CmdBuffer
	ret;

;
; Befehle
;
Cmd1:
	vector z, Txt1
	rcall	TxtOut
	ret

Cmd2:
	vector z, Txt2
	rcall	TxtOut
	ret

Cmd3:
	vector z, TxtStart
	rcall	TxtOut
	ret

;
; Tabelle der Befehle
;
CmdTable:
	.db "set",ccr .dw Cmd1
	.db "del",ccr .dw Cmd2
	.db "clr",ccr .dw Cmd3
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

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
	ZTab	CmdTable, Null
	Vector	x, CmdBuffer
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
	Vector	x, CmdBuffer
	lpm     temp1,z+                    ; Low Byte laden und Pointer erhöhen
    lpm     zh,z                        ; zweites Byte laden
    mov     zl,temp1                    ; erstes Byte in Z-Pointer kopieren
    ijmp

CmdNext:
	Vector	x, CmdBuffer
	adiw	zl, 5
	rjmp	CmdCheckChar

CmdExit:
	Vector	x, CmdBuffer
	ret;

;
; Befehle
;
Cmd1:
	ZTab 	Txt1, Null
	rcall	TxtOut
	ret

Cmd2:
	ZTab 	Txt2, Null
	rcall	TxtOut
	ret

Cmd3:
	ZTab 	TxtStart, Null
	rcall	TxtOut
	ret

Cmd4:
	ldi		temp1, 42
	rcall	Bin2Asc8
	mov		char, temp2
	rcall	SerialOut
	mov		char, temp1
	rcall	SerialOut
	ret




;***************************************************************************
;*
;* "Bin2BCD8" - 8-bit Binary to BCD conversion
;*
;* This subroutine converts an 8-bit number (temp1) to a 2-digit
;* BCD number (temp1:temp2).
;*
;* Number of words	:6 + return
;* Number of cycles	:5/50 (Min/Max) + return
;* Low registers used	:None
;* High registers used  :2 (temp1/temp2,temp3)
;*
;* Included in the code are lines to add/replace for packed BCD output.	
;*
;***************************************************************************

;***** Subroutine Register Variables

;temp1	8-bit binary value
;temp1	BCD result MSD
;temp2	BCD result LSD

;***** Code

Bin2bcd8:
	clr		temp2			;clear result MSD
bBCD8_1:
	subi	temp1,10	;input = input - 10
	brcs	bBCD8_2		;abort if carry set
	inc		temp2		;inc MSD
;---------------------------------------------------------------------------
; Replace the above line with this one
; for packed BCD output				
;	subi	temp2,-$10 	;temp2 = temp2 + 10
;---------------------------------------------------------------------------
	rjmp	bBCD8_1		;loop again
bBCD8_2:
	subi	temp1,-10	;compensate extra subtraction
;---------------------------------------------------------------------------
; Add this line for packed BCD output
;	add	temp1,temp2	
;---------------------------------------------------------------------------	
	ret


;***************************************************************************
;*
;* "Bin2Ascii8" - 8-bit Binary to Ascii conversion
;*
;* This subroutine converts an 8-bit number (temp1) to a 2-digit
;* Ascii number (temp3:temp2).
;*
;* Number of words	:6 + return
;* Number of cycles	:5/50 (Min/Max) + return
;* Low registers used	:None
;* High registers used  :2 (temp1/temp2,temp3)
;*
;* Included in the code are lines to add/replace for packed Ascii output.	
;*
;***************************************************************************

;***** Subroutine Register Variables

; temp1	8-bit binary value
; temp2	Ascii result MSD
; temp3	Ascii result LSD

;***** Code

Bin2Asc8:
	rcall	Bin2BCD8
	ldi		temp3, '0'
	add		temp1, temp3
	add		temp2, temp3
	ret



Asc2Bin8:
	ldi		temp3, '0'
	sub		temp1, temp3
	sub		temp2, temp3
	rcall	BCD2bin8
	ret

;***************************************************************************
;*
;* "BCD2bin8" - BCD to 8-bit binary conversion
;*
;* This subroutine converts a 2-digit BCD number (temp2:temp1) to an
;* 8-bit number (temp1).
;*
;* Number of words	:4 + return
;* Number of cycles	:3/48 (Min/Max) + return
;* Low registers used	:None
;* High registers used  :2 (temp1/temp1,temp2)	
;*
;* Modifications to make the routine accept a packed BCD number is indicated
;* as comments in the code. If the modifications are used, temp2 shall be
;* loaded with the BCD number to convert prior to calling the routine.
;*
;***************************************************************************

;***** Subroutine Register Variables

; temp1	binary result
; temp1	lower digit of BCD input
; temp2	higher digit of BCD input

;***** Code

BCD2bin8:
;--------------------------------------------------------------------------
;| For packed BCD input, add these two lines
;|	mov	temp1,temp2	;copy input to result
;|	andi	temp1,$0f	;clear higher nibble of result
;--------------------------------------------------------------------------

BCDb8_0:
	subi	temp2,1		;temp2 = temp2 - 1
;--------------------------------------------------------------------------
;| For packed BCD input, replace the above
;| line with this
;|	subi	temp2,$10	;MSD = MSD - 1
;--------------------------------------------------------------------------

	brcs	BCDb8_1		; if carry not set

	subi	temp1,-10	; result = result + 10
	rjmp	BCDb8_0		; loop again
BCDb8_1:
	ret			;else return



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

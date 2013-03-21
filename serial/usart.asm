
;
; Sendet das Zeichen > char < auf dem Uart
;
UsartOut:
    sbis    UCSRA,UDRE                  ; Warten bis UDR für das nächste
                                        ; Byte bereit ist
    rjmp    UsartOut
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
; Sendet null-terminierten Text vom Prg-Spreicher auf den Z zeigt
;
UsartTxtOut:
	lpm		char, z+
	cpi		char, cnull
	breq	UsartTxtOutExit
	rcall	UsartOut
	rjmp	UsartTxtOut
UsartTxtOutExit:
	rcall   SerialSync
	ret


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
	rcall	UsartOut					; Zeichen Echo
	
	cpi		char, ccr					; wurde Return empfangen?
	brne	URX_INT_Exit				; wenn nicht dann Interrupt verlassen
	
	mov		temp1, char					; Zeichen sichern
	ldi		char, clf					; Linefeed laden
	rcall	UsartOut					; und ausgeben
	mov		char, temp1					; Zeichen wiederherstellen

URX_INT_Exit:	  
	pop     temp1
    out     sreg, temp1					; SREG wiederherstellen
    pop     temp1						; temp1 wiederherstellen
    reti 

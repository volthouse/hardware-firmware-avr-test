timer1_compare:                     ; Timer 1 Output Compare Handler
 
        push    temp1               ; temp1 1 sichern
		push	temp2
        in      temp1,sreg          ; SREG sichern
 
        inc     SubCount            ; Wenn dies nicht der 100. Interrupt
        cpi     SubCount, 50        ; ist, dann passiert gar nichts
        brne    end_isr

		sbic	PIND, 6				; Toggle PIND6
		cbi		PORTD, 6
		sbis	PIND, 6
		sbi		PORTD, 6	

                                    ; �berlauf
        clr     SubCount            ; SubCount r�cksetzen
        inc     Sekunden            ; plus 1 Sekunde
        cpi     Sekunden, 60        ; sind 60 Sekunden vergangen?
        brne    Ausgabe             ; wenn nicht kann die Ausgabe schon
                                    ; gemacht werden
 
                                    ; �berlauf
        clr     Sekunden            ; Sekunden wieder auf 0 und daf�r
        inc     Minuten             ; plus 1 Minute
        cpi     Minuten, 60         ; sind 60 Minuten vergangen ?
        brne    Ausgabe             ; wenn nicht, -> Ausgabe
 
                                    ; �berlauf
        clr     Minuten             ; Minuten zur�cksetzen und daf�r
        inc     Stunden             ; plus 1 Stunde
        cpi     Stunden, 24         ; nach 24 Stunden, die Stundenanzeige
        brne    Ausgabe             ; wieder zur�cksetzen
 
                                    ; �berlauf
        clr     Stunden             ; Stunden r�cksetzen
 
Ausgabe:
        ldi     flag,1              ; Flag setzen, LCD updaten
 
end_isr:
 
        out     sreg,temp1          ; sreg wieder herstellen
		pop		temp2
        pop     temp1
        reti                        ; das wars. Interrupt ist fertig

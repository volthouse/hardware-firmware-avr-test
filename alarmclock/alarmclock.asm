.include "m8def.inc"
 
.def temp1 = r16
.def temp2 = r17
.def temp3 = r18
.def Flag  = r19
 
.def SubCount = r21
.def Sekunden = r22
.def Minuten  = r23
.def Stunden  = r24
 
.org 0x0000
           rjmp    main             ; Reset Handler
.org OC1Aaddr
           rjmp    timer1_compare   ; Timer Compare Handler
 
 
main:
        ldi     temp1, HIGH(RAMEND)
        out     SPH, temp1
        ldi     temp1, LOW(RAMEND)  ; Stackpointer initialisieren
        out     SPL, temp1
 
									; PORTD initialisieren
 		ldi     temp1, 0b11111011
	    out     DDRD, temp1
		ldi     temp1, 0x00
	    out     PORTD, temp1

	    ldi     r16,0x00
	    out     PORTD,r16
                                    ; Vergleichswert 
        ldi     temp1, high( 40000 - 1 )
        out     OCR1AH, temp1
        ldi     temp1, low( 40000 - 1 )
        out     OCR1AL, temp1
                                    ; CTC Modus einschalten
                                    ; Vorteiler auf 1
        ldi     temp1, ( 1 << WGM12 ) | ( 1 << CS10 )
        out     TCCR1B, temp1
 
        ldi     temp1, 1 << OCIE1A  ; OCIE1A: Interrupt bei Timer Compare
        out     TIMSK, temp1
 
        clr     Minuten             ; Die Uhr auf 0 setzen
        clr     Sekunden
        clr     Stunden
        clr     SubCount
        clr     Flag                ; Flag löschen
 
        sei
loop:
        cpi     flag,0
        breq    loop                ; Flag im Interrupt gesetzt?
        ldi     flag,0              ; Flag löschen
 
        rjmp    loop
 
timer1_compare:                     ; Timer 1 Output Compare Handler
 
        push    temp1               ; temp 1 sichern
        in      temp1,sreg          ; SREG sichern
 
        inc     SubCount            ; Wenn dies nicht der 100. Interrupt
        cpi     SubCount, 200       ; ist, dann passiert gar nichts
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
        pop     temp1
        reti                        ; das wars. Interrupt ist fertig

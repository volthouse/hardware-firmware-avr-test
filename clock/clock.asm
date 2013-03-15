.include    "m8def.inc"

.CSEG
.ORG	0x0000
		rjmp 	Start

Start:
		ldi     r16, HIGH(RAMEND)
        out     SPH, r16
        ldi     r16, LOW(RAMEND)     ; Stackpointer initialisieren
        out     SPL, r16

	    ldi     r16,0xFF
	    out     DDRD,r16

	    ldi     r16,0b11111111
	    out     PORTD,r16
		ldi		r18,5

Loop:
		inc		r18
		cpi		r18,15
		brne	L10
		ldi		r18,5
			
L10:	ldi     r16,0x00
	    out     PORTD,r16
		rcall	Delay
		ldi     r16,0xFF
	    out     PORTD,r16
		rcall	Delay
	    rjmp    Loop

Delay:
		push	r18
L03:	ldi		r17,0xff
L02:	ldi		r16,0xff
L01:	dec		r16
		brne	L01
		dec		r17
		brne	L02
		dec		r18
		brne	L03
		pop		r18
		ret

.include    "m8def.inc"
.include 	"macros.inc"


;.DSEG
;table:	.BYTE 5

.CSEG
.ORG	0x0000
		rjmp 	Start

Start:
		ldi     r16, HIGH(RAMEND)
        out     SPH, r16
        ldi     r16, LOW(RAMEND)     ; Stackpointer initialisieren
        out     SPL, r16

	    ldi     r16,0b11111011
	    out     DDRD,r16

	    ldi     r16,0x00
	    out     PORTD,r16


Main:	in		r16,PIND
		cpi		r16,0x04
		brne	Main
		
LoopM:	Vector	z,table
	
Loop:		
		lpm		r18,z+
		cpi		r18,0xFF
		breq	LoopM

		ldi     r16,0x00
	    out     PORTD,r16
		rcall	Delay
		ldi     r16,0xFF
	    out     PORTD,r16
		rcall	Delay

	    rjmp    Loop

Delay:
		push	r18
		push	r17
		push	r16

L03:	ldi		r17,0xff
L02:	ldi		r16,0xff
L01:	dec		r16
		brne	L01
		dec		r17
		brne	L02
		dec		r18
		brne	L03
		
		pop		r16
		pop		r17
		pop		r18
		ret


table:
		.DB 0x06,	0x06,	0x07,	0x08,	0x08,	0x08,	0x09,	0x09,	0x09,	0x09,	0x09,	0x08,	0x08,	0x08,	0x07,	0x06,	0x06,	0x05,	0x04,	0x04,	0x03,	0x02,	0x02,	0x02,	0x01,	0x01,	0x01,	0x01,	0x01,	0x02,	0x02,	0x02,	0x03,	0x04,	0x04,	0x05,	0xFF


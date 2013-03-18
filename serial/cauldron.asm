; ***** EvTax
; ***** Analogmonitor
; ***** 

; -----------------------------------------------------------------------------
.nolist
.include "tn261adef.inc"
.include "macros.inc"
.device ATtiny261A
.list
.listmac

; -----------------------------------------------------------------------------
.def	Attrib		= R13			; Kanal Attribute
.def	One		= R14			; := 1
.def	Null		= R15			; := 0
.def	TxIdx		= R21			; Transmit-Index
.def	Index		= R22			; Sample-Order
.def	Flags		= R23			; ADC-Kanal aktualisiert

; -----------------------------------------------------------------------------
.equ	VarLen		= 14			; Byte pro Feld

; -----------------------------------------------------------------------------
.equ	val_Filters	= 0x0			; AVG Filter Data
.equ	val_Val0	= 0x8			; Sample (low)
.equ	val_Val1	= 0x9			; Sample (high)
.equ	val_Index	= 0xa			; Filter Index
.equ	val_Flags	= 0xb			; Validate
.equ	val_Dat0	= 0xc			; Data (low)
.equ	val_Dat1	= 0xd			; Data (high)

; -----------------------------------------------------------------------------
.dseg
Values:		.BYTE	6*VarLen		; Kanal Samples

; -----------------------------------------------------------------------------
.cseg
.org    0x0000
		rjmp	Reset			; Resetvector
.org	INT0addr
		rjmp	IRQ0			; Interrupt0
.org	ADCCaddr
		rjmp	ADCInt			; ADC-Interrupt

.org    INT_VECTORS_SIZE
; -----------------------------------------------------------------------------
Reset:						; Init
		ldi	r16,0b00000010		; Enable PLL
		out	PLLCSR,r16

		ldi	r16,SRAM_Size		; SRAM löschen (definieren)
		clr	r17
		ldi	zl,low(SRAM_Start)
		ldi	zh,high(SRAM_Start)
L014:
		st	z+,r17
		dec	r16
		brne	L014

		ldi     r16,low(RAMEND)     	; Stack am SRAM-Ende
                out     SPL,r16
L016:
		in	r16,PLLCSR
		sbrs	r16,PLOCK
		rjmp	L016

		ldi	r16,0b00000110
		out	PLLCSR,r16
		
		ldi     r16,0b00000000		; Port A
                out     DDRA,r16
		ldi	r16,0b00000000
		out	PORTA,r16

                ldi     r16,0b00010000		; Port B
                out     DDRB,r16
		ldi	r16,0b11101111
		out	PORTB,r16

		ldi	r16,0b11111111		; Disable Digital Input at A
		out	DIDR0,r16
		
		ldi	r16,0b10001111
		out	ADCSRA,r16
		ldi	r16,0b11010000
		out	ADCSRB,r16
		ldi	r16,0b01100000
		out	ADMUX,r16

		in	r16,ADCH

		ldi	r16,0b00000010		; INT0 Sensitivity
		out	MCUCR,r16
		ldi	r16,0b01000000		; INT0 Enable
		out	GIMSK,r16

; -----------------------------------------------------------------------------
StartUp:
		clr	Null			; register Definition
		clr	One
		inc	One
		clr	Flags
		clr	Index
		clr	TxIdx
		clr	Attrib

		sei				; Enable IRQ-System
; -----------------------------------------------------------------------------
Main:						; Mainloop
		sbrs	Flags,7
		rjmp	Main

		cbr	Flags,0x80

		rcall	Evaluate		; Auswertung
		
		Vector	y,Values + 4*VarLen
		rcall	Render

		Vector	y,Values + 5*VarLen
		rcall	Render

		rjmp	Main		
; -----------------------------------------------------------------------------
IRQ0:						; INT0 (Sample Clock [extern])
		push	r16
		push	r17
		push	r18
		in	r18,SREG
		push	r18
		push	zl
		push	zh			; Prolog

;		sbi	PORTB,PB4
;		cbi	PORTB,PB4

		mov	r16,TxIdx		; Transmitt Channel
		lsl	r16
		ZTab	TransmitterMap,r16

		lpm	r16,z+
		lpm	r17,z+
		mov	zl,r16
		mov	zh,r17
		adiw	z,val_Dat0

		ldi	r16,20
		ld	r2,z+
		ld	r3,z+
		mov	r4,TxIdx
L0030:
		sbrc	r2,0
		rjmp	L0031

		sbi	PORTB,PB4
		cbi	PORTB,PB4
		
		lsr	r4
		ror	r3
		ror	r2
		dec	r16
		brne	L0030
		rjmp	L0032
L0031:
		sbi	PORTB,PB4		
		lsr	r4
		ror	r3
		ror	r2
		cbi	PORTB,PB4

		dec	r16
		brne	L0030
L0032:
		add	TxIdx,One
;		ldi	TxIdx,5
		cpi	TxIdx,6
		brne	L0033
		clr	TxIdx
L0033:
		sbi	ADCSRA,ADSC		; start conversion

		pop	zh			; Epilog
		pop	zl
		pop	r18
		out	SREG,r18
		pop	r18
		pop	r17
		pop	r16
		reti
; -----------------------------------------------------------------------------
ADCInt:						; ADC InterruptVector
		push	r16			; Prolog
		push	r17
		push	r18
		in	r18,SREG		; PSW merken
		push	r18
		push	zl
		push	zh

		in	r0,ADCL
		in	r1,ADCH
		
		mov	r16,Index		; Tabelle auslesen
		lsl	r16
		lsl	r16
		ZTab	ChannelMap,r16
		
		adiw	z,1			; Kanal * sizeof(Values)
		lpm	r18,z+
		lpm	Attrib,z+

		Vector	z,Values
		Plus	z,r18

		sbrc	Attrib,0		; Discard ?
		rjmp	L006

		sbrs	Attrib,1		; Bipolar ?
		rjmp	L004

		ldi	r16,0x80
		eor	r1,r16			; arithmetic
L004:
		lsr	r1
		ror	r0
		lsr	r1
		ror	r0
		lsr	r1
		ror	r0

		ldd	r16,z+val_Flags
		sbr	r16,1			; Render
		std	z+val_Flags,r16

		ldd	r17,z+val_Index		; new Index
		mov	r16,r17
		add	r17,One
		andi	r17,3
		std	z+val_Index,r17

		lsl	r16			; Save Sample
		Plus	z,r16
		st	z+,r0
		st	z+,r1
L006:
		add	Index,One		; next Channel
		cpi	Index,48
		brne	L005
		clr	Index
L005:
		mov	r16,Index		; neu
		lsl	r16
		lsl	r16
		ZTab	ChannelMap,r16

		in	r16,ADMUX		; setup next Channel
		andi	r16,~(0x1f)
		lpm	r17,z
		andi	r17,0x1f
		or	r16,r17
		out	ADMUX,r16

		in	r16,ADCSRB
		andi	r16,~(1 << MUX5)
		lpm	r17,z
		lsr	r17
		lsr	r17
		andi	r17,(1 << MUX5)
		or	r16,r17
		out	ADCSRB,r16

		sbr	Flags,0x80		; Data Valid

;		sbi	PORTB,PB4
;		cbi	PORTB,PB4

		pop	zh			; Epilog
		pop	zl
		pop	r18
		out	SREG,r18		
		pop	r18
		pop	r17
		pop	r16
		reti
; -----------------------------------------------------------------------------
Evaluate:					; Kanal - Auswertung
		clr	r19
		Vector	y,Values
L0020:
		ldd	r16,y+val_Flags
		sbrs	r16,0
		rjmp	L0021

		ldd	r16,y+val_Flags
		cbr	r16,1
		std	y+val_Flags,r16		; valid Off
		movw	x,y

		ldi	r18,4			; AVR Window
		clr	r10
		clr	r11
L0022:
		ld	r16,x+
		ld	r17,x+
		add	r10,r16
		adc	r11,r17

		dec	r18
		brne	L0022

		sbrs	r19,2			; TempChan (?)
		rjmp	L0024
		
		ldd	r16,y+val_Flags
		sbr	r16,2
		std	y+val_Flags,r16
		std	y+val_Val0,r10		; TempData
		std	y+val_Val1,r11
		rjmp	L0021
L0024:
		std	y+val_Dat0,r10
		std	y+val_Dat1,r11
L0021:
		adiw	y,VarLen
		add	r19,One
		cpi	r19,6
		brne	L0020

		ret
; -----------------------------------------------------------------------------
Render:						; Digit >> Temp 
		ldd	r16,y+val_Flags
		sbrs	r16,1
		ret

		cbr	r16,2
		std	y+val_Flags,r16

		ldd	r10,y+val_Val0
		ldd	r11,y+val_Val1

		ZTab	PT_Temperature_Tab,Null
		clr	r16
L020:
		lpm	r8,z+
		lpm	r9,z+
		sub	r8,r10			; Iterationswert
		sbc	r9,r11
		brcc	L022

		adiw	z,4
		add	r16,One
		cpi	r16,15
		brne	L020

		ldi	r16,0x7f
		mov	r11,r16
		ldi	r16,0x80
		mov	r10,r16
		rjmp	L024
L022:
		lpm	xl,z+			; Delta
		lpm	xh,z+

		rcall	Multiply

		lpm	r10,z+			; Temp Startwert
		lpm	r11,z+
		add	r10,r8
		adc	r11,r9
L024:
		std	y+val_Dat0,r10
		std	y+val_Dat1,r11
		ret
; -----------------------------------------------------------------------------
Multiply:					; Delta*x => r8:r9
		mov	r5,r8			; Shiftreg
		mov	r6,r9
		clr	r7
		clr	r8

		clr	r9			; Accu
		clr	r10
		clr	r11
		clr	r12

		ldi	r16,16
L030:		
		sbrs	xl,0			; lsb
		rjmp	L031

		add	r9,r5
		adc	r10,r6
		adc	r11,r7
		adc	r12,r8
L031:
		lsr	xh
		ror	xl

		lsl	r5
		rol	r6
		rol	r7
		rol	r8

		dec	r16
		brne	L030

		mov	r8,r10
		mov	r9,r11

		ret
; -----------------------------------------------------------------------------
ChannelMap:					; Kanalabfolge
		.db	0b00000011, 0*VarLen, 0b00000001, 0
		.db	0b00000011, 0*VarLen, 0b00000001, 0
		.db	0b00000011, 0*VarLen, 0b00000001, 0
		.db	0b00000011, 0*VarLen, 0b00000001, 0
		.db	0b00000011, 0*VarLen, 0b00000000, 0
		.db	0b00000011, 0*VarLen, 0b00000000, 0
		.db	0b00000011, 0*VarLen, 0b00000000, 0
		.db	0b00000011, 0*VarLen, 0b00000000, 0

		.db	0b00000100, 1*VarLen, 0b00000001, 0
		.db	0b00000100, 1*VarLen, 0b00000001, 0
		.db	0b00000100, 1*VarLen, 0b00000001, 0
		.db	0b00000100, 1*VarLen, 0b00000001, 0
		.db	0b00000100, 1*VarLen, 0b00000000, 0
		.db	0b00000100, 1*VarLen, 0b00000000, 0
		.db	0b00000100, 1*VarLen, 0b00000000, 0
		.db	0b00000100, 1*VarLen, 0b00000000, 0
		
		.db	0b00000101, 2*VarLen, 0b00000001, 0
		.db	0b00000101, 2*VarLen, 0b00000001, 0
		.db	0b00000101, 2*VarLen, 0b00000001, 0
		.db	0b00000101, 2*VarLen, 0b00000001, 0
		.db	0b00000101, 2*VarLen, 0b00000000, 0
		.db	0b00000101, 2*VarLen, 0b00000000, 0
		.db	0b00000101, 2*VarLen, 0b00000000, 0
		.db	0b00000101, 2*VarLen, 0b00000000, 0
					
		.db	0b00000110, 3*VarLen, 0b00000001, 0
		.db	0b00000110, 3*VarLen, 0b00000001, 0
		.db	0b00000110, 3*VarLen, 0b00000001, 0
		.db	0b00000110, 3*VarLen, 0b00000001, 0
		.db	0b00000110, 3*VarLen, 0b00000000, 0
		.db	0b00000110, 3*VarLen, 0b00000000, 0
		.db	0b00000110, 3*VarLen, 0b00000000, 0
		.db	0b00000110, 3*VarLen, 0b00000000, 0
		
		.db	0b00100011, 4*VarLen, 0b00000011, 0
		.db	0b00100011, 4*VarLen, 0b00000011, 0
		.db	0b00100011, 4*VarLen, 0b00000011, 0
		.db	0b00100011, 4*VarLen, 0b00000011, 0
		.db	0b00100011, 4*VarLen, 0b00000010, 0
		.db	0b00100011, 4*VarLen, 0b00000010, 0
		.db	0b00100011, 4*VarLen, 0b00000010, 0
		.db	0b00100011, 4*VarLen, 0b00000010, 0

		.db	0b00100101, 5*VarLen, 0b00000011, 0
		.db	0b00100101, 5*VarLen, 0b00000011, 0
		.db	0b00100101, 5*VarLen, 0b00000011, 0
		.db	0b00100101, 5*VarLen, 0b00000011, 0
		.db	0b00100101, 5*VarLen, 0b00000010, 0
		.db	0b00100101, 5*VarLen, 0b00000010, 0
		.db	0b00100101, 5*VarLen, 0b00000010, 0
		.db	0b00100101, 5*VarLen, 0b00000010, 0

; -----------------------------------------------------------------------------
TransmitterMap:					; Struktur-Positionen
		.dw	Values + 0*VarLen
		.dw	Values + 1*VarLen
		.dw	Values + 2*VarLen
		.dw	Values + 3*VarLen
		.dw	Values + 4*VarLen
		.dw	Values + 5*VarLen
; -----------------------------------------------------------------------------
PT_Temperature_Tab:
		.dw 	0x0010, 0x0000, 0x7fff
		.dw 	0x0A77, 0x039F, 0x4D00
		.dw 	0x1681, 0x0367, 0x23FF
		.dw 	0x23F8, 0x0331, 0xF8FE
		.dw 	0x3261, 0x02FB, 0xCDFE
		.dw 	0x413B, 0x057A, 0x4D01
		.dw 	0x48FC, 0x0549, 0x23FF
		.dw 	0x516A, 0x0519, 0xF901
		.dw 	0x5A2C, 0x04E8, 0xCDFE
		.dw 	0x79BB, 0x1535, 0x4CFF
		.dw 	0x7BAE, 0x1509, 0x23FD
		.dw 	0x7DBD, 0x14DE, 0xF906
		.dw 	0x7FD1, 0x14B2, 0xCE02
		.dw 	0xFFFF, 0x0000, 0x8000
; -----------------------------------------------------------------------------

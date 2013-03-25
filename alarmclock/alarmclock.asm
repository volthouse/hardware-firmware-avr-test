;***
;* AlarmClock - Example
;*
;****/


.include "m8def.inc"
.include "macros.inc"
 
; Register definition
.def Null	= r15								; := 0
.def temp1  = r16                             	
.def temp2	= r17
.def temp3	= r18
.def char 	= r19                              	; recieved char    
.def Flag   = r20

; Clock 
.def SubCount = r21
.def Sekunden = r22
.def Minuten  = r23
.def Stunden  = r24 
 
; Constants
.equ F_CPU 	= 16000000                          ; System clock (Hz)
.equ BAUD  	= 9600                              ; Baudrate

.equ CESC	= 0x1B								; ESCAPE character
.equ CCR	= 0x0D								; Carriage return character 
.equ CLF	= 0x0A								; Line feed character
.equ CNULL	= 0x00

; Timer 0 Callback Flags
.equ TIMEOUTPUTCALLBACK	= 0
.equ BEEPCALLBACK		= 1

; Baudrate calculations
.equ UBRR_VAL   = ((F_CPU+BAUD*8)/(BAUD*16)-1)  ; round
.equ BAUD_REAL  = (F_CPU/(16*(UBRR_VAL+1)))     ; real Baudrate
.equ BAUD_ERROR = ((BAUD_REAL*1000)/BAUD-1000)  ; error (Promille)
 
.equ CMDBUFFSIZE 	= 10
.equ COUNTERSIZE	= 2

; Data
.dseg
CmdBuffer: 			.byte CMDBUFFSIZE			; Usart receiver buffer
TimerCallbackFlags:	.byte 1
Counter:			.byte COUNTERSIZE


.if ((BAUD_ERROR>10) || (BAUD_ERROR<-10))       ; max. +/-10 Promille error
  .error "Systematischer Fehler der Baudrate grösser 1 Prozent und damit zu hoch!"
.endif



.cseg

.org 0x0000
        rjmp    Reset             	; Reset Handler
.org OC1Aaddr
        rjmp    Timer1_Compare_Int  ; Timer Compare Handler
.org OVF0addr
        rjmp    Timer0_Overflow_Int	; Timer overflow
.org URXCaddr                       
        rjmp 	Usart_Rx_Int		; Usart Interrupt

 
;
; Initialization
;
Reset:
	; Register initialization
	clr		Null
	clr		temp1
	clr		temp2
	clr		temp3
	clr		char

	; Stackpointer initialization

    ldi     temp1, HIGH(RAMEND)
    out     SPH, temp1
    ldi     temp1, LOW(RAMEND)  
    out     SPL, temp1

	; clear SRAM

	ldi		r16,low(SRAM_Size)		; ToDo: clear high Ram
	clr		r17
	ldi		zl,low(SRAM_Start)
	ldi		zh,high(SRAM_Start)

ClearSRAM:
	st	z+,r17
	dec	r16
	brne	ClearSRAM

	; Port initialization

	ldi     temp1, 0b11111011
    out     DDRD, temp1
	ldi     temp1, 0x00
    out     PORTD, temp1

    ldi     r16,0x00
    out     PORTD,r16
 	
	; Usart initialization

    ldi     temp1, HIGH(UBRR_VAL)
    out     UBRRH, temp1
    ldi     temp1, LOW(UBRR_VAL)
    out     UBRRL, temp1 
    							; Frame-Format: 8 Bit

    ldi     temp1, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
    out     UCSRC, temp1

    sbi     UCSRB,TXEN          ; activate TX
	sbi     UCSRB, RXCIE        ; enable Usart interrupt
    sbi     UCSRB, RXEN         ; enable RX
 
 	; Timer initialization
                                ; Timer 1 compare value 
    ldi     temp1, high( 40000 - 1 )
    out     OCR1AH, temp1
    ldi     temp1, low( 40000 - 1 )
    out     OCR1AL, temp1
                                ; Timer 1 enable CTC mode
                                ; Timer 1 set prescaler
    ldi     temp1, ( 1 << WGM12 ) | ( 1 << CS11 )
    out     TCCR1B, temp1
								; Timer 0 set prescaler
	ldi		temp1, (1 << CS02) | (1 << CS00)
	out		TCCR0, temp1
								; Timer 1 enable Compare interrupt
								; Timer 0 enable Overflow interrupt
    ldi     temp1, (1 << OCIE1A) | (1 << TOIE0) 
    out     TIMSK, temp1

	; Clock initialization

    clr     Minuten             
    clr     Sekunden
    clr     Stunden
    clr     SubCount
    clr     Flag                

	; Command Buffer initialization
	
	Vector	x, CmdBuffer				; set X Pointer to CmdBuffer
	clr		char						; clear char
	
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
 

;
; Time output to Usart
;
SerOutTime:
	push	temp1
	push	temp2
	push	char

	mov		temp1,Stunden
	rcall 	Bin2Ascii8
	mov		char, temp2
	rcall	UsartPutChar
	mov		char, temp1
	rcall	UsartPutChar

	ldi		char, ':'
	rcall	UsartPutChar

	mov		temp1,Minuten
	rcall 	Bin2Ascii8
	mov		char, temp2
	rcall	UsartPutChar
	mov		char, temp1
	rcall	UsartPutChar
	
	ldi		char, ':'
	rcall	UsartPutChar

	mov		temp1,Sekunden
	rcall 	Bin2Ascii8
	mov		char, temp2
	rcall	UsartPutChar
	mov		char, temp1
	rcall	UsartPutChar


	ldi     char, 10
    rcall   UsartPutChar
    ldi     char, 13
    rcall   UsartPutChar

	pop		char
	pop		temp2
	pop		temp1
	ret



;
; String table
;

; ToDo: be carefully: number of bytes must be even!

Txt1:
	.db "excute Command on ", CLF, CCR, CNULL

Txt2:
	.db "excute Command off", CLF, CCR, CNULL

TxtStart:
	.db  CESC,'[','H',CESC,'[','J' ; ANSI Clear screen
	.db "*** AVR Alarm Clock Test ***", CLF, CCR
	.db "* Commands:                *", CLF, CCR
	.db "*  on:  Beep on            *", CLF, CCR
	.db "*  off: Beep off           *", CLF, CCR
	.db "*  timer on:  Time on      *", CLF, CCR
	.db "*  timer off: Time off     *", CLF, CCR
	.db "*  time: current Time      *", CLF, CCR
	.db "****************************", CLF, CCR
	.db CNULL


;
; Include Subroutine
;

.include "stdlib.asm"
.include "usart.asm"
.include "cmd.asm"
.include "timer0.asm"
.include "timer1.asm"

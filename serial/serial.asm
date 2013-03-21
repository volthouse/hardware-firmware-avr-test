;***
;* Example - demonstration of usart and command usage
;*
;****/

; Dependencies
.include "m8def.inc"
.include "macros.inc"

; Register definition
.def Null	= R15								; := 0
.def temp1  = r16                             	
.def temp2	= r17
.def temp3	= r18
.def char 	= r19                              	; recieved char                                                

; Constants
.equ F_CPU 	= 16000000                          ; System clock (Hz)
.equ BAUD  	= 9600                              ; Baudrate

.equ cesc	= 0x1B								; ESCAPE character
.equ ccr	= 0x0D								; Carriage return character 
.equ clf	= 0x0A								; Line feed character
.equ cnull	= 0x00

; Baudrate calculations
.equ UBRR_VAL   = ((F_CPU+BAUD*8)/(BAUD*16)-1)  ; round
.equ BAUD_REAL  = (F_CPU/(16*(UBRR_VAL+1)))     ; real Baudrate
.equ BAUD_ERROR = ((BAUD_REAL*1000)/BAUD-1000)  ; error (Promille)
 
; Data
.dseg
CmdBuffer: .BYTE 10 							; Usart receiver buffer


.if ((BAUD_ERROR>10) || (BAUD_ERROR<-10))       ; max. +/-10 Promille error
  .error "Systematischer Fehler der Baudrate grösser 1 Prozent und damit zu hoch!"
.endif
 
.cseg

.org 0x0000
        rjmp Reset
 
.org URXCaddr                                   ; Usart Interruptvector
        rjmp URX_INT

;
; Initialization
;
Reset:
	clr		Null
	clr		temp1
	clr		temp2
	clr		temp3
	clr		char

    ; init Stackpointer
 
    ldi     temp1, HIGH(RAMEND)
    out     SPH, temp1
    ldi     temp1, LOW(RAMEND)
    out     SPL, temp1

    ; init Baudrate
 
    ldi     temp1, HIGH(UBRR_VAL)
    out     UBRRH, temp1
    ldi     temp1, LOW(UBRR_VAL)
    out     UBRRL, temp1
 
    ; Frame-Format: 8 Bit
 
    ldi     temp1, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
    out     UCSRC, temp1
 
    sbi     UCSRB, TXEN                 ; enable TX
	sbi     UCSRB, RXCIE                ; enable Usart interrupt
    sbi     UCSRB, RXEN                 ; enable RX
    
	; Command Buffer initialization
	
	Vector	x, CmdBuffer				; set X Pointer to CmdBuffer
	clr		char						; clear char
    sei									; enable interrups
	
	; clear output and send startup text
	
	ZTab	TxtStart, Null				; Startup text
	rcall	UsartTxtOut	

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
; Commands
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
	rcall	Bin2Ascii8
	mov		char, temp2
	rcall	UsartOut
	mov		char, temp1
	rcall	UsartOut
	ret


;
; Command table
;

CmdTable:
	.db "set",ccr .dw Cmd1
	.db "del",ccr .dw Cmd2
	.db "clr",ccr .dw Cmd3
	.db "num",ccr .dw Cmd4
	.db	cnull

;
; String table
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

.include "stdlib.asm"
.include "usart.asm"
.include "cmd.asm"

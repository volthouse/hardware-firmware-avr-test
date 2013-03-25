;***
;* cmd - for commonly used command functions
;*
;****/


;
; Check command buffer and execute commands
;
; Subroutine Register Variables
;	temp1
;	temp2
; 	x, z pointer

; ToDo: x pointer is used in usart, mutal destruction?
Cmd:
	ZTab	CmdTable, Null
CmdCompare:								; compare CmdBuffer and CmdTable
	Vector	x, CmdBuffer
CmdCheckChar:	
	lpm		temp1, z+					; load char from prog mem
	ld		temp2, x+					; load char from CmdBuffer
	cpi		temp1, cnull				; if table end,
	breq	CmdExit						;	exit
	cpi		temp1, '\r'					; if carriage return,
	breq	CmdMatch					; 	command match
	cp		temp1, temp2				; if chars unequal,
	brne	CmdNext						; 	search next command
	rjmp	CmdCheckChar				; next char

CmdMatch:								
	lpm     temp1, z+					; load Low Byte and increment Pointer
	cpi		temp1, '\r'					; read over carriage return
	breq	CmdMatch					
	Vector	x, CmdBuffer				; set x pointer to cmdbuffer
    lpm     zh,z                        ; load second Byte
    mov     zl,temp1                    ; copy first Byte to Z-Pointer 
    ijmp

CmdNext:								; search next command
	cpi		temp1, '\r'					; read over carriage return
	breq	CmdSearchCmdEnd
	lpm		temp1, z+
	rjmp	CmdNext

CmdSearchCmdEnd:
	lpm		temp1, z+					; read over carriage return
	cpi		temp1, '\r'
	brne	CmdSearchCmdEndMatch
	rjmp	CmdSearchCmdEnd

CmdSearchCmdEndMatch:
	adiw	z, 1						; set pointer to begin of next command
	rjmp	CmdCompare					; compare next command

CmdExit:
	Vector	x, CmdBuffer
	ret;


;
; Commands
;
CmdBeepOn:
	ZTab 	Txt1, Null
	rcall	UsartTxtOut
	ldi		temp1, 1 << BEEPCALLBACK
	rcall 	RegisterTimer0Callback
	ret

CmdBeepOff:
	ZTab 	Txt2, Null
	rcall	UsartTxtOut
	ldi		temp1, 1 << TIMEOUTPUTCALLBACK
	rcall	UnregisterTimer0Callback
	ret

CmdStartupScreen:
	ZTab 	TxtStart, Null
	rcall	UsartTxtOut
	ret

CmdTimeOutputInterval:
	ldi		temp1, 42
	rcall	Bin2Ascii8
	mov		char, temp2
	rcall	UsartPutChar
	mov		char, temp1
	rcall	UsartPutChar

	ldi		temp1, 1 << TIMEOUTPUTCALLBACK
	rcall 	RegisterTimer0Callback
	ret

CmdTimeOutput:
	rcall	SerOutTime
	ret

;
; Command table
;
; be carefully: number of bytes must be even, padding with carriage return
CmdTable:
	.db "beep on", '\r', '\r'	; command name
	.dw CmdBeepOn				; command function
	.db "beep off", '\r'
	.dw CmdBeepOff
	.db "clr", '\r'
	.dw CmdStartupScreen
	.db "timer", '\r'
	.dw CmdTimeOutputInterval
	.db "time", '\r', '\r'
	.dw CmdTimeOutput


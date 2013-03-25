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
	cpi		temp1, CCR					; if carriage return,
	breq	CmdMatch					; 	command match
	cp		temp1, temp2				; if chars unequal,
	brne	CmdNext						; 	search next command
	rjmp	CmdCheckChar				; next char

CmdMatch:								
	lpm     temp1, z+					; load Low Byte and increment Pointer
	cpi		temp1, CCR					; read over carriage return
	breq	CmdMatch					
	Vector	x, CmdBuffer				; set x pointer to cmdbuffer
    lpm     zh,z                        ; load second Byte
    mov     zl,temp1                    ; copy first Byte to Z-Pointer 
    ijmp

CmdNext:								; search next command
	cpi		temp1, CCR					; read over carriage return
	breq	CmdSearchCmdEnd
	lpm		temp1, z+
	rjmp	CmdNext

CmdSearchCmdEnd:
	lpm		temp1, z+					; read over carriage return
	cpi		temp1, CCR
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
	ldi		temp1, 1 << BEEPCALLBACK
	rcall	UnregisterTimer0Callback
	ret

CmdStartupScreen:
	ZTab 	TxtStart, Null
	rcall	UsartTxtOut
	ret

CmdTimeOutputIntervalOn:
	ldi		temp1, 1 << TIMEOUTPUTCALLBACK
	rcall 	RegisterTimer0Callback
	ret

CmdTimeOutputIntervalOff:
	ldi		temp1, 1 << TIMEOUTPUTCALLBACK
	rcall 	UnregisterTimer0Callback
	ret


CmdTimeOutput:
	rcall	SerOutTime
	ret

;
; Command table
;
; be carefully: number of bytes must be even, padding with carriage return
CmdTable:
	.db "on", CCR, CCR	; command name
	.dw CmdBeepOn				; command function
	.db "off", CCR
	.dw CmdBeepOff
	.db "clr", CCR
	.dw CmdStartupScreen
	.db "timer on", CCR, CCR
	.dw CmdTimeOutputIntervalOn
	.db "timer off", CCR
	.dw CmdTimeOutputIntervalOff
	.db "time", CCR, CCR
	.dw CmdTimeOutput
	.db CNULL, CNULL


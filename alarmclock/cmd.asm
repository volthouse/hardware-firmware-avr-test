;***
;* cmd - for commonly used command functions
;*
;****/


;
; Check command buffer and execute commands
;
Cmd:
	ZTab	CmdTable, Null
CmdCompare:
	Vector	x, CmdBuffer
CmdCheckChar:	
	lpm		temp1, z+
	ld		temp2, x+
	cpi		temp1, cnull		
	breq	CmdExit
	cpi		temp1, '\r'
	breq	CmdMatch
	cp		temp1, temp2
	brne	CmdNext
	rjmp	CmdCheckChar

CmdMatch:
	lpm     temp1, z+					; load Low Byte and increment Pointer
	cpi		temp1, '\r'
	breq	CmdMatch
	Vector	x, CmdBuffer				; set x pointer to cmdbuffer
;	lpm     temp1, z+                   ; load Low Byte and increment Pointer
    lpm     zh,z                        ; load second Byte
    mov     zl,temp1                    ; copy first Byte to Z-Pointer 
    ijmp

CmdNext:
	cpi		temp1, '\r'
	breq	CmdSearchCmdEnd
	lpm		temp1, z+
	rjmp	CmdNext

CmdSearchCmdEnd:
	lpm		temp1, z+
	cpi		temp1, '\r'
	brne	CmdSearchCmdEndMatch
	rjmp	CmdSearchCmdEnd

CmdSearchCmdEndMatch:
	adiw	z, 1
	rjmp	CmdCompare

CmdExit:
	Vector	x, CmdBuffer
	ret;


;
; Commands
;
Cmd1:
	ZTab 	Txt1, Null
	rcall	UsartTxtOut
	ldi		temp1, 1
	rcall 	RegisterCallback
	ret

Cmd2:
	ZTab 	Txt2, Null
	rcall	UsartTxtOut
	ldi		temp1, 1
	rcall	UnregisterCallback
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

	ldi		temp1, 2
	rcall 	RegisterCallback
	ret

Cmd5:
	rcall	SerOutTime
	ret

;
; Command table
;
; be carefully: number of bytes must be even, padding with carriage return
CmdTable:
	.db "on", '\r', '\r'
	.dw Cmd1
	.db "off", '\r'
	.dw Cmd2
	.db "clr", '\r'
	.dw Cmd3
	.db "timer", '\r'
	.dw Cmd4 
	.db "time", '\r', '\r'
	.dw Cmd5


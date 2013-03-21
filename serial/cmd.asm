;***
;* cmd - for commonly used command functions
;*
;****/


;
; Check command buffer and execute commands
;
Cmd:
	ZTab	CmdTable, Null
	Vector	x, CmdBuffer
CmdCheckChar:	
	lpm		temp1, z+
	ld		temp2, x+
	cpi		temp1, cnull		
	breq	CmdExit
	cpi		temp1, ccr
	breq	CmdMatch
	cp		temp1, temp2
	brne	CmdNext
	rjmp	CmdCheckChar

CmdMatch:
	Vector	x, CmdBuffer
	lpm     temp1,z+                    ; load Low Byte and increment Pointer
    lpm     zh,z                        ; load second Byte
    mov     zl,temp1                    ; copy first Byte to Z-Pointer 
    ijmp

CmdNext:
	Vector	x, CmdBuffer
	adiw	zl, 5
	rjmp	CmdCheckChar

CmdExit:
	Vector	x, CmdBuffer
	ret;


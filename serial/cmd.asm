
;
; Befehle die über den Uart empfangen wurden bearbeiten
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
	lpm     temp1,z+                    ; Low Byte laden und Pointer erhöhen
    lpm     zh,z                        ; zweites Byte laden
    mov     zl,temp1                    ; erstes Byte in Z-Pointer kopieren
    ijmp

CmdNext:
	Vector	x, CmdBuffer
	adiw	zl, 5
	rjmp	CmdCheckChar

CmdExit:
	Vector	x, CmdBuffer
	ret;


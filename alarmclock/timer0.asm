

timer0_overflow:
	
		push	temp1
        in      temp1,sreg
		push	temp1
		push	zh
		push	zl

		Vector	z, Callbacks
		ld      temp1,z+                    ; load Low Byte and increment Pointer
		cpi		temp1, 0
		breq	timer0_overflow_Exit	
	    ld      zh,z                        ; load second Byte
	    mov     zl,temp1                    ; copy first Byte to Z-Pointer 
	    icall
		

timer0_overflow_Exit:
		pop		zl
		pop		zh
		pop		temp1
		out		sreg,temp1
		pop		temp1

		reti




CBTest:
		ldi		zh,high(CBDummy)
		ldi		zl,low(CBDummy)
		rcall	RegisterCallback

	

		ret

CBDummy:
		sbic	PIND, 7				; Toggel PIND6
		cbi		PORTD, 7
		sbis	PIND, 7
		sbi		PORTD, 7
		ret;


RegisterCallback:
		Vector 	y, Callbacks
RegisterCallbackNext:
		ld		temp1, y
		cpi		temp1, 0
		breq	RegisterCallbackExit
		adiw	y, 2
		rjmp	RegisterCallbackNext	

RegisterCallbackExit:
		st		y+, zl
		st		y, zh
		ret

UnregisterCallback:
		Vector	y, Callbacks
		ldi		temp1, 0
		st		y+, temp1
		st		y, temp1
		ret


TimerCallbacks:
		.dw CBDummy, cnull
		.dw dummy, cnull

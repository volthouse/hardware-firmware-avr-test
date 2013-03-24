

timer0_overflow:
		push	temp2
		push	temp1
        in      temp1,sreg
		push	temp1
		push	zh
		push	zl		
		
		Vector	z, TimerCallbackFlags	; load flags
		ld		temp1, z
			
		sbrc	temp1,0
		rcall	CBDummy
		sbrc	temp1,1
		rcall	CBDummy1

		Vector	z, Counter
		clr		temp2
timer0_overflow_L01:
		cpi		temp2, COUNTERSIZE
		brge	timer0_overflow_Exit		
		ld		temp1, z
		inc		temp1
		st		z+, temp1
		inc		temp2
		rjmp	timer0_overflow_L01

timer0_overflow_Exit:
		pop		zl
		pop		zh
		pop		temp1
		out		sreg,temp1
		pop		temp1
		pop		temp2
		reti





CBDummy:
		sbic	PIND, 7				; Toggel PIND6
		cbi		PORTD, 7
		sbis	PIND, 7
		sbi		PORTD, 7
		ret;

CBDummy1:
		push	temp1
		ldi		temp1, 0
		rcall	GetCounter
		cpi		temp1, 200
		brlo	CBDummy_L01
		ldi		temp1, 0
		rcall 	ClearCounter

		rcall 	SerOutTime
		
CBDummy_L01:
		pop		temp1
		ret


RegisterCallback:
		push	temp2
		push	zh
		push	zl
		
		Vector	z, TimerCallbackFlags	; load flags
		ld		temp2, z
		or		temp2, temp1
		st		z, temp2
		
		pop		zl
		pop		zh
		pop		temp2
		ret

UnregisterCallback:
		push	temp2
		push	zh
		push	zl
		
		Vector	z, TimerCallbackFlags	; load flags
		ld		temp2, z
		eor		temp2, temp1
		st		z, temp2
		
		pop		zl
		pop		zh
		pop		temp2
		ret


GetCounter:
		push	zh
		push	zl

		Vector	z, Counter
		Plus	z, temp1
		ld		temp1, z

		pop		zl
		pop		zh
		ret

ClearCounter:
		push	temp1
		push	zh
		push	zl
		
		Vector	z, Counter
		Plus	z, temp1
		clr		temp1
		st		z, temp1

		pop		zl
		pop		zh
		pop		temp1
		ret
		

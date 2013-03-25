;***
;* timer0 - timer0 functions
;*
;****/

;
; Timer 0 interupt
;
Timer0_Overflow_Int:
	push	temp2					; prolog
	push	temp1
	in      temp1,sreg
	push	temp1
	push	zh
	push	zl		

	; handle Timer Callbacks

	Vector	z, TimerCallbackFlags	; load flags
	ld		temp1, z
	
	sbrc	temp1,TIMEOUTPUTCALLBACK
	rcall	Timer_TimeOutputCallback		

	sbrc	temp1,BEEPCALLBACK
	rcall	Timer_BeepCallback

	; increment Counter	

	Vector	z, Counter
	clr		temp2
Timer0_Overflow_Int_Counter:
	cpi		temp2, COUNTERSIZE
	brge	Timer0_Overflow_Int_Exit		
	ld		temp1, z
	inc		temp1
	st		z+, temp1
	inc		temp2
	rjmp	Timer0_Overflow_Int_Counter

Timer0_Overflow_Int_Exit:			; epiloge
	pop		zl
	pop		zh
	pop		temp1
	out		sreg,temp1
	pop		temp1
	pop		temp2
	reti


;
; Toggle Beeper
;
Timer_BeepCallback:
	sbic	PIND, 7				; toggel PIND6
	cbi		PORTD, 7
	sbis	PIND, 7
	sbi		PORTD, 7
	ret;

;
; Output Time to Usart
;
Timer_TimeOutputCallback:
	push	temp1

	ldi		temp1, 0			; check Counter 0
	rcall	GetCounter
	cpi		temp1, 200
	brlo	Timer_TimeOutputCallbackExit

	ldi		temp1, 0
	rcall 	ClearCounter

	rcall 	SerOutTime			; Output Time to Usart
		
Timer_TimeOutputCallbackExit:
	pop		temp1
	ret


;
; Register timer 0 callback function
;
; Subroutine Register Variables
;	temp1		: Flag
;	temp2		: temporary
; 	z pointer
RegisterTimer0Callback:
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

;
; Unregister timer 0 callback function
;
; Subroutine Register Variables
;	temp1		: Flag
;	temp2		: temporary
; 	z pointer
UnregisterTimer0Callback:
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

;
; Get Counter value
;
; Subroutine Register Variables
;	temp1		: Counter index 
GetCounter:
	push	zh
	push	zl

	Vector	z, Counter
	Plus	z, temp1
	ld		temp1, z

	pop		zl
	pop		zh
	ret

;
; Clear Counter
;
; Subroutine Register Variables
;	temp1		: Counter index 
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
		

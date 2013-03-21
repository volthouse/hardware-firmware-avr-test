
;***************************************************************************
;*
;* "Bin2BCD8" - 8-bit Binary to BCD conversion
;*
;* This subroutine converts an 8-bit number (temp1) to a 2-digit
;* BCD number (temp1:temp2).
;*
;* Number of words	:6 + return
;* Number of cycles	:5/50 (Min/Max) + return
;* Low registers used	:None
;* High registers used  :2 (temp1/temp2,temp3)
;*
;* Included in the code are lines to add/replace for packed BCD output.	
;*
;***************************************************************************

;***** Subroutine Register Variables

;temp1	8-bit binary value
;temp1	BCD result MSD
;temp2	BCD result LSD

;***** Code

Bin2bcd8:
	clr		temp2			;clear result MSD
bBCD8_1:
	subi	temp1,10	;input = input - 10
	brcs	bBCD8_2		;abort if carry set
	inc		temp2		;inc MSD
;---------------------------------------------------------------------------
; Replace the above line with this one
; for packed BCD output				
;	subi	temp2,-$10 	;temp2 = temp2 + 10
;---------------------------------------------------------------------------
	rjmp	bBCD8_1		;loop again
bBCD8_2:
	subi	temp1,-10	;compensate extra subtraction
;---------------------------------------------------------------------------
; Add this line for packed BCD output
;	add	temp1,temp2	
;---------------------------------------------------------------------------	
	ret


;***************************************************************************
;*
;* "Bin2Ascii8" - 8-bit Binary to Ascii conversion
;*
;* This subroutine converts an 8-bit number (temp1) to a 2-digit
;* Ascii number (temp3:temp2).
;*
;* Number of words	:6 + return
;* Number of cycles	:5/50 (Min/Max) + return
;* Low registers used	:None
;* High registers used  :2 (temp1/temp2,temp3)
;*
;* Included in the code are lines to add/replace for packed Ascii output.	
;*
;***************************************************************************

;***** Subroutine Register Variables

; temp1	8-bit binary value
; temp2	Ascii result MSD
; temp3	Ascii result LSD

;***** Code

Bin2Asc8:
	rcall	Bin2BCD8
	ldi		temp3, '0'
	add		temp1, temp3
	add		temp2, temp3
	ret



Asc2Bin8:
	ldi		temp3, '0'
	sub		temp1, temp3
	sub		temp2, temp3
	rcall	BCD2bin8
	ret

;***************************************************************************
;*
;* "BCD2bin8" - BCD to 8-bit binary conversion
;*
;* This subroutine converts a 2-digit BCD number (temp2:temp1) to an
;* 8-bit number (temp1).
;*
;* Number of words	:4 + return
;* Number of cycles	:3/48 (Min/Max) + return
;* Low registers used	:None
;* High registers used  :2 (temp1/temp1,temp2)	
;*
;* Modifications to make the routine accept a packed BCD number is indicated
;* as comments in the code. If the modifications are used, temp2 shall be
;* loaded with the BCD number to convert prior to calling the routine.
;*
;***************************************************************************

;***** Subroutine Register Variables

; temp1	binary result
; temp1	lower digit of BCD input
; temp2	higher digit of BCD input

;***** Code

BCD2bin8:
;--------------------------------------------------------------------------
;| For packed BCD input, add these two lines
;|	mov	temp1,temp2	;copy input to result
;|	andi	temp1,$0f	;clear higher nibble of result
;--------------------------------------------------------------------------

BCDb8_0:
	subi	temp2,1		;temp2 = temp2 - 1
;--------------------------------------------------------------------------
;| For packed BCD input, replace the above
;| line with this
;|	subi	temp2,$10	;MSD = MSD - 1
;--------------------------------------------------------------------------

	brcs	BCDb8_1		; if carry not set

	subi	temp1,-10	; result = result + 10
	rjmp	BCDb8_0		; loop again
BCDb8_1:
	ret			;else return

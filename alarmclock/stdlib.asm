;***
;* stdlib - for commonly used library functions
;*
;****/

;
; "Bin2BCD8" - 8-bit Binary to BCD conversion
;
; This subroutine converts an 8-bit number (temp1) to a 2-digit
; BCD number (temp1:temp2).
;
; Subroutine Register Variables
;	temp1	8-bit binary value
;	temp1	BCD result MSD
;	temp2	BCD result LSD

Bin2bcd8:
	clr		temp2		; clear result MSD
bBCD8_1:
	subi	temp1,10	; input = input - 10
	brcs	bBCD8_2		; abort if carry set
	inc		temp2		; inc MSD
	rjmp	bBCD8_1		; loop again
bBCD8_2:
	subi	temp1,-10	; compensate extra subtraction
	ret
	
;
; "BCD2bin8" - BCD to 8-bit binary conversion
;
; This subroutine converts a 2-digit BCD number (temp2:temp1) to an
; 8-bit number (temp1).
;
; Subroutine Register Variables
; 	temp1	binary result
; 	temp1	lower digit of BCD input
; 	temp2	higher digit of BCD input

BCD2bin8:
	subi	temp2,1		; temp2 = temp2 - 1
	brcs	BCDb8_1		;  if carry not set
	subi	temp1,-10	;  result = result + 10
	rjmp	BCD2bin8	;	 loop again
BCDb8_1:
	ret

;
; "Bin2Ascii8" - 8-bit Binary to Ascii conversion
;
; This subroutine converts an 8-bit number (temp1) to a 2-digit
; Ascii number (temp3:temp2).
;
; Subroutine Register Variables
; 	temp1	8-bit binary value
; 	temp1	Ascii result MSD
; 	temp2	Ascii result LSD
; 	temp3 Ascii code for 0

Bin2Ascii8:
	rcall	Bin2BCD8		; convert binary to BCD
	ldi		temp3, '0'
	add		temp1, temp3	; add Ascii '0'=48
	add		temp2, temp3	; add Ascii '0'=48
	ret

;
; "Ascii2Bin8" - Ascii to 8-bit binary conversion
;
; This subroutine converts a 2-digit Ascii number (temp2:temp1) to an
; 8-bit number (temp1).
;
; Subroutine Register Variables
; 	temp1	binary result
; 	temp1	lower digit of BCD input
; 	temp2	higher digit of BCD input
; 	temp3 Ascii code for 0

Ascii2Bin8:
	ldi		temp3, '0'
	sub		temp1, temp3	; substract Ascii '0'=48
	sub		temp2, temp3	; substract Ascii '0'=48
	rcall	BCD2bin8		; convert BCD to binary
	ret

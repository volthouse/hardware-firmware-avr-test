;***
;* usart - for commonly used usart functions
;*
;****/


;
; Sends a character (char) to uart
;
UsartPutChar:
    sbis    UCSRA,UDRE                  ; Wait until UDR is ready for the next byte
    rjmp    UsartPutChar
    out     UDR, char
    ret

;
; Synchronization
;                                 
UsartSync:
    ldi     r16,0
UsartSync_1:
    ldi     r17,0
UsartSync_loop:
    dec     r17
    brne    UsartSync_loop
    dec     r16
    brne    UsartSync_1  
    ret

;
; Sends null-terminated string (set Z-Pointer to string table in Prog-Mem)
;
UsartTxtOut:
	lpm		char, z+
	cpi		char, cnull
	breq	UsartTxtOutExit
	rcall	UsartPutChar
	rjmp	UsartTxtOut
UsartTxtOutExit:
	rcall   UsartSync
	ret


;
; Usart Rx Interrupt
;
Usart_Rx_Int:
    push    temp1						; save temp1
	in      temp1, sreg					; save SREG
    push    temp1

    in      char, UDR                   ; read received Byte and clear Interrupt Flag
					                    
    ; TODO: auf Puffer Ende Prüfen !!!!!!!
	st		x+, char					; store char to reciver buffer
	rcall	UsartPutChar					; char echo
	
	cpi		char, ccr					; is char equals return code (13))
	brne	Usart_Rx_Int_Exit				; if not goto exit
	
	mov		temp1, char					; save char temporarily
	ldi		char, clf					; load line feed char
	rcall	UsartPutChar					; send line feed
	mov		char, temp1					; restore char

Usart_Rx_Int_Exit:	  
	pop     temp1						
    out     sreg, temp1					; restore SREG
    pop     temp1						; restore temp1
    reti 

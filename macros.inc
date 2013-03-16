.MACRO Vector ;(Adresse)
        ldi     @0H, HIGH(2*@1)
        ldi     @0L, LOW(2*@1)
		;LDI ZH,HIGH(2*table)
   		;LDI ZL,LOW(2*table)
.ENDMACRO

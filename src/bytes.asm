	# pastreaza doar al doilea octet al valorii dintr-un registru dat ca parametru
	# intentionat pentru valori half-word(16b)
	.macro lobyte (%reg)
	andi %reg, %reg, 0x000000FF
	.end_macro
	
	# pastreaza doar al doilea octet al valorii dintr-un registru dat ca parametru
	# intentionat pentru valori half-word(16b)
	.macro hibyte (%reg)
	srl %reg, %reg, 8
	andi %reg, %reg, 0x000000FF
	.end_macro
	
	# pastreaza in registrul dat ca parametru doar cel mai semnificativ nibble
	.macro hinib (%reg)
	srl %reg, %reg, 4
	andi %reg, %reg, 0x0000000F
	.end_macro
	
	# pastreaza in registrul dat ca parametru doar cel mai nesemnificativ nibble
	.macro lonib (%reg)
	andi %reg, %reg, 0x0000000F
	.end_macro 
	
	## reseteaza toti bitii de pe pozitiile 31:16 dintr-un registru
	## util pentru cand lucram cu valori pe 16b si intervin si shiftari
	.macro keep_lower16 (%reg)
	andi %reg, %reg, 0x0000FFFF
	.end_macro
	
	

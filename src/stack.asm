	# poate eventual vrei sa te asiguri ca aceste macro-uri fac wrapping in caz ca sp depaseste limitele din memorie
	# !!! stiva ca adresa este dupa segmentul de text si cel de date
	
	# pusheaza un word in stiva din registrul corespunzator
	# si modifica stack pointerul in mod corespunzator
	.macro push_word (%reg)
	addi $sp, $sp, -4
	sw %reg, ($sp)
	.end_macro
	
	# pop-uie un word din stiva in registrul specificat
	# si modifica stack pointerul in mod corespunzator
	.macro pop_word (%reg)
	lw %reg, ($sp)
	addi $sp, $sp, 4
	.end_macro
	
	

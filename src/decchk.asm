	.include "stack.asm"
	.include "utils.asm"

##############################################
#
# Program driver
#
##############################################
	.data
str:	.asciiz "1923556417" # modifica aici datele de test
len:	.byte 10	            # modifica aici datele de test
endl:	.asciiz "\n"

	.macro print_char (%reg)
	push_word ($a0)
	move $a0, %reg
	li $v0, 11
	syscall
	pop_word ($a0)
	.end_macro
	
	.macro print_int (%reg)
	push_word ($a0)
	move $a0, %reg
	li $v0, 1
	syscall
	pop_word ($a0)
	.end_macro
	
	.macro print_string (%addr)
	push_word ($a0)
	la $a0, %addr
	li $v0, 4
	syscall
	pop_word ($a0)
	.end_macro
		
	.text
main:
	la $a0, str
	lb  $a1, len
	jal _decchk
	print_char ($v0)
	exit
	
##############################################
	
##############################################
#
#     Calculeaza suma de control pentru o secventa de cifre de lungime aleatoare
#    ARG:
#        a0 - char* string - pointer catre string-ul pt. care calculez checksum-ul - esential este un sir de cifre, deci literele se ignora
#        a1 - uint len     - lungimea string-ului (consideram sizeof(uint) = 4 octeti)
#        a2 - char* ch     - adresa catre octetul in care va fi scris octetul checksum
#
#    RETVAL:
#	 v0 	           - suma de control calculata pentru sirul dat
#	 v1 	           - valabil doar daca codul zecimal are deja suma de control atasata; e sau nu e corecta acea suma?
#
##############################################	
	.data
	# matricea de inmultire in grupul (structura algebrica) D_5 (vezi carte)
ip:	.byte 0, 1, 5, 8, 9, 4, 2, 7, 1, 5,  8, 9, 4, 2, 7, 0, 2, 7, 0, 1,
	      5, 8, 9, 4, 3, 6, 3, 6, 3, 6,  3, 6, 4, 2, 7, 0, 1, 5, 8, 9,
	      5, 8, 9, 4, 2, 7, 0, 1, 6, 3,  6, 3, 6, 3, 6, 3, 7, 0, 1, 5,
              8, 9, 4, 2, 8, 9, 4, 2, 7, 0,  1, 5, 9, 4, 2, 7, 0, 1, 5, 8
        # matricea de permutare specifica pentru acest algoritm (vezi carte)
ij:     .byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,  1, 2, 3, 4, 0, 6, 7, 8, 9, 5,
              2, 3, 4, 0, 1, 7, 8, 9, 5, 6,  3, 4, 0, 1, 2, 8, 9, 5, 6, 7,
              4, 0, 1, 2, 3, 9, 5, 6, 7, 8,  5, 9, 8, 7, 6, 0, 4, 3, 2, 1,
              6, 5, 9, 8, 7, 1, 0, 4, 3, 2,  7, 6, 5, 9, 8, 2, 1, 0, 4, 3,
              8, 7, 6, 5, 9, 3, 2, 1, 0, 4,  9, 8, 7, 6, 5, 4, 3, 2, 1, 0
         
         # pentru acces la un element din matricea de inmultire
        .macro ip_acc (%line, %col)
	la $v0, ip
	mul $t9, %line, 8
	add $v0, $v0, $t9
	add $v0, $v0, %col
	lb $v0, ($v0)
	.end_macro
	
	# pentru acces la un element din matricea de permutare
	.macro ij_acc (%line, %col)
	la $v0, ij
	mul $t9, %line, 10
	add $v0, $v0, $t9
	add $v0, $v0, %col
	lb $v0, ($v0)
	.end_macro
              
	.text
_decchk:
	li $v1, 0		# 	incarc ret_val <- false la inceput
	
	li $s0, 48		#	margine inferioara cifre in ascii (pt verificare cifra; orice alt caracter ignorat)
	li $s1, 57		# 	margine superioara cifre in ascii (pt verificare cifra; orice alt caracter ignorat)
	li $s2, 0		#	int k
	li $s3, 0		# 	int m

	move $t0, $a0		# 	t0 <- aux pentru pointerul a0
	
	## for 1 ##
	li $t1, 0		# 	for (uint j = 0; j < n; j++) {
L1:	beq $t1, $a1, endL1
	
	lb $t2, ($t0)		# 		c = aux (<=> string[j]); t2 <=> c
	
	blt $t2, $s0, not_digit	# 		if (c < 48 || c > 57) continue;
	bgt $t2, $s1, not_digit
	
	addi $t3, $t2, 2	# 		t3 <- c + 2
	rem $t3, $t3, 10	# 		t3 <- (c + 2) % 10
	and $t4, $s3, 7		# 		t4 <- 7 & m
	ip_acc ($t3, $t4)	# 		v0 <- ip[(c+2) % 10][7 & m];
	move $t4, $v0		# 		t4 <- v0
	ij_acc ($s2, $t4)	# 		v0 <- ij[k][ip[(c+2) % 10][7 & m]];
	move $s2, $v0		# 		s2 (k) <- v0
	
	## debug ##
	print_int ($s2)
	print_string (endl)
	########### 
	
	addi $s3, $s3, 1	# 		m++;
	
not_digit:
	addi $t0, $t0, 1	# 		aux++;
	addi $t1, $t1, 1
	
	b L1			#	}
endL1:  
	###########
	
	## for 2 ##

	li $t0, 0		# 	for (uint j = 0; j <= 9; j++) {
L2:	beq $t0, 10, endL2
	
	and $t1, $s3, 7		# 		t1 <- m & 7	
	ip_acc ($t0, $t1)			
	move $t1, $v0		#		t1 <- ip[j][m & 7];
	ij_acc ($s2, $t1)
	move $t1, $v0		# 		t2 <- ij[k][ip[j][m & 7]];
	
	beqz $t1, endL2		# 		if (!ij[k][ip[j][m & 7]]) break;
	
	addi $t0, $t0, 1
	b L2			#	}
endL2:
	##########
	
	## prelucrare finala rezultat ##
	addi $t0, $t0, 48	# 	conversie a rezultatului la cifra corespunzatoare in tabelul ascii
	move $v0, $t0
	
	bnez $s2, end		# verific daca k == 0 <=> cifra suma de control atasata sirului este valida -> sirul este valid
	li $v1, 1
end:
	jr $ra
	
##############################################

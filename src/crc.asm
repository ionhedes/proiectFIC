	
	.include "stack.asm"
	.include "bytes.asm"
	.include "utils.asm"

##############################################
#
# Program driver
#	
##############################################	
	.data
mask:	.word 0x00008000
gen:	.word 4129
str:	.asciiz "Piatra crapa capul caprei in patru, cum a crapat si capra piatra in patru."
len:    .byte 74
endl:	.asciiz "\n"
space:	.asciiz " "
	
	.macro print_int (%reg)
	push_word ($a0)
	move $a0, %reg
	li $v0, 1
	syscall
	pop_word ($a0)
	.end_macro
	
	.macro print_hex (%reg)
	push_word ($a0)
	move $a0, %reg
	li $v0, 34
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
	
	.macro print_char (%reg)
	push_word ($a0)
	move $a0, %reg
	li $v0, 11
	syscall
	pop_word ($a0)
	.end_macro
	
	# macro folosit ca sa inversez cuvinte folosind tabela de caractere inversate
	# nu o apela inainte de init
	# am facut-o ca sa nu trebuiasca sa tot scriu acelasi cod, dar nu o pot pune in bytes.asm
	# (pt. ca ar insemna ca includ de 2 ori stack.asm)
	.macro rev_half (%reg)
	push_word ($t1)
	push_word ($t2)
	push_word ($t3)
	la $t1, rchr
	move $t2, %reg
	hibyte ($t2)		# 	t2 <- hibyte(word);
	add $t2, $t2, $t1	# 	t2 <- addr(rchr + hibyte(word)); (incarcam bytes deci nu e nevoie sa sarim cate 2,4 adrese)
	lb $t2, ($t2)		# 	t2 <- rchr[hibyte(word)];
	
	move $t3, %reg
	lobyte ($t3)		#	t3 <- lobyte(word);
	add $t3, $t3, $t1	#	t3 <- addr(rchr + lobyte(word)); (incarcam bytes deci nu e nevoie sa sarim cate 2,4 adrese)
	lb $t3, ($t3)		# 	t3 <- rchr[lobyte(word)];
	sll $t3, $t3, 8		# 	t3 <- rchr[lobyte(word)] << 8;
	
	or %reg, $t2, $t3	# 	word <- rchr[hibyte(word)] | rchr[lobyte(word)] << 8;
	
	pop_word ($t3)
	pop_word ($t2)
	pop_word ($t1)
	.end_macro
	
	.text
main:
	la $t0, str
	push_word ($t0)		# 	stack <- bufptr (string-ul pentru care fac crc)
	li $a0, 0		# 	a0 <- crc = 0 (crc-ul "precedent")
	lb $a1, len		#	a1 <- len = 12 (lungimea string-ului pe care se calculeaza crc)
	li $a2, 0		# 	a2 <- jinit = 0 (initializez crc cu 0)
	li $a3, 0		# 	a3 <- jrev = 0 (nu vreau sa fac rev)
	jal _icrc		# 	v1 <- icrc(crc, bufptr, len, jinit, jrev);
	print_hex ($v1)		# 	print($v1)
	exit

##############################################


##############################################
#
#     Calculeaza CRC-ul pe 16b pentru o secventa de octeti
#    ARG:
#        a0 - crc - valoarea de return a unui apel icrc() anterior?
#        stack - uchar* bufptr - pointer catre sirul de octeti
#        a1 - uint len     - lungimea sirului de octeti (consideram sizeof(uint) = 4 octeti)
#        a2 - short jinit   - >=0 - CRC-ul se initializeaza cu fiecare octet
#                                pe valoarea jinit
#                        - <0  - CRC-ul se initializeaza cu valoarea crc
#                                (care poate fi crc-ul unei secvente precedente
#                                de octeti (*1))
#        a3 - int jrev      - <0  - caracterele prelucrate vor fi inversate dpdv al
#                                bitilor (al endianess-ului?)
#                              - de asemenea, crc-ul final va fi inversat dpdv. al
#                                bitilor
#
#    RETVAL:
#         v1 - 		- crc-ul
#
##############################################
	.data
icrctb:	.half 0 : 256		# pentru stocarea tabelei de rezultate crc pentru fiecare caracter posibil din ascii
rchr:	.byte 0 : 256		# pentru stocarea tabelului caracterelor bit-inversate
it:	.byte 0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15 # stocare hardcodata fiecare varianta de nibble inversat; ex.: inv[2] = 4 (0010 invers = 0100)
init:	.byte 0			# va fi 0 daca inca nu s-a initializat tabela de crc-uri caractere si tabela de caractere bit-inversate

	.text
_icrc:	
	push_word ($a0)
	push_word ($a1)
	
	## partea de init tabele crc ##
	lb $t0, init
	bnez $t0, crcinit	# if (init == 0) {
	
	li $t0, 1
	sb $t0, init		#	init = 1;
	
	la $t1, icrctb		#	crt_addr_icrctb = icrctb;
	la $t2, rchr		#	crt_addr_rchr = rchr;	
	
	li $t0, 0		# 	for (int i = 0; i < 256; i++) {
tbfor:	beq $t0, 256, crcinit	
	
	move $a0, $t0		#		crc - a0 <- i << 8
	sll $a0, $a0, 8
	
	push_word ($t0)		#		imi salvez registrii astia in stiva pentru ca sunt refolositi in _icrc1
	push_word ($t1)
	push_word ($t2)
	push_word ($t3)
	push_word ($ra)		#		icrc1(i << 8)
	jal _icrc1
	pop_word ($ra)
	pop_word ($t3)		# 		restaurez registrii la valorile de dinainte de apel _icrc1
	pop_word ($t2)
	pop_word ($t1)
	pop_word ($t0)
	
	sh $v1, ($t1)		#		mem[crt_addr_icrctb] = icrc1(i << 8)
	
	add $t1, $t1, 2		#		crt_addr_icrctb += 2; (pt ca lucrez cu half-worduri (2 octeti), iar sistemul e byte-addressable)
	
	la $t3, it		#		it
	move $t4, $t0		#		t4 <- i;
	lonib ($t4)		#		t4 <- i & 0xF;
	add $t4, $t4, $t3	#		t4 <- it + i & 0xF;
	lb $t4, ($t4)		#		t4 <- mem[it + i & 0xF];
	sll $t4, $t4, 4		#		t4 <- mem[it + i & 0xF] << 4;
	
	move $t5, $t0		#		t5 <- i;
	hinib ($t5)		#		t5 <- i >> 4;
	add $t5, $t5, $t3	#		t5 <- it + i >> 4;
	lb $t5, ($t5)		#		t5 <- mem[it + i >> 4];
	
	or $t4, $t4, $t5	#		t4 <- it[i & 0xF] << 4 | it [j >> 4];
	sb $t4, ($t2)		#		mem[crt_addr_rchr] = it[i & 0xF] << 4 | it [j >> 4];
	addi $t2, $t2, 1	#		crt_addr_rchr += 1; (pt ca lucrez cu octeti, iar sistemul e byte-addressable)
	
	addi $t0, $t0, 1
	b tbfor			#	}
	
	###########
	
crcinit:	## partea de initializare rezultat ##
	pop_word ($a1)		# a1 <- len (restitui param cu care a fost apelat _icrc)
	pop_word ($a0)		# a0 <- crc (restitui param cu care a fost apelat _icrc)
	pop_word ($t0)		# t0 <- adresa sir (scoatem param din stiva)
				# a2 <- jinit
				# a3 <- jrev
	bltz $a2, ldprev	# if (jinit >= 0) {
	li $t3, 0x000000FF
	and $t1, $a2, $t3	#	t1 <- (uchar)jinit; (prin & cu masca pastreaza ultimii 16b nesemnif)
	sll $t2, $t1, 8		# 	t2 <- jinit << 8;
	or $t9, $t1, $t2	# 	cword <- ((uchar) jinit) | (((uchar) jinit) << 8);
	b checkrev
ldprev: 			# } else {
	move $t9, $a0		# 	cword <- crc;
				# }
				
checkrev:			
	bgez $a3, iterstr		# if (jrev < 0) {
	rev_half ($t9)		# 	cword = rev_half(cword);
				# }
	###########
	
	
iterstr:	## partea de generare crc ##
	li $t1, 0		# j = 0;
	la $t2, icrctb		# t2 <- addr(icrctb)
	
crcfor:				# for (int j = 0; j < len; j++)	{
	beq $t1, $a1, finrev
	
	bltz $a3, rev		# 	if (jrev >= 0) {
	add $t3, $t0, $t1	#		t3 <- addr(bufptr + j); (in sir sunt octeti, deci adaug j*1 la adresa)
 	b nxt_chr		#	} else {
rev:	
	la $t3, rchr		# 		t3 <- addr(rchr);
	add $t4, $t0, $t1	# 		t4 <- addr(bufptr + j);
	lb $t4, ($t4)		#		t4 <- bufptr[j]; (in sir sunt octeti, deci adaug 1 la adresa)
	add $t3, $t3, $t4	#		t3 <- addr(rchr + bufptr[j]); (in rchr sunt tot octeti, deci adaug 1 la adresa)
				#	}
nxt_chr:
	lb $t3, ($t3)		# 	next_char <- (jrev < 0 ? rchr[bufptr[j]] : bufptr[j]);
	move $t4, $t9		#	t4 <- cword;
	hibyte ($t4)		# 	t4 <- hibyte(cword);
	xor $t4, $t3, $t4	#	t4 <- next_char ^ hibyte(cword);
	add $t4, $t4, $t4	# 	t4 <- 2 * (next_char ^ hibyte(cword)); (in icrctb sunt half-worduri, deci va treb sa adaug 2*... la adresa de inceput ca sa gasesc elem cautat)
	add $t4, $t4, $t2	#	t4 <- addr(icrctb + 2 * next_char ^ hibyte(cword)); (in icrctb sunt half-worduri, deci adaug 2*cv la adresa)
	lh $t4, ($t4)		# 	t4 <- icrctb[next_char ^ hibyte(cword)];
	
	move $t5, $t9		# 	t5 <- cword;
	lobyte ($t5)		# 	t5 <- lobyte(cword);
	sll $t5, $t5,  8	# 	t5 <- lobyte(cword) << 8;
	
	xor $t9, $t4, $t5	# 	cword <- icrctb[next_char ^ hibyte(cword)] ^ (lobyte(cword) << 8);
	
	addi $t1, $t1, 1	# 	j++; (in sir sunt octeti, deci adaug 1 la adresa)
	b crcfor		# }
	
	##########
	
	
finrev:		## revese final ##
	bgez $a3, return	# if (jrev < 0) {
	rev_half ($t9)		# 	cword = rev_half(cword);
				# }
	
return: 
	keep_lower16 ($t9)
	move $v1, $t9		# t1 <- cword (crc; folosesc v1 pentru return)
	jr $ra			# return

##############################################


##############################################
#
#     Calculeaza amprenta pe care o va avea un octet la zapare
#     Va fi apelata repetat de 256 de ori pentru a genera tabelul de valori precalculate icrctb
#    ARG:
#        a0 - crc - caracterul care trebuie sa se afle in hibyte
#
#    RETVAL:
#         v1 - rezultatul zaparii cu caracterul crc in hibyte
#
##############################################
_icrc1: 
	li $t2, 7		# i = 8;
	move $v1, $a0
	
	lh $t4, gen
	
l2:				# do {
	lw $t3, mask
	and $t3, $v1, $t3	# t3 <- ans & mask
	beqz $t3, nozap		# if (ans & mask == 0) goto nozap; adica daca MSB e 1 (caz de zap)
	sll $v1, $v1, 1		# else { ans <<= 1;
	xor $v1, $v1, $t4		#	ans ^= gen;}
	b re
	
nozap:	
	sll $v1, $v1, 1		#	ans <<= 1;
	
re:
	
	addi $t2, $t2, -1	#	i--;
	bgez $t2, l2		# } while (i >= 0)
	
	
	keep_lower16 ($v1)
	jr $ra
	
##############################################	
	
	

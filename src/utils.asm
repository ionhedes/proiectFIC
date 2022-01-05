	# initial am vrut sa fie mai multe chestii aici

	# apeleaza syscall-ul care termina procesul in care ruleaza programul simulat
	.macro exit
	li $v0, 10
	syscall
	.end_macro
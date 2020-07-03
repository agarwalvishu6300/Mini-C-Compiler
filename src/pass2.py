import sys
import pass2func


#variable declaration

with open (sys.argv[1], "r") as fil:
    data=fil.readlines()

print(".data")

variables = []
dataType = {}

for i in data:
	textData = i.split('\n')[0].split(',')
	print(textData[0], end=":")
	variables.append(textData[0])
	if textData[2] == "0":
		if(textData[1] == "int"):
			print(" .word 0")
			dataType[textData[0]] = "int"
		else :
			dataType[textData[0]] = "float"
			print(" .float 0.0")
	else:
		print(" .space "+textData[2])

print("newline: .asciiz \"\\n\"")
print(".text")
print(".globl main")

# local variables for each function

with open (sys.argv[2], "r") as fil:
    mainCode=fil.readlines()

localVariables = {}

for i in mainCode:
	text = i.split('\n')[0].split(' ')
	text = list(filter(('').__ne__, text))
	if text[1] == "func" and text[2] == "begin":
		curFunc = text[3]
		localVariables[curFunc] = list()
	for j in text:
		if j.endswith("_" + curFunc) and j not in localVariables[curFunc]:
			localVariables[curFunc].append(j)

for i in mainCode:
	text = i.split('\n')[0].split(' ')
	text = list(filter(('').__ne__, text))
	text[0] = 'L'+text[0]
	if len(text) <= 1:
		continue;
	if text[1] != "func":	
		print(text[0], end=" ")
	# goto statemements
	if(text[1] == "goto"):		
		text[2] = 'L'+ text[2]
		print("b " + text[2], end="")
	elif text[1] == "func":
		if text[2] == "begin":
			# i in $ai initialized to zero.
			cnt = 0
			curFunc = text[3]
			print(curFunc + ":", end="")
		else:
			print(text[0], end=" ")
			print("jr $ra")
	#return t0 or f0
	elif text[1] == "return":
		if len(text)==2:
			print("jr $ra", end="")
		# return t0
		elif pass2func.checkword(text[2]):
			print("move $v0, " + pass2func.checker(variables, text[2]))
			print("jr $ra", end="")
		# return f0
		else:												
			print("mfc1 $v0, " + pass2func.checker(variables, text[2]))
			print("jr $ra", end="")

	elif text[1] == "call":
		#push remaining ai
		# move stack if on first param
		if cnt != 0:
			text2 = str(cnt*4)
		else:
			text2 = ""
			sz = (len(localVariables[curFunc])*4) + 108
			print("addi $sp,$sp,-" + str(sz))
		# push $ai on stack
		for textData in range(0, 4-cnt):
			print("sw $a" + str(cnt+textData) + ", " + text2 + "($sp)")
			text2 = str((cnt+textData+1)*4)
		#push t0-t9
		# push $ti on stack
		for textData in range(10):
			print("sw $t" + str(textData) + ", " + str(4*(4+textData)) + "($sp)")
		#push f0-f9 and f20
		for textData in range(10):
			print("swc1 $f" + str(textData) + ", " + str(4*(14+textData)) + "($sp)")
		print("swc1 $f20, 96($sp)")
		#push s0
		print("sw $s0, 100($sp)")
		#push ra
		print("sw $ra, 104($sp)")
		#push all variables in this function on stack
		for i, local in enumerate(localVariables[curFunc]):
			print("lw $t0, " + local)
			print("sw $t0, " + str((i*4)+108) + "($sp)")

		print("jal " + text[2].split(',')[0])
		# restore all registers
		print("lw $a0, ($sp)")
		print("lw $a1, 4($sp)")
		print("lw $a2, 8($sp)")
		print("lw $a3, 12($sp)")
		#load all variables in this function on stack
		# load $ti on stack
		for i, local in enumerate(localVariables[curFunc]):
			print("lw $t0, " + str((i*4)+108) + "($sp)")
			print("sw $t0, " + local)
		#load ti
		# restore $ti from  stack
		for textData in range(0,10):
			print("lw $t" + str(textData) + ", " + str(4*(4+textData)) + "($sp)")
		#load f0-f9 and f20
		# load $fi on stack
		for textData in range(10):
			print("lwc1 $f" + str(textData) + ", " + str(4*(14+textData)) + "($sp)")
		print("lwc1 $f20, 96($sp)")
		#load s0
		print("lw $s0, 100($sp)")
		#load ra
		print("lw $ra, 104($sp)")
		# pop	
		sz = (len(localVariables[curFunc])*4) + 108
		print("addi $sp, $sp, " + str(sz), end="")
		cnt = 0
	# refparam t0 or f0
	elif text[1] == "refparam":
		#t0
		if pass2func.checkword(text[2]):
			print("move "+pass2func.checker(variables, text[2])+", $v0", end="")
		#f0
		else:												
			print("mtc1 $v0, "+pass2func.checker(variables, text[2]), end="")
	
	elif text[1] == "param":
		if cnt != 0:	
			text2 = str(cnt*4)
		else:
			text2 = ""
			sz = (len(localVariables[curFunc])*4) + 108
			print("addi $sp, $sp, -" + str(sz))
		# push $ai on stack
		print("sw $a" + str(cnt) + ", " + text2 + "($sp)")			
		if pass2func.checkword(text[2]): #t0			
			print("move $a" + str(cnt) + ", " + pass2func.checker(variables, text[2]), end="")
		else: #f0		
			print("mfc1 $a" + str(cnt) + ", " + pass2func.checker(variables, text[2]), end="")
		cnt = cnt+1

	elif(text[1].startswith("if")):	
		a = text[1].split('(')[1]
		b = text[3].split(')')[0]
		# f0 < f1
		if pass2func.checkfloat(a) and pass2func.checkfloat(b):
			operator = {
				"==" : "c.eq.s",
				"!=" : "c.eq.s",
				"<" : "c.lt.s",
				"<=" : "c.le.s",
				">" : "c.lt.s",
				">=" : "c.le.s",
			}
			if text[2] in [">", ">="]:
				a,b = b,a
			# if $f2 operator $f4 then code = 1 else code = 0
			print(operator.get(text[2]) + " " + pass2func.checker(variables, a) + ", " + pass2func.checker(variables, b))
			if text[2]=="!=":
				print("bc1f L" + text[-1], end="")
			else:
				print("bc1t L" + text[-1], end="")
		else:			
			# t0<t1
			operator = {
				"==" : "beqz",
				"!=" : "bnez",
				"<" : "bltz",
				"<=" : "blez",
				">" : "bgtz",
				">=" : "bgez",
			}
			if(b[0].isdigit()):
				print("li $s0, " + b)
				print("sub $s0, " + pass2func.checker(variables,a) + ", $s0")
			else:
				print("sub $s0, " + pass2func.checker(variables,a) + ", " + pass2func.checker(variables,b))
			print("     " + operator.get(text[2]) + " $s0, L" + text[-1], end="") 

	elif text[1].startswith("Load"):
		print("la $"+text[2]+", "+text[3], end="")

	elif text[1].startswith("print"):
		reg = text[1].split(')')[0].split('(')[1]
		print("addi $sp, $sp, -8")
		print("sw $a0, ($sp)")
		print("sw $v0, 4($sp)")
		if(pass2func.checkfloat(reg)):
			#float
			print("li $v0, 2 \nmov.s $f12, "+pass2func.checker(variables, reg)+" \nsyscall")
		else:
			#int
			print("li $v0, 1 \nmove $a0, "+pass2func.checker(variables, reg)+" \nsyscall")
		#newline
		print("li $v0, 4\nla $a0, newline\nsyscall")
		
		print("lw $a0, ($sp)")
		print("lw $v0, 4($sp)")
		print("addi $sp, $sp, 8", end="")

	else:
		if any('[' in textData for textData in text):
			text[1]=text[1]+text[2]+text[3]
			a,b = text[1].split('=')
			if text[1][-1]!=']':
				t1,t2 = a.split('[')
				t2 = t2.split(']')[0]
				if pass2func.checkword(b):
					print("add $"+ t1+", $"+t1+", $"+t2)
					print("sw $"+b+", ($"+t1+")", end="")
				else:
					print("add $"+ t1+", $"+t1+", $"+t2)
					print("s.s $"+b+", ($"+t1+")", end="")
			else:
				t1,t2 = b.split('[')
				t2 = t2.split(']')[0]
				if pass2func.checkword(a):		
					print("add $"+ t1+", $"+t1+", $"+t2)
					print("lw $"+a+", ($"+t1+")", end="")
				else:					
					print("add $"+ t1+", $"+t1+", $"+t2)
					print("l.s $"+a+", ($"+t1+")", end="")
		elif len(text) != 4:
			a = text[-5]
			b = text[-3]
			opt = text[-2]
			c = text[-1]
			operator = {
				"+" : "add",
				"-" : "sub",
				"*" : "mul",
			}
			textData = " "
			if pass2func.checkfloat(a) or pass2func.checkfloat(b):
				textData = ".s "
			if opt in ["+","-","*"]:
				print(operator.get(opt) + textData + pass2func.checker(variables,a) + ", " + pass2func.checker(variables,b) + ", " + pass2func.checker(variables,c), end="")
			else:
				if pass2func.checkfloat(a) or pass2func.checkfloat(b):
					# f0 = f1 / f2
					print("div.s " + pass2func.checker(variables, a) + ", " + pass2func.checker(variables, b) + ", " + pass2func.checker(variables, c))
				else:
					# t0 = t1 / t2
					print("div " + pass2func.checker(variables,b) + ", " + pass2func.checker(variables,c))
					if(opt == "%"):
						print("mfhi " + pass2func.checker(variables,a), end="")
					else:
						print("mflo " + pass2func.checker(variables,a), end="")
		else:
			a = text[-3]
			b = text[-1]
			if(b[0].isdigit() or b[0]=="-"):
				if pass2func.checkfloat(a) or pass2func.checkfloat(b):
					print("li.s " + pass2func.checker(variables,a) + ", " + b, end="")
				else:
					print("li " + pass2func.checker(variables,a) + ", " + b, end="")
			else:
				#int to float conversion
				if b.startswith('ConvertToFloat'):
					b = b.split('(')[1].split(')')[0]
					print("mtc1 " + pass2func.checker(variables, b) + ", " + pass2func.checker(variables, a))
					print("\tcvt.s.w " + pass2func.checker(variables, a) + ", " + pass2func.checker(variables, a), end="")
				#float to int conversion
				elif b.startswith('ConvertToInt'):
					b = b.split('(')[1].split(')')[0]
					print("cvt.w.s " + pass2func.checker(variables, b) + ", " + pass2func.checker(variables, b))
					print("\tmfc1 " + pass2func.checker(variables, a) + ", " + pass2func.checker(variables, b), end="")	
				elif a in variables:
					if pass2func.checkfloat(a) or pass2func.checkfloat(b):
						print("s.s " + pass2func.checker(variables,b) + ", " + pass2func.checker(variables,a), end="")
					else:
						print("sw " + pass2func.checker(variables,b) + ", " + pass2func.checker(variables,a), end="")
				else :
					if pass2func.checker(variables,b).startswith("$a"):
						if pass2func.checkfloat(a):
							print("mtc1 " + pass2func.checker(variables,b) + ", " + pass2func.checker(variables,a), end="")
						else:
							print("move " + pass2func.checker(variables,a) + ", " + pass2func.checker(variables,b), end="")
					elif pass2func.checker(variables,a).startswith("$a"):
						if pass2func.checkfloat(b):
							print("mfc1 " + pass2func.checker(variables,a) + ", " + pass2func.checker(variables,b), end="")
						else:
							print("move " + pass2func.checker(variables,a) + ", " + pass2func.checker(variables,b), end="")
					elif pass2func.checkfloat(a) and pass2func.checkfloat(b):
						# f0 = f1
						print("mov.s " + pass2func.checker(variables,a) + ", " + pass2func.checker(variables,b), end="")
					elif pass2func.checkfloat(a) or pass2func.checkfloat(b):
						# f0 = var
						print("l.s " + pass2func.checker(variables,a) + ", " + pass2func.checker(variables,b), end="") 
					else:
						if pass2func.checkword(a) and pass2func.checkword(b):
							# t0 = t1
							print("move " + pass2func.checker(variables,a) + ", " + pass2func.checker(variables,b), end="")
						else:
							# t0 = var
							print("lw " + pass2func.checker(variables,a) + ", " + pass2func.checker(variables,b), end="")
	print()

def checkfloat(val):
	if len(val) == 2 and val.startswith('f') and val[1].isdigit():
		return True
	if len(val.split('_'))==4:
		return True
	return False

def checkword(val):
	if len(val) == 2 and val.startswith('t') and val[1].isdigit():
		return True
	if len(val.split('_'))==4:
		return True
	return False

def checker(variables, val):
	if val in variables :
		return val
	if len(val.split('_')) in [3,4]:
		if len(val.split('_')) == 4:
			return "$a" + val.split('_')[-1]
		return val
	return "$"+val
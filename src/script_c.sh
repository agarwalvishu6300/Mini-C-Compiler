
if [ $# -ne 1  ]
then
	echo "Provide one argument with valid file name"
	exit 1
fi

if [ ! -f $1 ]
then
	echo "Invalid file name"
	exit 1
fi

#remove extension
fname=`echo "$1" | cut -f 1 -d '.'`
exten=`echo "$1" | cut -f 2 -d '.'`

#check if extension is .c
if [ ! $exten == "c" ]
then
	echo "extension must be .c"
	exit 1
fi

varFile="__variables.txt"
fname2=${fname}${varFile}

interFile="__interCode.txt"
fname3=${fname}${interFile}

asmFile="__asmCode.asm"
fname4=${fname}${asmFile}

bison -d --warning=none pass1bison.y
flex pass1lex.l
gcc -c -w lex.yy.c
gcc -c -w pass1bison.tab.c
gcc pass1bison.tab.o lex.yy.o -o ex

./ex $1 $fname3 $fname2

#remove all .tab files created
rm pass1bison.tab.c
rm pass1bison.tab.h
rm pass1bison.tab.o

#remove .yy files created
rm lex.yy.c
rm lex.yy.o

if [ $? -eq 139 ]; then
    echo "Compiler gives segmentation fault."
    rm $fname2 
    rm "ex"
    exit 1
fi

if [ -f "finResult.txt" ]
then

textRes=`cat "finResult.txt"`
if [ $textRes -eq "1" ]
then
	python3 pass2.py $fname2 $fname3> $fname4
	rm -rf __pycache__
	outp=`spim -file $fname4`
	finoutp=`echo "$outp" | tail -n+6`
	echo "Output :"
	echo "$finoutp"
fi
rm "finResult.txt"

else
	echo "Result file not made."
fi

rm $fname2
rm "ex"


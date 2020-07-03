# Mini-C-Compiler

This repository contains the code for a C-like compiler for a subset of C language that supports user defined classes, macros, function calls. It uses Flex for lexical analysis, Bison for syntax analysis, sematic analysis and intermediate code generation for the first pass. MIPS code is then generated from intermediate code in second pass.

Steps to run the code:
- Open terminal in the src folder and run "./script_c.sh <file_name>"
- If the code has error, syntax and semantic errors will be printed in the terminal.
- Else the Intermediate Code and MIPS Assembly Code is generated and stored(in the same folder where the input file is located) and the MIPS Code is simulated on SPIM simulator.
- The output is displayed on the terminal.


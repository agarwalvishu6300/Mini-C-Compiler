%{
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define mx 1000	

extern FILE * yyin;
extern int total_lines;

void yyerror(char *s);

int scope_change,arr_break_cnt[10],arr_break[10][20],printer_len=1,all_sizes[100],cnt_allvar=0,idx_func_call,cur_idx_func=0,scope_global=0,cnt_break=0;
char all_vars[100][100],all_type[100][100];
bool register_int[10],register_float[10],success=true;
FILE*fp,*fil;
struct details_variable
{
	int cnt_size,size_mod[100],scope,size_dim[100];
	char variable_name[100],variable_type[100],name_fin[100];
	bool if_arr,tag;
};
struct details_function
{
	struct details_variable list_variable[100],list_param[100];
	int cnt_var,cnt_param;
	char type[100],name_func[100];
};
struct details_function functable[1000];

int newtemp();
int string_to_int(char*s);
int is_pres_arr(struct details_variable array[],int size,char finder[]);
bool is_pres_var (struct details_variable array[],int size,char finder[],int scope);
void disp_func(struct details_function a);
void disp_all_func();
void disp_variables(struct details_variable a);
void releasetemp(int i);

%}

%start	START

%token SELECT PRINT INT FLT ID
%token SC SP COMMA COLON
%token EQ OR AND NOT
%token LT LTE GT GTE EQUATE NEQ
%token PLUS MINUS MULT DIV MOD
%token OPENPARA CLOSEPARA OPENCURL CLOSECURL
%token IF ELSE WORD_FOR WORD_WHILE VOID RET WORD_SWITCH CASET BREAK DEFAULT
%token CLOSESQR OPENSQR NUM DOL

%union
{
	struct attributes{
		int array,index,counter,cnt_or,cnt_and,list_quad[1000],list_quad1[1000],cnt_quad,cnt_quad1,cur_register,quad,quad_beg;
		char text[1000],type[1000];
		bool if_case,isarray;
	} attr;
};

%type<attr> F START INP FUNC_DECL FUNC_HEAD BODY R_ID OPENPARA DECLISTE CLOSEPARA RESULT  INT FLT VOID DECLIST COMMA DEC TYPE OPENCURL INSTRUCTIONS CLOSECURL MSLIST COMPSTMT VAR_DECL ASSIGN IFELSE FOR WHILE SCOPEINC FUNC_CALL SC RETURN SWITCH RET OR_COND PARAMLIST PLIST WHILE_HEAD WORD_WHILE MWHILE FOREXP WORD_FOR MFOR NFOR FORASSIGN IFEXP NIF MIF ELSE L IDS ARRS ARR ID BRLIST OPENSQR CLOSESQR NUM EQ AND_COND OR AND NOT_COND NOT COMP_EQUAL LT LTE GT GTE NEQ EQUATE EXPR PLUS MINUS TERM MULT DIV MOD WORD_SWITCH CASES CASELIST MCASE DEFAULTE DEFAULT COLON CASE CASET NCASE IDTEMP SWITCHET CASETEMP FORBACK1 FORBACK2 CBODY ARRFUNC LISTFUNC CMARK ARRF ARRFLIST INPUTGLOBAL GLIST MGL NGL DOL
%%

START : NGL INP
		| MGL GLIST NGL INP
;

NGL :
	{	cur_idx_func=1;	}
;

MGL:
	{
		strcpy(functable[0].type,"int");
		strcpy(functable[0].name_func,"global");
	}
;

GLIST 	: DOL VAR_DECL
		| GLIST DOL VAR_DECL
;

INP 	: FUNC_DECL 
		| FUNC_DECL INP
;

FUNC_DECL 	: error SC  { yyerrok;}
	| FUNC_HEAD BODY
	{
		char file_text[mx];
		scope_global=0;
		cur_idx_func++; 
		fix_print($2.list_quad,$2.cnt_quad,printer_len);
		snprintf(file_text,mx-1,"func end");
		file_printer(file_text);			 
	}
;

FUNC_HEAD : R_ID OPENPARA DECLISTE CLOSEPARA 
	{	scope_global++;	}
;

R_ID: 	RESULT ID
	{ 
		scope_global++;
		functable[cur_idx_func].cnt_var=0;
		functable[cur_idx_func].cnt_param=0;
		strcpy(functable[cur_idx_func].name_func,$2.text);
		char file_text[mx];
		snprintf(file_text,mx-1,"func begin %s",$2.text);
		file_printer(file_text);
	}
;

RESULT 	: VOID 	{strcpy(functable[cur_idx_func].type,"void");}
		| INT 	{strcpy(functable[cur_idx_func].type,"int");}
		| FLT 	{strcpy(functable[cur_idx_func].type,"float");}
;

DECLISTE: DECLIST
		| 
;

DECLIST : DEC
		| DECLIST COMMA DEC
;

DEC : TYPE ARRFUNC
	{
		int finder;
		finder = is_pres_arr(functable[cur_idx_func].list_param,functable[cur_idx_func].cnt_param,$2.text); 
		if(finder==-1){
			struct details_variable new_record;
			strcpy(new_record.variable_type,$1.type);
			strcpy(new_record.variable_name,$2.text);	
			new_record.scope = scope_global;
			new_record.if_arr = true;
			new_record.cnt_size = $2.counter;
			new_record.tag=false;
			char name_fin[mx];
			snprintf(name_fin,mx-1,"%s_%d_%s_%d",new_record.variable_name,scope_global,functable[cur_idx_func].name_func,functable[cur_idx_func].cnt_param);
			strcpy(new_record.name_fin,name_fin);
			functable[cur_idx_func].list_param[functable[cur_idx_func].cnt_param++]=new_record;
		}
		else{
			char file_text[mx];
			snprintf(file_text,mx-1,"Parameter with name %s already declared.",$2.text);
			disp_errors(file_text);
		}	
	}	
	| TYPE ID
	{
		int finder;
		finder = is_pres_arr(functable[cur_idx_func].list_param,functable[cur_idx_func].cnt_param,$2.text); 
		if(finder==-1){
			struct details_variable new_record;
			strcpy(new_record.variable_type,$1.type);
			strcpy(new_record.variable_name,$2.text);
			new_record.scope = scope_global;
			new_record.if_arr = false;
			new_record.cnt_size = 0;
			new_record.tag=false;
			char name_fin[mx];
			snprintf(name_fin,mx-1,"%s_%d_%s_%d",new_record.variable_name,scope_global,functable[cur_idx_func].name_func,functable[cur_idx_func].cnt_param);
			strcpy(new_record.name_fin,name_fin);
			functable[cur_idx_func].list_param[functable[cur_idx_func].cnt_param++]=new_record;
		}
		else{
			char file_text[mx];
			snprintf(file_text,mx-1,"Parameter with name %s already declared.",$2.text);
			disp_errors(file_text);
		}				
	}
;

ARRFUNC : ID LISTFUNC
	{
		$$.counter=$2.counter;
		strcpy($$.text,$1.text);
	}
;

LISTFUNC 	: LISTFUNC OPENSQR CLOSESQR 	{$$.counter=$1.counter+1;}
			| OPENSQR CLOSESQR     		{$$.counter=1;}
;

BODY: 	OPENCURL INSTRUCTIONS CLOSECURL
	{
		int i,counter=0;
		for(i=functable[cur_idx_func].cnt_var-1;i>=0;i--){
			if(functable[cur_idx_func].list_variable[i].scope==scope_global) counter++;
		}
		$$.cnt_quad=0;
		scope_global--;
		functable[cur_idx_func].cnt_var -= counter;
		for(i=0;i<$2.cnt_quad;i++){
			$$.list_quad[$$.cnt_quad++]=$2.list_quad[i];
		}
	}
;

INSTRUCTIONS 	: 	INSTRUCTIONS MSLIST COMPSTMT
	{
		fix_print($1.list_quad,$1.cnt_quad,$2.quad);
		$$.cnt_quad=0;
		for(int i=0;i<$3.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$3.list_quad[i];
	}
	| COMPSTMT
	{
		$$.cnt_quad=0;
		for(int i=0;i<$1.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
	}
;

MSLIST : {$$.quad=printer_len;};

COMPSTMT 	: 	error SC { yyerrok;}

	| VAR_DECL {}

	| ASSIGN {}

	| IFELSE
	{
		$$.cnt_quad=0;
		int i;
		for( i=0;i<$1.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
 	}
	| FOR
	{
		$$.cnt_quad=0;
		int i;
		for(i=0;i<arr_break_cnt[cnt_break];i++) $$.list_quad[$$.cnt_quad++]=arr_break[cnt_break][i];
		arr_break_cnt[cnt_break]=0;
		cnt_break--;
		for( i=0;i<$1.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
	}
	| SWITCH
	{
		$$.cnt_quad=0;
		int i;
		for(i=0;i<arr_break_cnt[cnt_break];i++) $$.list_quad[$$.cnt_quad++]=arr_break[cnt_break][i];
		arr_break_cnt[cnt_break]=0;
		cnt_break--;
		for(i=0;i<$1.cnt_quad;i++){
			$$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
		}
		free_intreg(scope_change);
 	}
	| WHILE
	{
		$$.cnt_quad=0;
		int i;
		for(i=0;i<arr_break_cnt[cnt_break];i++) $$.list_quad[$$.cnt_quad++]=arr_break[cnt_break][i];
		arr_break_cnt[cnt_break]=0;
		cnt_break--;
		for( i=0;i<$1.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
	}
	| SCOPEINC BODY
	{
		$$.cnt_quad=0;
		int i;
		for( i=0;i<$2.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$2.list_quad[i];
	}
	| FUNC_CALL SC {}

	| RETURN SC{}	
	| BREAK SC
	{
		if(cnt_break==0) disp_errors("Break can only occur within switch or loops.");
		char file_text[mx];
		snprintf(file_text,mx-1,"goto _____");
		arr_break[cnt_break][arr_break_cnt[cnt_break]++]=printer_len;
		file_printer(file_text);
	}
	| PRINT OPENPARA OR_COND CLOSEPARA SC
	{
		char file_text[mx];
		fix_print($3.list_quad,$3.cnt_quad,printer_len);
		if(!strcmp($3.type,"int")){
			snprintf(file_text,mx-1,"print(t%d)",$3.cur_register); 
			file_printer(file_text);
			free_intreg($3.cur_register);
		}
		else if(!strcmp($3.type,"float")){
			snprintf(file_text,mx-1,"print(f%d)",$3.cur_register); 
			file_printer(file_text);
			free_floatreg($3.cur_register);
		}
		else if(!strcmp($3.type,"errortype")) disp_errors("Some error while calling print.");
	}
; 

SCOPEINC :  {scope_global++;}
;

RETURN 	: 	RET
	{
		if(strcmp(functable[cur_idx_func].type,"void")) disp_warnings("No return value in non-void function.");
		char file_text[mx];
		snprintf(file_text,mx-1,"return");
		file_printer(file_text);
	}
	| 	RET OR_COND
	{
		if(!strcmp(functable[cur_idx_func].type,"void")) disp_warnings("Return value in a void function.");
		fix_print($2.list_quad,$2.cnt_quad,printer_len);
		char file_text[mx];
		if(!strcmp(functable[cur_idx_func].type,"float")){
			int temp2=$2.cur_register;
			if(!strcmp($2.type,"int")){
				temp2=allot_floatreg();
				snprintf(file_text,mx-1,"f%d = ConvertToFloat(t%d)",temp2,$2.cur_register);
				free_intreg($2.cur_register);
				file_printer(file_text);
			}
			snprintf(file_text,mx-1,"return f%d",temp2);
			file_printer(file_text);
			free_floatreg(temp2);
			
		}
		else{
			int temp2=$2.cur_register;
			if(!strcmp($2.type,"float")){
				temp2=allot_intreg();
				snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp2,$2.cur_register);
				free_floatreg($2.cur_register);
				file_printer(file_text);
			}
			snprintf(file_text,mx-1,"return t%d",temp2);
			file_printer(file_text);
			free_intreg(temp2);
		}
	}
;

FUNC_CALL 	: 	IDTEMP OPENPARA PARAMLIST CLOSEPARA
	{
		if(idx_func_call!=-1 && functable[idx_func_call].cnt_param!=$3.counter){
			disp_errors("Number of parameters not matching.");
			strcpy($$.type,"errortype");
		}
		else if(idx_func_call!=-1) strcpy($$.type,functable[idx_func_call].type);
		else strcpy($$.type,"errortype");
		char file_text[mx];
		snprintf(file_text,mx-1,"call %s,%d",$1.text,$3.counter+1);
		file_printer(file_text);
		int temp_idx;
		if(idx_func_call!=-1){
			if(!strcmp(functable[idx_func_call].type,"int")){	
				temp_idx=allot_intreg();
				snprintf(file_text,mx-1,"refparam t%d",temp_idx);
				file_printer(file_text);
			}
			else if(!strcmp(functable[idx_func_call].type,"float")){
				temp_idx=allot_floatreg();
				snprintf(file_text,mx-1,"refparam f%d",temp_idx);
				file_printer(file_text);
			}
			else temp_idx=-1;
			$$.cur_register=temp_idx;
		}
	}
;

IDTEMP 	: 	ID
	{
		int i=0,get=-1;
		for(i=0;i<cur_idx_func+1;i++){
			if(!strcmp(functable[i].name_func,$1.text)){
					get=i;
					break;
			}
		}
		if(get==-1){
			disp_errors("No such function exists.");
			idx_func_call=-1;
		}
		else idx_func_call = get;
		strcpy($$.text,$1.text);
	}
;

PARAMLIST 	: 	PLIST 	{ $$.counter = $1.counter;}
			|			{$$.counter = 0;} 
;

PLIST 	: 	PLIST COMMA OR_COND
	{
		$$.counter++;
		fix_print($3.list_quad,$3.cnt_quad,printer_len);
		char checktype[100];
		if(idx_func_call!=-1) strcpy(checktype,functable[idx_func_call].list_param[$$.counter-1].variable_type);
		else strcpy(checktype,"errortype");
		char file_text[mx];
		if(!strcmp($3.type,"int"))
		{
			if(!strcmp(checktype,"float"))
			{
				int temp_idx = allot_floatreg();
				snprintf(file_text,mx-1,"f%d = ConvertToFloat(t%d)",temp_idx,$3.cur_register);
				file_printer(file_text);
				free_intreg($3.cur_register);
				snprintf(file_text,mx-1,"param f%d",temp_idx);
				free_floatreg(temp_idx);
			}
			else
			{
				snprintf(file_text,mx-1,"param t%d",$3.cur_register);
				free_intreg($3.cur_register);
			}
		}
		if(!strcmp($3.type,"float"))
		{
			if(!strcmp(checktype,"int"))
			{
				int temp_idx = allot_intreg();
				snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp_idx,$3.cur_register);
				file_printer(file_text);
				free_floatreg($3.cur_register);
				snprintf(file_text,mx-1,"param t%d",temp_idx);
				free_intreg(temp_idx);
			}
			else
			{
				snprintf(file_text,mx-1,"param f%d",$3.cur_register);
				free_floatreg($3.cur_register);
			}	
		}
		file_printer(file_text);
	}
	| 	OR_COND
	{
		$$.counter=1;
		fix_print($1.list_quad,$1.cnt_quad,printer_len);
		char checktype[100];
		if(idx_func_call!=-1) strcpy(checktype,functable[idx_func_call].list_param[$$.counter-1].variable_type);
		else strcpy(checktype,"errortype");
		char file_text[mx];
		if(!strcmp($1.type,"int"))
		{
			if(!strcmp(checktype,"float"))
			{
				int temp_idx = allot_floatreg();
				snprintf(file_text,mx-1,"f%d = ConvertToFloat(t%d)",temp_idx,$1.cur_register);
				file_printer(file_text);
				free_intreg($1.cur_register);
				snprintf(file_text,mx-1,"param f%d",temp_idx);
				free_floatreg(temp_idx);
			}
			else
			{
				snprintf(file_text,mx-1,"param t%d",$1.cur_register);
				free_intreg($1.cur_register);
			}
		}
		if(!strcmp($1.type,"float"))
		{
			if(!strcmp(checktype,"int"))
			{
				int temp_idx = allot_intreg();
				snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp_idx,$1.cur_register);
				file_printer(file_text);
				free_floatreg($1.cur_register);
				snprintf(file_text,mx-1,"param t%d",temp_idx);
				free_intreg(temp_idx);
			}
			else
			{
				snprintf(file_text,mx-1,"param f%d",$1.cur_register);
				free_floatreg($1.cur_register);
			}	
		}
		file_printer(file_text);
	}
;

WHILE 	: 	WHILE_HEAD BODY
	{
								
		char file_text[mx];
		snprintf(file_text,mx-1,"goto %d",$1.quad_beg);
		file_printer(file_text);
		fix_print($2.list_quad,$2.cnt_quad,$1.quad_beg);
		$$.cnt_quad=0;
		int i;
		for(i=0;i<$1.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
	}
;

WHILE_HEAD : 	WORD_WHILE MWHILE OPENPARA OR_COND CLOSEPARA
	{ 
		fix_print($4.list_quad,$4.cnt_quad,printer_len);
		int temp2=$4.cur_register;
		char file_text[mx];
		if(!strcmp($4.type,"float")){
			temp2=allot_intreg();
			snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp2,$4.cur_register);
			free_floatreg($4.cur_register);
			file_printer(file_text);
		}
		snprintf(file_text,mx-1,"if(t%d == 0) goto _____",temp2);
		$$.cnt_quad=0;
		$$.list_quad[$$.cnt_quad++]=printer_len;
		file_printer(file_text);
		free_intreg(temp2);
		$$.quad_beg=$2.quad;
		scope_global++; cnt_break++;
	}
;

MWHILE 	:  	{ $$.quad=printer_len;} 
;


FOR : 	FOREXP BODY
	{		
		char file_text[mx];
		snprintf(file_text,mx-1,"goto _____");
		$2.list_quad[$2.cnt_quad++]=printer_len;
		file_printer(file_text);
		fix_print($2.list_quad,$2.cnt_quad,$1.quad);
		$$.cnt_quad=0;
		int i;
		for(i=0;i<$1.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
	}
;

FOREXP 	: 	FORBACK1 FORBACK2
	{
		scope_global++;cnt_break++;
		$$.quad=$2.quad;
		char file_text[mx];
		snprintf(file_text,mx-1,"goto %d",$1.quad);
		file_printer(file_text);
		fix_print($1.list_quad1,$1.cnt_quad1,printer_len);
		$$.cnt_quad=0;
		int i;
		for(i=0;i<$1.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
	}
;

FORBACK1 	: 	WORD_FOR OPENPARA ASSIGN MFOR OR_COND SC
	{
		fix_print($5.list_quad,$5.cnt_quad,printer_len);
		int temp2=$5.cur_register;
		char file_text[mx];
		if(!strcmp($5.type,"float"))
		{
			temp2=allot_intreg();
			snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp2,$5.cur_register);
			free_floatreg($5.cur_register);
			file_printer(file_text);
		}
		snprintf(file_text,mx-1,"if(t%d == 0) goto _____",temp2);
		$$.cnt_quad=0;
		$$.list_quad[$$.cnt_quad++]=printer_len;
		file_printer(file_text);
		free_intreg(temp2);
		$$.cnt_quad1=0;
		$$.list_quad1[$$.cnt_quad1++]=printer_len;
		snprintf(file_text,mx-1,"goto _____");
		file_printer(file_text);
		$$.quad=$4.quad;
	}
;

FORBACK2	: 	NFOR FORASSIGN CLOSEPARA 	{ $$.quad=$1.quad;}
;

MFOR 		: 	{ $$.quad=printer_len;}
;

NFOR 	: 	{$$.quad=printer_len;}
;

IFELSE 	: 	IFEXP BODY
	{
		int i;
		$$.cnt_quad=0;
		for(i=0;i<$1.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
		for(i=0;i<$2.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$2.list_quad[i];
	}
	| 	IFEXP BODY NIF ELSE MIF BODY
	{ 
		fix_print($1.list_quad,$1.cnt_quad,$5.quad);
		$$.cnt_quad=0;
		int i;
		for(i=0;i<$2.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$2.list_quad[i];
		for(i=0;i<$3.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$3.list_quad[i];
		for(i=0;i<$6.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$6.list_quad[i];
	}
;

NIF 	: 	
	{
		char file_text[mx];
		snprintf(file_text,mx-1,"goto _____");
		$$.cnt_quad=0;
		$$.list_quad[$$.cnt_quad++]=printer_len;
		file_printer(file_text);
	}
;

MIF 	:	{$$.quad=printer_len;scope_global++;}
;

IFEXP 	: 	IF OPENPARA OR_COND CLOSEPARA 
	{ 
		fix_print($3.list_quad,$3.cnt_quad,printer_len);
		char file_text[mx];
		scope_global ++;
		int temp2=$3.cur_register;
		if(!strcmp($3.type,"float")){
			temp2=allot_intreg();
			snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp2,$3.cur_register);
			free_floatreg($3.cur_register);
			file_printer(file_text);
		}
		snprintf(file_text,mx-1,"if(t%d == 0) goto _____",temp2);
		$$.cnt_quad=0;
		$$.list_quad[$$.cnt_quad++]=printer_len;
		file_printer(file_text);
		free_intreg(temp2);
	}
;

VAR_DECL 	: 	TYPE L SC
	{
		int i;
		int ct = 1;
		for(i=0;i<functable[cur_idx_func].cnt_var;i++){
			if(!strcmp(functable[cur_idx_func].list_variable[i].variable_type,"-1")){
				strcpy(functable[cur_idx_func].list_variable[i].variable_type,$1.type);
				strcpy(all_type[cnt_allvar-ct],$1.type);
				ct--;
			}
		}
	}
;

TYPE 	: INT  	{strcpy($$.type,"int");}
		| FLT  	{strcpy($$.type,"float");}
;
L 	: L COMMA IDS
	| IDS   
	| L COMMA ARRS
	| ARRS            
;

ARRS : ARR
;

ARR : 	ID BRLIST
	{
		int finder,checker;
		checker = is_pres_arr(functable[cur_idx_func].list_variable,functable[cur_idx_func].cnt_var,$1.text);
		finder = is_pres_arr(functable[cur_idx_func].list_param,functable[cur_idx_func].cnt_param,$1.text);
		if(finder!=-1 && scope_global==2)
		{
			char file_text[mx];
			snprintf(file_text,mx-1,"Parameter with name %s already exists",$1.text);
			disp_errors(file_text);
		}
		else if(checker!=-1 && functable[cur_idx_func].list_variable[checker].scope==scope_global)
		{
			char file_text[mx];
			snprintf(file_text,mx-1,"Variable with name %s already exists in the current scope.",$1.text);
			disp_errors(file_text);
		}
		else
		{
			functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].if_arr=true;
			functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].scope=scope_global;
			functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].tag=true;
			strcpy(functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].variable_name,$1.text);
			strcpy(functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].variable_type,"-1");
			char name_fin[mx];
			snprintf(name_fin,mx-1,"%s_%d_%s",$1.text,scope_global,functable[cur_idx_func].name_func);
			strcpy(all_vars[cnt_allvar],name_fin);
			strcpy(all_type[cnt_allvar],functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].variable_type);
			int store = functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].cnt_size;
			functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].size_mod[store-1]=1;
			for(int j=store-2;j>=0;j--) functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].size_mod[j] = functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].size_mod[j+1] * functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].size_dim[j+1];
			int prod=1,i=0;
			for(i=0;i<functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].cnt_size;i++) prod *= functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].size_dim[i];
			all_sizes[cnt_allvar]=prod;
			cnt_allvar++;
			strcpy(functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].name_fin,name_fin);
			functable[cur_idx_func].cnt_var++;
		}	
	}
;

BRLIST 	: 	BRLIST OPENSQR NUM CLOSESQR
	{
		int i=0,t = strlen($3.text);
		bool isf=false;
		bool isn = ($3.text[0]=='-');
		for(i=0;i<t;i++){
			if($3.text[i]=='.'){
				isf=true;
				break;
			}
		}
		
		if(isf) disp_errors("Array dimensions should be an integer");
		if(isn) disp_errors("Array dimensions should be an positive integer");
		functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].size_dim[functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].cnt_size++]=string_to_int($3.text);
	}
	| 	OPENSQR NUM CLOSESQR
	{
		int i=0,t = strlen($2.text);
		bool isn = ($2.text[0]=='-');
		bool isf=false;
		for(i=0;i<t;i++){
			if($2.text[i]=='.'){
				isf=true;
				break;
			}
		}
		if(isn) disp_errors("Array dimensions should be an positive integer");
		if(isf) disp_errors("Array dimensions should be an integer");
		functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].cnt_size=1;
		functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var].size_dim[0]=string_to_int($2.text);
	}
;

IDS : 	ID
	{
		int finder,checker;
		checker = is_pres_arr(functable[cur_idx_func].list_variable,functable[cur_idx_func].cnt_var,$1.text);
		finder = is_pres_arr(functable[cur_idx_func].list_param,functable[cur_idx_func].cnt_param,$1.text); 
		if(finder!=-1 && scope_global==2){
			char file_text[mx];
			snprintf(file_text,mx-1,"Parameter with name %s already exists",$1.text);
			disp_errors(file_text);
		}
		else if(checker!=-1 && functable[cur_idx_func].list_variable[checker].scope==scope_global){
			char file_text[mx];
			snprintf(file_text,mx-1,"Variable with name %s already exists in the current scope.",$1.text);
			disp_errors(file_text);
		}
		else{
			struct details_variable new_record;
			strcpy(new_record.variable_type,"-1");
			strcpy(new_record.variable_name,$1.text);
			new_record.if_arr = false;
			new_record.scope = scope_global;
			new_record.tag=true;
			new_record.cnt_size = 0;
			char name_fin[mx];
			snprintf(name_fin,mx-1,"%s_%d_%s",new_record.variable_name,scope_global,functable[cur_idx_func].name_func);
			strcpy(all_vars[cnt_allvar],name_fin);
			strcpy(all_type[cnt_allvar],new_record.variable_type);
			all_sizes[cnt_allvar]=0;
			cnt_allvar++;
			strcpy(new_record.name_fin,name_fin);
			functable[cur_idx_func].list_variable[functable[cur_idx_func].cnt_var++]=new_record;
		}
	}
;

FORASSIGN 	: 	ID EQ OR_COND
	{
		fix_print($3.list_quad,$3.cnt_quad,printer_len);
		int finder,checker,gchecker;
		finder = is_pres_arr(functable[cur_idx_func].list_param,functable[cur_idx_func].cnt_param,$1.text); 
		gchecker = is_pres_arr(functable[0].list_variable,functable[0].cnt_var,$1.text);
		checker = is_pres_arr(functable[cur_idx_func].list_variable,functable[cur_idx_func].cnt_var,$1.text);
		if(checker==-1 && finder==-1 && gchecker==-1){
			char file_text[mx];
			snprintf(file_text,mx-1,"No such variable called %s exists",$1.text);
			disp_errors(file_text);
		}
		if(gchecker!=-1) strcpy($1.type,functable[0].list_variable[gchecker].variable_type);					
		else if (finder!=-1) strcpy($1.type,functable[cur_idx_func].list_param[finder].variable_type);	
		else if(checker!=-1) strcpy($1.type,functable[cur_idx_func].list_variable[checker].variable_type);	

		if($3.cur_register==-2) disp_errors("Some error in assignment.");
		else if($3.cur_register==-1) disp_errors("Void function does not return anything.");
		else
		{
			char file_text[mx];
			if(!strcmp($3.type,"float")){
				if(strcmp($1.type,"float")){
					int temp_idx=allot_intreg();
					snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp_idx,$3.cur_register);
					file_printer(file_text);
					free_floatreg($3.cur_register);
					if(checker!=-1) snprintf(file_text,mx-1,"%s = t%d",functable[cur_idx_func].list_variable[checker].name_fin,temp_idx);	
					else if(finder!=-1) snprintf(file_text,mx-1,"%s = t%d",functable[cur_idx_func].list_param[finder].name_fin,temp_idx);	
					else snprintf(file_text,mx-1,"%s = t%d",functable[0].list_variable[gchecker].name_fin,temp_idx);
					free_intreg(temp_idx);
				}
				else{
					if(checker!=-1) snprintf(file_text,mx-1,"%s = f%d",functable[cur_idx_func].list_variable[checker].name_fin,$3.cur_register);	
					else if(finder!=-1) snprintf(file_text,mx-1,"%s = f%d",functable[cur_idx_func].list_param[finder].name_fin,$3.cur_register);	
					else snprintf(file_text,mx-1,"%s = f%d",functable[0].list_variable[gchecker].name_fin,$3.cur_register);
					free_floatreg($3.cur_register);
				}										
			}
			if(!strcmp($3.type,"int")){
				if(strcmp($1.type,"int")){
					int temp_idx=allot_floatreg();
					snprintf(file_text,mx-1,"f%d = ConvertToFloat(t%d)",temp_idx,$3.cur_register);
					file_printer(file_text);
					free_intreg($3.cur_register);
					if(checker!=-1) snprintf(file_text,mx-1,"%s = f%d",functable[cur_idx_func].list_variable[checker].name_fin,temp_idx);									
					else if(finder!=-1) snprintf(file_text,mx-1,"%s = f%d",functable[cur_idx_func].list_param[finder].name_fin,temp_idx);									
					else snprintf(file_text,mx-1,"%s = f%d",functable[0].list_variable[gchecker].name_fin,temp_idx);
					free_floatreg(temp_idx);
				}
				else{
					if(checker!=-1) snprintf(file_text,mx-1,"%s = t%d",functable[cur_idx_func].list_variable[checker].name_fin,$3.cur_register);									
					else if(finder!=-1) snprintf(file_text,mx-1,"%s = t%d",functable[cur_idx_func].list_param[finder].name_fin,$3.cur_register);
					else snprintf(file_text,mx-1,"%s = t%d",functable[0].list_variable[gchecker].name_fin,$3.cur_register);
					free_intreg($3.cur_register);
				}
			}
			
			file_printer(file_text);
		}
	}
	| 	ARRF EQ OR_COND
	{
		fix_print($3.list_quad,$3.cnt_quad,printer_len);
		if($1.array!=-1 && $1.index!=-1){
			if($3.cur_register==-1) disp_errors("Void function does not return anything.");
			else if($3.cur_register==-2) disp_errors("Some error in assignment.");
			else
			{
				char file_text[mx];
				if(!strcmp($3.type,"int")){
					if(!strcmp($1.type,"int")){
						snprintf(file_text,mx-1,"t%d[t%d] = t%d",$1.array,$1.index,$3.cur_register);
						free_intreg($3.cur_register);
					}
					else{
						int temp_idx=allot_floatreg();
						snprintf(file_text,mx-1,"f%d = ConvertToFloat(t%d)",temp_idx,$3.cur_register);
						file_printer(file_text);
						free_intreg($3.cur_register);
						snprintf(file_text,mx-1,"t%d[t%d] = f%d",$1.array,$1.index,temp_idx);
						free_floatreg(temp_idx);
					}
				}
				if(!strcmp($3.type,"float")){
					if(!strcmp($1.type,"float")){
						snprintf(file_text,mx-1,"t%d[t%d] = f%d",$1.array,$1.index,$3.cur_register);
						free_floatreg($3.cur_register);
					}
					else{
						int temp_idx=allot_intreg();
						snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp_idx,$3.cur_register);
						file_printer(file_text);
						free_floatreg($3.cur_register);
						snprintf(file_text,mx-1,"t%d[t%d] = t%d",$1.array,$1.index,temp_idx);
						free_intreg(temp_idx);
					}										
				}
				file_printer(file_text);
				free_intreg($1.array);
				free_intreg($1.index);
			}
		}
	}
;

ASSIGN 	: 	ID EQ OR_COND SC
	{
		fix_print($3.list_quad,$3.cnt_quad,printer_len);
		int finder,checker,gchecker;
		checker = is_pres_arr(functable[cur_idx_func].list_variable,functable[cur_idx_func].cnt_var,$1.text);
		gchecker = is_pres_arr(functable[0].list_variable,functable[0].cnt_var,$1.text);
		finder = is_pres_arr(functable[cur_idx_func].list_param,functable[cur_idx_func].cnt_param,$1.text); 
		if(checker==-1 && finder==-1 && gchecker==-1){
			char file_text[mx];
			snprintf(file_text,mx-1,"No such variable called %s exists",$1.text);
			disp_errors(file_text);
		}
		if (finder!=-1) strcpy($1.type,functable[cur_idx_func].list_param[finder].variable_type);		
		else if(gchecker!=-1) strcpy($1.type,functable[0].list_variable[gchecker].variable_type);	
		else if(checker!=-1) strcpy($1.type,functable[cur_idx_func].list_variable[checker].variable_type);
		if ($3.cur_register!=-1&&$3.cur_register!=-2){
			char file_text[mx];
			if(!strcmp($3.type,"int")){
				if(!strcmp($1.type,"int")){
					if(checker!=-1) snprintf(file_text,mx-1,"%s = t%d",functable[cur_idx_func].list_variable[checker].name_fin,$3.cur_register);
					else if(finder!=-1) snprintf(file_text,mx-1,"%s = t%d",functable[cur_idx_func].list_param[finder].name_fin,$3.cur_register);
					else snprintf(file_text,mx-1,"%s = t%d",functable[0].list_variable[gchecker].name_fin,$3.cur_register);
					free_intreg($3.cur_register);
				}
				else{
					int temp_idx=allot_floatreg();
					snprintf(file_text,mx-1,"f%d = ConvertToFloat(t%d)",temp_idx,$3.cur_register);
					file_printer(file_text);
					free_intreg($3.cur_register);
					if(checker!=-1) snprintf(file_text,mx-1,"%s = f%d",functable[cur_idx_func].list_variable[checker].name_fin,temp_idx);
					else if(finder!=-1) snprintf(file_text,mx-1,"%s = f%d",functable[cur_idx_func].list_param[finder].name_fin,temp_idx);	
					else snprintf(file_text,mx-1,"%s = f%d",functable[0].list_variable[gchecker].name_fin,temp_idx);
					free_floatreg(temp_idx);
				}
			}
			if(!strcmp($3.type,"float")){
				if(!strcmp($1.type,"float")){
					if(checker!=-1) snprintf(file_text,mx-1,"%s = f%d",functable[cur_idx_func].list_variable[checker].name_fin,$3.cur_register);
					else if(finder!=-1) snprintf(file_text,mx-1,"%s = f%d",functable[cur_idx_func].list_param[finder].name_fin,$3.cur_register);
					else snprintf(file_text,mx-1,"%s = f%d",functable[0].list_variable[gchecker].name_fin,$3.cur_register);
					free_floatreg($3.cur_register);
				}
				else{
					int temp_idx=allot_intreg();
					snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp_idx,$3.cur_register);
					file_printer(file_text);
					free_floatreg($3.cur_register);
					if(checker!=-1) snprintf(file_text,mx-1,"%s = t%d",functable[cur_idx_func].list_variable[checker].name_fin,temp_idx);
					else if(finder!=-1) snprintf(file_text,mx-1,"%s = t%d",functable[cur_idx_func].list_param[finder].name_fin,temp_idx);	
					else snprintf(file_text,mx-1,"%s = t%d",functable[0].list_variable[gchecker].name_fin,temp_idx);
					free_intreg(temp_idx);
				}										
			}
			file_printer(file_text);
		}
		else{	
			if($3.cur_register==-2) disp_errors("Some error in assignment.");
			else if($3.cur_register==-1) disp_errors("Void function does not return anything.");
		}
	}
	| 	ARRF EQ OR_COND SC
	{
		fix_print($3.list_quad,$3.cnt_quad,printer_len);
		if($1.array!=-1 && $1.index!=-1){
			if($3.cur_register==-2) disp_errors("Some error in assignment.");
			else if($3.cur_register==-1) disp_errors("Void function does not return anything.");
			else{
				char file_text[mx];
				if(!strcmp($3.type,"float")){
					if(strcmp($1.type,"float")){
						int temp_idx=allot_intreg();
						snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp_idx,$3.cur_register);
						file_printer(file_text);
						free_floatreg($3.cur_register);
						snprintf(file_text,mx-1,"t%d[t%d] = t%d",$1.array,$1.index,temp_idx);
						free_intreg(temp_idx);
					}
					else{
						snprintf(file_text,mx-1,"t%d[t%d] = f%d",$1.array,$1.index,$3.cur_register);
						free_floatreg($3.cur_register);
					}										
				}
				if(!strcmp($3.type,"int")){
					if(strcmp($1.type,"int")){
						int temp_idx=allot_floatreg();
						snprintf(file_text,mx-1,"f%d = ConvertToFloat(t%d)",temp_idx,$3.cur_register);
						file_printer(file_text);
						free_intreg($3.cur_register);
						snprintf(file_text,mx-1,"t%d[t%d] = f%d",$1.array,$1.index,temp_idx);
						free_floatreg(temp_idx);
					}
					else{
						snprintf(file_text,mx-1,"t%d[t%d] = t%d",$1.array,$1.index,$3.cur_register);
						free_intreg($3.cur_register);
					}
				}
				file_printer(file_text);
				free_intreg($1.index);
				free_intreg($1.array);
			}
		}
	}
;

OR_COND	: 	OR_COND OR AND_COND
	{
		fix_print($3.list_quad,$3.cnt_quad,printer_len);
		if($1.cnt_or==0){
			$$.cnt_or=1;
			int temp2=$1.cur_register;
			int temp_idx=allot_intreg();
			char file_text[mx];
			snprintf(file_text,mx-1,"t%d = 0 ",temp_idx);
			file_printer(file_text);
			if(strcmp($1.type,"float")==0){
				temp2=allot_intreg();
				snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp2,$1.cur_register);
				free_floatreg($1.cur_register);
				file_printer(file_text);
			}
			snprintf(file_text,mx-1,"if(t%d == 0) goto %d",temp2,printer_len+3);
			file_printer(file_text);
			snprintf(file_text,mx-1,"t%d = 1",temp_idx);
			file_printer(file_text);
			snprintf(file_text,mx-1,"goto _____");
			$1.cnt_quad=0;
			$1.list_quad[$1.cnt_quad++]=printer_len;
			file_printer(file_text);
			free_intreg($1.cur_register);
			$1.cur_register=temp_idx;
			free_intreg(temp2);				
		}
		int getcase = return_type($1.type,$3.type);
		if(getcase!=0) strcpy($$.type,"int");
		else strcpy($$.type,"errortype");
		$$.if_case=$1.if_case && $3.if_case;
		int temp2=$3.cur_register;
		char file_text[mx];
		if(!strcmp($3.type,"float")){
			temp2=allot_intreg();
			snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp2,$3.cur_register);
			free_floatreg($3.cur_register);
			file_printer(file_text);
		}
		snprintf(file_text,mx-1,"if(t%d == 0) goto %d",temp2,printer_len+3);
		file_printer(file_text);
		snprintf(file_text,mx-1,"t%d = 1",$1.cur_register);
		file_printer(file_text);
		snprintf(file_text,mx-1,"goto _____");
		$$.cnt_quad=0;
		int i;
		for(i=0;i<$1.cnt_quad;i++){
			$$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
		}
		$$.list_quad[$$.cnt_quad++]=printer_len;
		file_printer(file_text);
		free_intreg(temp2);
		free_intreg($3.cur_register);
		$$.cur_register=$1.cur_register;
	}
	| 	AND_COND
	{						
		fix_print($1.list_quad,$1.cnt_quad,printer_len);
		strcpy($$.type,$1.type);
		$$.cnt_or=0;
		$$.cnt_quad=0;
		$$.if_case=$1.if_case;
		$$.cur_register=$1.cur_register;
	}
;

AND_COND 	: 	AND_COND AND NOT_COND 
	{
		if($1.cnt_and==0){
			$$.cnt_and=1;
			int temp_idx=allot_intreg();
			int temp2=$1.cur_register;
			char file_text[mx];
			snprintf(file_text,mx-1,"t%d = 1 ",temp_idx);
			file_printer(file_text);
			if(!strcmp($1.type,"float")){
				temp2=allot_intreg();
				snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp2,$1.cur_register);
				free_floatreg($1.cur_register);
				file_printer(file_text);
			}
			snprintf(file_text,mx-1,"if(t%d != 0) goto %d",temp2,printer_len+3);
			file_printer(file_text);
			snprintf(file_text,mx-1,"t%d = 0",temp_idx);
			file_printer(file_text);
			snprintf(file_text,mx-1,"goto _____");
			$1.cnt_quad=0;
			$1.list_quad[$1.cnt_quad++]=printer_len;
			file_printer(file_text);
			free_intreg(temp2);
			free_intreg($1.cur_register);
			$1.cur_register=temp_idx;
		}
		$$.if_case=$1.if_case && $3.if_case;
		int getcase = return_type($1.type,$3.type);
		char file_text[mx];
		int temp2=$3.cur_register;
		if(getcase!=0) strcpy($$.type,"int");	
		else strcpy($$.type,"errortype");
		if(!strcmp($3.type,"float")){
			temp2=allot_intreg();
			snprintf(file_text,mx-1,"t%d = ConvertToInt(f%d)",temp2,$3.cur_register);
			free_floatreg($3.cur_register);
			file_printer(file_text);
		}
		snprintf(file_text,mx-1,"if(t%d != 0) goto %d",temp2,printer_len+3);
		file_printer(file_text);
		snprintf(file_text,mx-1,"t%d = 0",$1.cur_register);
		file_printer(file_text);
		snprintf(file_text,mx-1,"goto _____");
		$$.cnt_quad=0;
		int i;
		for(i=0;i<$1.cnt_quad;i++) $$.list_quad[$$.cnt_quad++]=$1.list_quad[i];
		$$.list_quad[$$.cnt_quad++]=printer_len;
		file_printer(file_text);
		free_intreg($3.cur_register);
		free_intreg(temp2);
		$$.cur_register=$1.cur_register;
	}
	| 	NOT_COND
	{		
		strcpy($$.type,$1.type);	
		$$.cnt_and=0;
		$$.cnt_quad=0;			
		$$.cur_register=$1.cur_register;
		$$.if_case=$1.if_case;
	}
;



NOT_COND : COMP_EQUAL  					
	{
		$$.cur_register = $1.cur_register;
		$$.if_case = $1.if_case;
		strcpy($$.type,$1.type);
	}
	| NOT COMP_EQUAL 			
	{
		if(strcmp($1.type,"errortype") == 0) strcpy($$.type,"errortype");
		else strcpy($$.type,"int");

		$$.if_case=$2.if_case;

		int cur_register;
		cur_register = allot_intreg();

		char output[mx];
		snprintf(output, mx-1, "t%d = 1 ", cur_register);
		file_printer(output);

		int tempreg2 = $2.cur_register;
		if(strcmp($2.type,"float") == 0)
		{
			tempreg2 = allot_intreg();
			snprintf(output, mx-1, "t%d = ConvertToInt(f%d)", tempreg2, $2.cur_register);
			free_floatreg($2.cur_register);
			file_printer(output);
		}

		snprintf(output, mx-1, "if(t%d == 0) goto %d", tempreg2, printer_len+2);
		file_printer(output);
		snprintf(output, mx-1, "t%d = 0", cur_register);
		file_printer(output);

		free_intreg($2.cur_register);
		free_intreg(tempreg2);
		$$.cur_register = cur_register;
	}
;


COMP_EQUAL : COMP_EQUAL LT EXPR              
	{
		int caseType = return_type($1.type,$3.type);
		if(caseType != 0) strcpy($$.type, "int");
		else strcpy($$.type, "errortype");
		
		int cur_register;
		$$.if_case = ($1.if_case && $3.if_case);
		
		if(caseType == 1)
		{
			if(strcmp($1.type, "int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $1.cur_register);
				file_printer(output);
				free_intreg($1.cur_register);

				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				snprintf(output, mx-1, "if(f%d < f%d) goto %d", tempreg2, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg($3.cur_register);
				free_floatreg(tempreg2);
			}
			else if(strcmp($3.type, "int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $3.cur_register);
				file_printer(output);
				free_intreg($3.cur_register);

				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				snprintf(output, mx-1, "if(f%d < f%d) goto %d", $1.cur_register, tempreg2, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg($1.cur_register);
				free_floatreg(tempreg2);
			}
			else
			{
				char output[mx];
				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				
				snprintf(output, mx-1, "if(f%d < f%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg($1.cur_register);
				free_floatreg($3.cur_register);
			}
		}
		else if(caseType == 2)
		{
			char output[mx];
			cur_register = allot_intreg();
			snprintf(output, mx-1, "t%d = 1", cur_register);
			file_printer(output);
			
			snprintf(output, mx-1, "if(t%d < t%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
			file_printer(output);
			snprintf(output,mx-1,"t%d = 0",cur_register);
			file_printer(output);

			free_intreg($1.cur_register);
			free_intreg($3.cur_register);
		}

		$$.cur_register = cur_register;
	}
	| COMP_EQUAL LTE EXPR
	{
		int caseType = return_type($1.type, $3.type);
		if(caseType != 0) strcpy($$.type, "int");
		else strcpy($$.type,"errortype");
		
		$$.if_case = ($1.if_case && $3.if_case);

		int cur_register;
		if(caseType == 1)
		{
			if(strcmp($1.type, "int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $1.cur_register);
				file_printer(output);
				free_intreg($1.cur_register);

				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				snprintf(output, mx-1, "if(f%d <= f%d) goto %d", tempreg2, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg($3.cur_register);
				free_floatreg(tempreg2);
			}
			else if(strcmp($3.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output,mx-1,"f%d = ConvertToFloat(t%d)",tempreg2,$3.cur_register);
				file_printer(output);
				free_intreg($3.cur_register);

				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				snprintf(output, mx-1, "if(f%d <= f%d) goto %d", $1.cur_register, tempreg2, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg($1.cur_register);
				free_floatreg(tempreg2);
			}
			else
			{
				char output[mx];
				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				snprintf(output, mx-1, "if(f%d <= f%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg($1.cur_register);
				free_floatreg($3.cur_register);
			}
		}
		else if(caseType == 2)
		{
			char output[mx];
			cur_register = allot_intreg();
			snprintf(output, mx-1, "t%d = 1", cur_register);
			file_printer(output);
			snprintf(output, mx-1, "if(t%d <= t%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
			file_printer(output);
			snprintf(output, mx-1, "t%d = 0", cur_register);
			file_printer(output);

			free_intreg($1.cur_register);
			free_intreg($3.cur_register);
		}

		$$.cur_register = cur_register;
	}
	| COMP_EQUAL GT EXPR 			
	{
		int caseType = return_type($1.type,$3.type);
		if(caseType != 0) strcpy($$.type, "int");
		else strcpy($$.type,"errortype");
		
		int cur_register;
		$$.if_case = ($1.if_case && $3.if_case);

		if(caseType == 1)
		{
			if(strcmp($1.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $1.cur_register);
				file_printer(output);
				free_intreg($1.cur_register);

				cur_register = allot_intreg();
				snprintf(output,  mx-1, "t%d = 1", cur_register);
				file_printer(output);
				snprintf(output, mx-1, "if(f%d > f%d) goto %d", tempreg2, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg(tempreg2);
				free_floatreg($3.cur_register);
			}
			else if(!strcmp($3.type,"int"))
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $3.cur_register);
				file_printer(output);
				free_intreg($3.cur_register);

				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				snprintf(output, mx-1, "if(f%d > f%d) goto %d", $1.cur_register, tempreg2, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg(tempreg2);
				free_floatreg($1.cur_register);
			}
			else
			{
				char output[mx];
				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				snprintf(output, mx-1, "if(f%d > f%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg($3.cur_register);
				free_floatreg($1.cur_register);
			}
		}
		else if(caseType == 2)
		{
			char output[mx];
			cur_register = allot_intreg();
			snprintf(output, mx-1, "t%d = 1", cur_register);
			file_printer(output);
			snprintf(output, mx-1, "if(t%d > t%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
			file_printer(output);
			snprintf(output, mx-1, "t%d = 0", cur_register);
			file_printer(output);

			free_intreg($3.cur_register);
			free_intreg($1.cur_register);
		}

		$$.cur_register = cur_register;
	}
	| COMP_EQUAL GTE EXPR           
	{
		int caseType = return_type($1.type,$3.type);
		if(caseType != 0) strcpy($$.type, "int");
		else strcpy($$.type,"errortype");
		
		int cur_register;
		$$.if_case = ($1.if_case && $3.if_case);

		if(caseType == 1)
		{
			if(strcmp($1.type,"int") == 0)
			{
				int tempreg2 = allot_floatreg();
				char output[mx];
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2,  $1.cur_register);
				file_printer(output);
				free_intreg($1.cur_register);

				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				
				snprintf(output, mx-1, "if(f%d >= f%d) goto %d",tempreg2, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0" ,cur_register);
				file_printer(output);

				free_floatreg($3.cur_register);
				free_floatreg(tempreg2);
			}
			else if(strcmp($3.type,"int") == 0)
			{
				int tempreg2 = allot_floatreg();
				char output[mx];
				snprintf(output,mx-1,"f%d = ConvertToFloat(t%d)",tempreg2,$3.cur_register);
				file_printer(output);
				free_intreg($3.cur_register);
				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				
				snprintf(output, mx-1, "if(f%d >= f%d) goto %d", $1.cur_register, tempreg2, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg(tempreg2);
				free_floatreg($1.cur_register);
			}
			else
			{
				char output[mx];
				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				
				snprintf(output, mx-1, "if(f%d >= f%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);
				
				free_floatreg($3.cur_register);
				free_floatreg($1.cur_register);
			}
			
		
		}

		else if(caseType == 2)
		{
				cur_register = allot_intreg();
				char output[mx];
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				
				snprintf(output, mx-1,"if(t%d >= t%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_intreg($1.cur_register);
				free_intreg($3.cur_register);
		}
		$$.cur_register = cur_register;
	
	}
	| COMP_EQUAL NEQ EXPR    	       
	{	
		int caseType = return_type($1.type,$3.type);
		if(caseType != 0) strcpy($$.type, "int");
		else strcpy($$.type,"errortype");
		
		int cur_register;
		$$.if_case = ($1.if_case && $3.if_case);

		if(caseType == 1)
		{
			if(strcmp($1.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $1.cur_register);
				file_printer(output);
				free_intreg($1.cur_register);

				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				
				snprintf(output, mx-1, "if(f%d != f%d) goto %d", tempreg2, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);
				free_floatreg($3.cur_register);
				free_floatreg(tempreg2);
			}
			else if(strcmp($3.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $3.cur_register);
				file_printer(output);
				free_intreg($3.cur_register);
				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				
				snprintf(output, mx-1, "if(f%d != f%d) goto %d", $1.cur_register, tempreg2, printer_len+2);
				file_printer(output);
				snprintf(output , mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg(tempreg2);
				free_floatreg($1.cur_register);
			}
			else
			{
				char output[mx];
				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				
				snprintf(output, mx-1, "if(f%d != f%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg($3.cur_register);
				free_floatreg($1.cur_register);
			}		
		}
		else if(caseType == 2)
		{
			cur_register = allot_intreg();
			char output[mx];
			snprintf(output, mx-1, "t%d = 1", cur_register);
			file_printer(output);
			
			snprintf(output, mx-1, "if(t%d != t%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
			file_printer(output);
			snprintf(output, mx-1, "t%d = 0", cur_register);
			file_printer(output);

			free_intreg($3.cur_register);
			free_intreg($1.cur_register);
		}
		$$.cur_register = cur_register;

	}
	| COMP_EQUAL EQUATE EXPR         
	{
		int caseType = return_type($1.type, $3.type);
		if(caseType != 0) strcpy($$.type, "int");
		else strcpy($$.type,"errortype");
		
		int cur_register;
		$$.if_case = ($1.if_case && $3.if_case);

		if(caseType == 1)
		{
			if(strcmp($1.type,"int") == 0)
			{
				int tempreg2 = allot_floatreg();
				char output[mx];
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $1.cur_register);
				file_printer(output);
			
				free_intreg($1.cur_register);

				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				
				snprintf(output, mx-1, "if(f%d == f%d) goto %d", tempreg2, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg(tempreg2);
				free_floatreg($3.cur_register);
			}
			else if(!strcmp($3.type,"int"))
			{
				char output[mx];
				int tempreg2 = allot_floatreg();

				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $3.cur_register);
				file_printer(output);
				free_intreg($3.cur_register);

				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				snprintf(output, mx-1, "if(f%d == f%d) goto %d", $1.cur_register, tempreg2, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);

				free_floatreg(tempreg2);
				free_floatreg($1.cur_register);
			}
			else
			{
				char output[mx];
				cur_register = allot_intreg();
				snprintf(output, mx-1, "t%d = 1", cur_register);
				file_printer(output);
				snprintf(output,mx-1, "if(f%d == f%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
				file_printer(output);
				snprintf(output, mx-1, "t%d = 0", cur_register);
				file_printer(output);
				free_floatreg($1.cur_register);
				free_floatreg($3.cur_register);
			}
			
		}
		else if(caseType == 2)
		{
			char output[mx];
			cur_register = allot_intreg();

			snprintf(output, mx-1, "t%d = 1", cur_register);
			file_printer(output);
			snprintf(output, mx-1, "if(t%d == t%d) goto %d", $1.cur_register, $3.cur_register, printer_len+2);
			file_printer(output);
			snprintf(output, mx-1, "t%d = 0", cur_register);
			file_printer(output);

			free_intreg($3.cur_register);
			free_intreg($1.cur_register);
		}

		$$.cur_register = cur_register;
	}
	| EXPR 					
	{
		$$.if_case = $1.if_case;
		$$.cur_register = $1.cur_register;
		strcpy($$.type,$1.type);
	}
;		

EXPR : EXPR PLUS TERM                    
	{
		int caseType = return_type($1.type,$3.type);
		int cur_register;
		if(caseType == 0) strcpy($$.type,"errortype");
		else if(caseType == 1)
		{
			strcpy($$.type, "float");
			if(strcmp($1.type, "int") == 0)
			{
				int tempreg2 = allot_floatreg();
				char output[mx];
		
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $1.cur_register);
				file_printer(output);
				free_intreg($1.cur_register);

				cur_register = allot_floatreg();
				snprintf(output, mx-1, "f%d = f%d + f%d", cur_register,  tempreg2, $3.cur_register);
				file_printer(output);

				free_floatreg(tempreg2);
				free_floatreg($3.cur_register);
			}
			else if(strcmp($3.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();

				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $3.cur_register);
				file_printer(output);
				free_intreg($3.cur_register);

				cur_register = allot_floatreg();
				snprintf(output, mx-1, "f%d = f%d + f%d", cur_register, $1.cur_register, tempreg2);
				file_printer(output);

				free_floatreg(tempreg2);
				free_floatreg($1.cur_register);
			}
			else
			{
				char output[mx];
				cur_register = allot_floatreg();

				snprintf(output, mx-1, "f%d = f%d + f%d", cur_register, $1.cur_register, $3.cur_register);
				file_printer(output);

				free_floatreg($1.cur_register);
				free_floatreg($3.cur_register);
			}
		}
		else if(caseType == 2)
		{
			char output[mx];
			cur_register = allot_intreg();
			strcpy($$.type, "int");

			snprintf(output, mx-1, "t%d = t%d + t%d", cur_register, $1.cur_register, $3.cur_register);
			file_printer(output);

			free_intreg($3.cur_register);
			free_intreg($1.cur_register);
		}

		$$.if_case = ($1.if_case && $3.if_case);
		$$.cur_register = cur_register;

	}
	| EXPR MINUS TERM 				
	{
		int caseType = return_type($1.type,$3.type);
		int cur_register;
		
		if(caseType == 0) strcpy($$.type,"errortype");
		else if(caseType == 1)
		{
			strcpy($$.type,"float");
			if(strcmp($1.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output,mx-1,"f%d = ConvertToFloat(t%d)",tempreg2,$1.cur_register);
				file_printer(output);
				free_intreg($1.cur_register);

				cur_register = allot_floatreg();
				snprintf(output,mx-1,"f%d = f%d - f%d",cur_register,tempreg2,$3.cur_register);
				file_printer(output);

				free_floatreg(tempreg2);
				free_floatreg($3.cur_register);
			}
			else if(strcmp($3.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output,mx-1,"f%d = ConvertToFloat(t%d)",tempreg2,$3.cur_register);
				file_printer(output);

				free_intreg($3.cur_register);
				cur_register = allot_floatreg();

				snprintf(output,mx-1,"f%d = f%d - f%d",cur_register,$1.cur_register,tempreg2);
				file_printer(output);
				free_floatreg(tempreg2);
				free_floatreg($1.cur_register);
			}
			else
			{
				cur_register = allot_floatreg();
				char output[mx];

				snprintf(output,mx-1,"f%d = f%d - f%d",cur_register,$1.cur_register,$3.cur_register);
				file_printer(output);

				free_floatreg($3.cur_register);
				free_floatreg($1.cur_register);
			}
		}
		else if(caseType == 2)
		{
			char output[mx];
			strcpy($$.type,"int");
			cur_register = allot_intreg();

			snprintf(output, mx-1, "t%d = t%d - t%d", cur_register, $1.cur_register, $3.cur_register);
			file_printer(output);

			free_intreg($3.cur_register);
			free_intreg($1.cur_register);

		}
		$$.if_case = ($1.if_case && $3.if_case);
		$$.cur_register = cur_register;

	}
	| TERM 						
	{
		$$.if_case = $1.if_case;
		$$.cur_register = $1.cur_register;
		strcpy($$.type,$1.type);
	}
;

TERM : TERM MULT F 					
	{
		int caseType = return_type($1.type,$3.type);
		int cur_register;
		
		if(caseType == 0) strcpy($$.type,"errortype");
		else if(caseType == 1)
		{
			strcpy($$.type,"float");
			if(strcmp($1.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
		
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $1.cur_register);
				file_printer(output);
				free_intreg($1.cur_register);

				cur_register = allot_floatreg();
				snprintf(output, mx-1, "f%d = f%d * f%d", cur_register, tempreg2, $3.cur_register);
				file_printer(output);

				free_floatreg($3.cur_register);
				free_floatreg(tempreg2);
			}
			else if(strcmp($3.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();

				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $3.cur_register);
				file_printer(output);
				free_intreg($3.cur_register);

				cur_register = allot_floatreg();
				snprintf(output,mx-1,"f%d = f%d * f%d",cur_register,$1.cur_register,tempreg2);
				file_printer(output);
				free_floatreg($1.cur_register);
				free_floatreg(tempreg2);
			}
			else
			{
				cur_register = allot_floatreg();
				char output[mx];
				snprintf(output, mx-1, "f%d = f%d * f%d", cur_register, $1.cur_register, $3.cur_register);
				file_printer(output);

				free_floatreg($3.cur_register);
				free_floatreg($1.cur_register);
			}
		}
		else if(caseType == 2)
		{
			char output[mx];
			cur_register = allot_intreg();
			strcpy($$.type,"int");

			snprintf(output, mx-1 ,"t%d = t%d * t%d", cur_register, $1.cur_register, $3.cur_register);
			file_printer(output);

			free_intreg($1.cur_register);
			free_intreg($3.cur_register);
		}

		$$.if_case = ($1.if_case && $3.if_case);
		$$.cur_register = cur_register;
	}
	| TERM DIV F                   
	{
		int caseType = return_type($1.type,$3.type);
		int cur_register;
		
		if(caseType == 0) strcpy($$.type,"errortype");
		else if(caseType == 1)
		{
			strcpy($$.type,"float");
			if(strcmp($1.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
		
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $1.cur_register);
				file_printer(output);
				free_intreg($1.cur_register);

				cur_register = allot_floatreg();
				snprintf(output, mx-1, "f%d = f%d / f%d", cur_register, tempreg2, $3.cur_register);
				file_printer(output);

				free_floatreg($3.cur_register);
				free_floatreg(tempreg2);
			}
			else if(strcmp($3.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $3.cur_register);
				file_printer(output);
				free_intreg($3.cur_register);

				cur_register = allot_floatreg();
				snprintf(output, mx-1, "f%d = f%d / f%d", cur_register, $1.cur_register, tempreg2);
				file_printer(output);

				free_floatreg($1.cur_register);
				free_floatreg(tempreg2);

			}
			else
			{
				char output[mx];
				cur_register = allot_floatreg();
				snprintf(output, mx-1, "f%d = f%d / f%d", cur_register, $1.cur_register, $3.cur_register);
				file_printer(output);

				free_floatreg($1.cur_register);
				free_floatreg($3.cur_register);
			}
		}
		else if(caseType == 2)
		{
			char output[mx];
			cur_register = allot_intreg();
			strcpy($$.type,"int");

			snprintf(output, mx-1, "t%d = t%d / t%d", cur_register, $1.cur_register, $3.cur_register);
			file_printer(output);

			free_intreg($1.cur_register);
			free_intreg($3.cur_register);

		}

		$$.if_case = ($1.if_case && $3.if_case);
		$$.cur_register = cur_register;

	}		
	| TERM MOD F 					
	{
		int caseType = return_type($1.type,$3.type);
		int cur_register;
		if(caseType == 0)
		{
			strcpy($$.type,"errortype");
		}
		if(caseType == 1)
		{
			strcpy($$.type,"float");
			if(strcmp($1.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();

				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $1.cur_register);
				file_printer(output);
				free_intreg($1.cur_register);

				cur_register = allot_floatreg();
				snprintf(output, mx-1, "f%d = f%d %% f%d", cur_register, tempreg2, $3.cur_register);
				file_printer(output);

				free_floatreg(tempreg2);
				free_floatreg($3.cur_register);
			}
			else if(strcmp($3.type,"int") == 0)
			{
				char output[mx];
				int tempreg2 = allot_floatreg();
				snprintf(output, mx-1, "f%d = ConvertToFloat(t%d)", tempreg2, $3.cur_register);
				file_printer(output);
				free_intreg($3.cur_register);

				cur_register = allot_floatreg();
				snprintf(output, mx-1, "f%d = f%d %% f%d",  cur_register, $1.cur_register, tempreg2);
				file_printer(output);

				free_floatreg($1.cur_register);
				free_floatreg(tempreg2);

			}
			else
			{
				char output[mx];
				cur_register = allot_floatreg();
				snprintf(output, mx-1, "f%d = f%d %% f%d", cur_register, $1.cur_register, $3.cur_register);
				file_printer(output);
				free_floatreg($1.cur_register);
				free_floatreg($3.cur_register);
			}
		}
		else if(caseType == 2)
		{
			char output[mx];
			cur_register = allot_intreg();
			strcpy($$.type,"int");

			snprintf(output, mx-1, "t%d = t%d %% t%d", cur_register, $1.cur_register, $3.cur_register);
			file_printer(output);
			free_intreg($1.cur_register);
			free_intreg($3.cur_register);

		}
		$$.if_case = ($1.if_case && $3.if_case);
		$$.cur_register = cur_register;

	}
	| F 						
	{
		$$.if_case = $1.if_case;
		$$.cur_register = $1.cur_register;
		strcpy($$.type, $1.type);
	}			
;	

F : ID 							
	{
		int pfind = is_pres_arr(functable[cur_idx_func].list_param, functable[cur_idx_func].cnt_param, $1.text);
		int gfind = is_pres_arr(functable[0].list_variable, functable[0].cnt_var, $1.text);
		int find = is_pres_arr(functable[cur_idx_func].list_variable, functable[cur_idx_func].cnt_var, $1.text);

		if(pfind == -1 && gfind == -1 && find == -1)
		{
			char temp[mx];
			snprintf(temp, mx-1, "No variable with name %s exists", $1.text);
			disp_errors(temp);
			strcpy($$.type, "errortype");
		}
		else
		{
			int cur_register;
			if(find != -1)
			{
				if(functable[cur_idx_func].list_variable[find].cnt_size > 0)
				{
					disp_errors("Direct use of Arrays like this is not permitted.");
				}

				strcpy($$.type, functable[cur_idx_func].list_variable[find].variable_type);

				char output[mx];
				if(strcmp($$.type,"int"))
				{
					cur_register = allot_floatreg();
					snprintf(output, mx-1, "f%d = %s", cur_register, functable[cur_idx_func].list_variable[find].name_fin);
				}
				else
				{
					cur_register = allot_intreg();
					snprintf(output, mx-1, "t%d = %s", cur_register, functable[cur_idx_func].list_variable[find].name_fin);
				}
				file_printer(output);	

			}
			else if(pfind != -1)
			{
				strcpy($$.type,functable[cur_idx_func].list_param[pfind].variable_type);

				char output[mx];
				if(strcmp($$.type,"int"))
				{
					cur_register = allot_floatreg();
					snprintf(output, mx-1, "f%d = %s", cur_register, functable[cur_idx_func].list_param[pfind].name_fin);
				}
				else
				{
					cur_register = allot_intreg();
					snprintf(output, mx-1, "t%d = %s", cur_register, functable[cur_idx_func].list_param[pfind].name_fin);
				}
				
				file_printer(output);

			}
			else if(gfind != -1)
			{
				if(functable[0].list_variable[gfind].cnt_size > 0)
				{
					disp_errors("Direct use of Arrays like this is not permitted.");
				}

				strcpy($$.type,functable[0].list_variable[gfind].variable_type);

				char output[mx];
				if(strcmp($$.type,"int"))
				{
					cur_register = allot_floatreg();
					snprintf(output, mx-1, "f%d = %s", cur_register, functable[0].list_variable[gfind].name_fin);
				}
				else
				{
					cur_register = allot_intreg();
					snprintf(output, mx-1, "t%d = %s", cur_register, functable[0].list_variable[gfind].name_fin);
				}

				file_printer(output);
			}

			$$.cur_register = cur_register;

		}

		$$.if_case = false;

	}							
	| NUM						
	{
		int cur_register;
		int len = strlen($1.text);
		bool isFloat=false;

		for(int i=0; i<len; i++)
		{
			if($1.text[i] == '.') isFloat=true;
		}

		char output[mx];
		if(isFloat)
		{
			strcpy($$.type,"float");
			cur_register = allot_floatreg();
			snprintf(output, mx-1, "f%d = %s", cur_register, $1.text);			
		}
		else
		{
			strcpy($$.type,"int");
			cur_register = allot_intreg();
			snprintf(output, mx-1, "t%d = %s", cur_register, $1.text);
		}
		
		file_printer(output);

		$$.if_case = true;
		$$.cur_register = cur_register;

	}
	| FUNC_CALL 				
	{
		$$.cur_register = $1.cur_register;
		strcpy($$.type, $1.type);

		if($$.cur_register == -1)
		{
			disp_errors("Void Function doesn't return any value.");
		}

		$$.if_case = false;

	}     
	| OPENPARA OR_COND CLOSEPARA 				
	{
		$$.cur_register = $2.cur_register;
		$$.if_case = $2.if_case;
		strcpy($$.type, $2.type);

		fix_print($2.list_quad, $2.cnt_quad, printer_len);
	}
	| ARRF  					
	{
		char output[mx];
		int cur_register = -2;

		if($1.index != -1 && $1.array != -1)
		{
			
			if(strcmp($1.type, "float") == 0)
			{
				cur_register = allot_floatreg();
				snprintf(output,mx-1,"f%d = t%d[t%d]",cur_register,$1.array,$1.index);
			}
			
			if(strcmp($1.type, "int") == 0)
			{
				cur_register = allot_intreg();
				snprintf(output,mx-1,"t%d = t%d[t%d]",cur_register,$1.array,$1.index);
			}

			file_printer(output);

			free_intreg($1.index);
			free_intreg($1.array);
		}

		$$.if_case = false;
		$$.cur_register = cur_register;
		strcpy($$.type, $1.type);
	}
;	

ARRF : ID ARRFLIST 				
	{
		int gfind = is_pres_arr(functable[0].list_variable, functable[0].cnt_var, $1.text);
		int find = is_pres_arr(functable[cur_idx_func].list_variable, functable[cur_idx_func].cnt_var, $1.text);
		
		strcpy($$.type, "errortype");
		$$.index = -1;
		$$.array = -1;

		if(gfind == -1 && find == -1)
		{
			char temp[mx];
			snprintf(temp, mx-1, "No variable with name %s exists", $1.text);
			disp_errors(temp);
			strcpy($$.type,"errortype");
		}
		else if(find != -1)
		{
			if(functable[cur_idx_func].list_variable[find].cnt_size == 0)
			{
				disp_errors("In simple variables, indexing is not permitted.");
			}
			else
			{
				if(functable[cur_idx_func].list_variable[find].cnt_size != $2.cnt_quad)
				{
					disp_errors("Mismatch in number of dimensions in array.");	
				}
				else 
				{
					char output[mx];
					int array = allot_intreg();
					snprintf(output, mx-1, "Load t%d %s", array, functable[cur_idx_func].list_variable[find].name_fin);
					file_printer(output);

					int nextIndex = allot_intreg();
					int temp = allot_intreg();
					snprintf(output, mx-1, "t%d = 0", nextIndex);
					file_printer(output);

					for(int x = 0; x < $2.cnt_quad; x++)
					{
						snprintf(output, mx-1, "t%d = %d", temp, functable[cur_idx_func].list_variable[find].size_mod[x]);
						file_printer(output);

						snprintf(output, mx-1, "t%d = t%d * t%d", temp, temp, $2.list_quad[x]);
						free_intreg($2.list_quad[x]);
						file_printer(output);

						snprintf(output, mx-1, "t%d = t%d + t%d", nextIndex, nextIndex, temp);
						file_printer(output);
					}

					snprintf(output, mx-1, "t%d = 4", temp);
					file_printer(output);
					snprintf(output, mx-1, "t%d = t%d * t%d", nextIndex, nextIndex, temp);
					file_printer(output);

					strcpy($$.type, functable[cur_idx_func].list_variable[find].variable_type);
					$$.index = nextIndex;
					$$.array = array;
					free_intreg(temp);
				}	
			}
		}
		else if(gfind != -1)
		{
			if(functable[0].list_variable[gfind].cnt_size == 0)
			{
				disp_errors("In simple variables, indexing is not permitted.");
			}
			else
			{
				if(functable[0].list_variable[gfind].cnt_size != $2.cnt_quad)
				{
					disp_errors("Mismatch in number of dimensions in array.");	
				}
				else 
				{
					char output[mx];
					int array = allot_intreg();
					snprintf(output, mx-1, "Load t%d %s", array, functable[0].list_variable[gfind].name_fin);
					file_printer(output);

					int temp = allot_intreg();
					int nextIndex = allot_intreg();

					snprintf(output, mx-1, "t%d = 0", nextIndex);
					file_printer(output);

					for(int x = 0; x < $2.cnt_quad; x++)
					{
						snprintf(output, mx-1, "t%d = %d", temp, functable[0].list_variable[gfind].size_mod[x]);
						file_printer(output);

						snprintf(output, mx-1, "t%d = t%d * t%d", temp, temp, $2.list_quad[x]);
						free_intreg($2.list_quad[x]);
						file_printer(output);

						snprintf(output, mx-1, "t%d = t%d + t%d", nextIndex, nextIndex, temp);
						file_printer(output);
					}

					snprintf(output, mx-1, "t%d = 4", temp);
					file_printer(output);
					snprintf(output, mx-1, "t%d = t%d * t%d", nextIndex, nextIndex, temp);
					file_printer(output);

					free_intreg(temp);
					strcpy($$.type, functable[0].list_variable[gfind].variable_type);
					$$.index = nextIndex;
					$$.array = array;
				}	
			}
		}
	}
;

ARRFLIST : ARRFLIST OPENSQR OR_COND CLOSESQR     
	{
		fix_print($3.list_quad, $3.cnt_quad, printer_len);

		if(strcmp($3.type,"int") != 0)
		{
			disp_errors("Array indices should be integers.");
		}

		$$.cnt_quad = 0;
		for(int x = 0; x < $1.cnt_quad; x++, $$.cnt_quad++)
		{
			$$.list_quad[$$.cnt_quad] = $1.list_quad[x];
		}

		$$.list_quad[$$.cnt_quad] = $3.cur_register;
		$$.cnt_quad++;

	}
	| OPENSQR OR_COND CLOSESQR 				
	{
		fix_print($2.list_quad, $2.cnt_quad, printer_len);

		if(strcmp($2.type,"int") != 0)
		{
			disp_errors("Array indices should be integers.");
		}

		$$.cnt_quad = 0;
		$$.list_quad[$$.cnt_quad] = $2.cur_register;
		$$.cnt_quad++;
	}
;

SWITCH : SWITCHET OPENCURL CASES CLOSECURL 		
	{									
		$$.cnt_quad = 0;
		for(int x = 0; x < $3.cnt_quad; x++, $$.cnt_quad++){
			$$.list_quad[$$.cnt_quad] = $3.list_quad[x];
		}
	}
; 

SWITCHET : WORD_SWITCH  OPENPARA OR_COND CLOSEPARA 			
	{
		cnt_break++;

		if(strcmp($3.type,"int") != 0)
		{
			disp_errors("In switch, integer resulting expression is required.");
		}

		scope_change = $3.cur_register;
		fix_print($3.list_quad, $3.cnt_quad, printer_len);
	}
;

CASES : CASELIST MCASE DEFAULTE 
	{
		$$.cnt_quad = 0;
		fix_print($1.list_quad1, $1.cnt_quad1, $2.quad);
	
		for(int x = 0; x < $3.cnt_quad; x++, $$.cnt_quad++)
		{
			$$.list_quad[$$.cnt_quad] =  $3.list_quad[x];
		}

	}
	| CASELIST				
	{
		$$.cnt_quad = 0;

		for(int x = 0; x < $1.cnt_quad1; x++, $$.cnt_quad++)
		{
			$$.list_quad[$$.cnt_quad] = $1.list_quad1[x];
		}
	}
;

DEFAULTE : DEFAULT COLON INSTRUCTIONS   
	{
		$$.cnt_quad = 0;

		for(int x = 0; x < $3.cnt_quad; x++, $$.cnt_quad++)
		{
			$$.list_quad[$$.cnt_quad]=$3.list_quad[x];
		}
 	}	
;

CASELIST : CASELIST CASE  
	{				
		$$.cnt_quad1 = 0;
		fix_print($1.list_quad1, $1.cnt_quad1, $2.quad);

		for(int x = 0; x < $2.cnt_quad1; x++, $$.cnt_quad1++)
		{
			$$.list_quad1[$$.cnt_quad1] = $2.list_quad1[x];
		}
  	}	
   	| CASE      
   	{
		$$.cnt_quad1 = 0;

		for(int x = 0; x < $1.cnt_quad1; x++, $$.cnt_quad1++)
		{
			$$.list_quad1[$$.cnt_quad1] = $1.list_quad1[x];
		}
	}
;

CASE : CASETEMP CMARK CBODY 							
	{
		$$.cnt_quad1 = 0;
		fix_print($3.list_quad, $3.cnt_quad, printer_len);

		$$.list_quad1[$$.cnt_quad1] = printer_len;
		$$.cnt_quad1++;
		
		char printer[mx];
		snprintf(printer, mx-1, "goto _____");
		file_printer(printer);


		fix_print($1.list_quad, $1.cnt_quad, printer_len);
		$$.quad = $2.quad;
	}
;

CMARK : 
	{
		$$.quad = printer_len;
	}
;

CASETEMP : CASET NCASE OR_COND COLON      						
	{
		if(strcmp($3.type, "int") != 0)
		{
			disp_errors("Case label can't be reduced to a constant integer.");
		}
		else if($3.if_case == 0)
		{
			disp_errors("Case label should be having only constant integer expressions.");
		}

		fix_print($3.list_quad, $3.cnt_quad, printer_len);
		char output[mx];
		snprintf(output, mx-1, "if(t%d != t%d) goto _____", scope_change, $3.cur_register);
		
		$$.cnt_quad=0;
		$$.list_quad[$$.cnt_quad] = printer_len;
		$$.cnt_quad++;

		free_intreg($3.cur_register);
		file_printer(output);
	}
;

CBODY : INSTRUCTIONS   
	{
		$$.cnt_quad = 0;
		for(int x=0; x < $1.cnt_quad; x++, $$.cnt_quad++)
		{
			$$.list_quad[$$.cnt_quad] = $1.list_quad[x];
		}
	}
;

MCASE : 
	{
		$$.quad = printer_len;	
	}
;

NCASE : 
; 


%%

void yyerror (char *s) {
	success=false;
	printf("Syntax Error at line %d\n",total_lines+1);	
}

int return_type(char str1[],char str2[])
{
	if(strcmp(str1,"errortype")==0 || strcmp(str2,"errortype")==0) return 0;
	else if(strcmp(str1,"float")==0 || strcmp(str2,"float")==0) return 1;
	else return 2;
}

bool is_pres_var (struct details_variable array[],int size,char finder[],int scope)
{
	int i=0;
	for(i=0;i<size;i++){
		if(strcmp(array[i].variable_name,finder)==0 && array[i].scope==scope) return true;
	}
	return false;
}

int is_pres_arr (struct details_variable array[],int size,char finder[])
{
	int i=0;
	for(i=size-1;i>=0;i--){
		if(strcmp(array[i].variable_name,finder)==0) return i;
	}
	return -1;
}

void disp_variables(struct details_variable rec)
{
	printf("%s %s",rec.variable_name,rec.variable_type);
	if(rec.tag) printf(" %s ","1");
	else printf(" %s ","0");
	printf("%d\n",rec.scope);
}

void fix_print(int* array, int len, int x)
{
	for(int i = 0; i < len; ++i){
		for(int j = 0; j < len; ++j){
			if(array[i]<array[j]){
				int t=array[i];
				array[i]=array[j];
				array[j]=t;
			}
		}
	}

	fseek(fp,0,0);
	int num_line=1,i=0;
	for(i=0;i<len;i++){
		while(true){
			if(num_line==array[i]){
				char temp[300];
				char idx=0;
				while(true){
					char ch=getc(fp);
					temp[idx]=ch;
					idx++;
					if(ch=='\n') break;	
				}
				temp[idx]='\0';
				char int_print[5];
				sprintf(int_print,"%d",x);
				int idx1,idx2;
				for(idx1=0;idx1<strlen(int_print);idx1++) temp[idx+idx1-6]=int_print[idx1];
				for(idx2=strlen(int_print);idx2<5;idx2++) temp[idx+idx2-6]=' ';
				fseek(fp,-idx,SEEK_CUR);
				fputs(temp, fp);
				num_line++;
				break;
			}
			char ch = getc(fp);
			if(ch=='\n') num_line++;
		}
	}
	fseek(fp, 0, SEEK_END);
}
void disp_warnings(char*s)
{
	printf("Semantic Warning at Line #%d : ",total_lines+1);
	printf("%s\n",s);
}
void disp_errors(char*s)
{
	success=false;
	printf("Semantic Error at Line #%d : ",total_lines+1);
	printf("%s\n",s);
}
void file_printer(char*s)
{
	fprintf(fp,"%d: %s\n",printer_len,s);
	printer_len++;
}
int allot_intreg()
{
	int i=0;
	for(i=0;i<10;i++){
		if(!register_int[i]){
			register_int[i]=true;
			return i;
		}
	}
	return -1;
}

void free_intreg(int i)
{
	if(i!=-1) register_int[i]=false;
}
int allot_floatreg()
{
	int i=0;
	for(i=0;i<10;i++){
		if(!register_float[i]){
			register_float[i]=true;
			return i;
		}
	}
	return -1;
}
int string_to_int(char *str)
{
	int len=strlen(str),i,ans=0;
	for(i=0;i<len;i++) ans=ans*10+(str[i]-48);
	return ans;
}
void free_floatreg(int i)
{
	if(i!=-1) register_float[i]=false;
}

bool has_char(char text[],int len)
{
	int i=0;
	for(i=0;i<len;i++){
		if(text[i]!=' '&&text[i]!='\t'&&text[i]!='\n') return true;
	}
	return false;
}

bool if_func_like(char text[],int n)
{
	for(int i=0;i<n;i++){
		if(text[i]=='(') return true;
	}
	return false;
}
void disp_all_func()
{
	int i=0;
	for(i=0;i<cur_idx_func;i++) disp_func(functable[i]);	
}

void disp_func(struct details_function func_rec)
{
	printf("%s %s\n",func_rec.name_func,func_rec.type);
	int i=0;
	printf("Parameters %d\n",func_rec.cnt_param);
	for(i=0;i<func_rec.cnt_param;i++) disp_variables(func_rec.list_param[i]);
	printf("=====================================\n");
	printf("Variables %d\n",func_rec.cnt_var);
	for(i=0;i<func_rec.cnt_var;i++) disp_variables(func_rec.list_variable[i]);
}

int main(int argc, char const * argv[])
{
	char file_name[3][100];
	int i=0;
	for(i=0;i<3;i++) snprintf(file_name[i],mx-1,"%s",argv[i+1]);
	char temp_name[mx];
	snprintf(temp_name,mx-1,"%s_Modified.txt",file_name[0]);
	fil=fopen(file_name[0],"r");
	FILE * fil1=fopen(temp_name,"w");
	bool check=true;
	char text[mx];
	while(fgets(text,sizeof(text),fil)){
		if(if_func_like(text,strlen(text))){
			fprintf(fil1,"%s",text);
			check=false;
		}
		else{
			if(check && has_char(text,strlen(text))) fprintf(fil1,"$$ %s",text);
			else fprintf(fil1,"%s",text);
		}
	}
	fclose(fil);
	fclose(fil1);
	fil1=fopen(temp_name,"r");
	yyin=fil1;
	for(i=0;i<10;i++){
		register_float[i]=false;
		register_int[i]=false;
	}
	fp=fopen(file_name[1],"w+");
	yyparse();
	fclose(fil1);
	fclose(fp);
	remove(temp_name);
	if(!success) printf("Error during compilation.\n");
	else printf("Successfully Compiled.\n\n");
	
	fil1=fopen(file_name[2],"w");
	for(i=0;i<cnt_allvar;i++) fprintf(fil1,"%s,%s,%d\n",all_vars[i],all_type[i],all_sizes[i]*4);
	fclose(fil1);

	fil1=fopen("finResult.txt","w");
	if(!success) fprintf(fil1,"0");
	else fprintf(fil1,"1");
	fclose(fil1);

	return 0;
}
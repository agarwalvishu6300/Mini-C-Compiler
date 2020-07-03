%{ 

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "pass1bison.tab.h"

void remove_space(char input[], char target[], int l);
void print_error();

int total_lines;
int flag = 1; 

%} 

wtspc 								[ \t]*
id 									[a-zA-Z][a-zA-Z0-9_]*
posnum 								([0-9]+)|([0-9]+)"."([0-9]+)
negnum 								"-"{posnum}
num 								{negnum}|{posnum}

%% 

{wtspc}"+"{wtspc} 					{flag = 1; return PLUS;}
{wtspc}"-"{wtspc} 					{flag = 1; return MINUS;}
{wtspc}"*"{wtspc} 					{flag = 1; return MULT;}
{wtspc}"/"{wtspc} 					{flag = 1; return DIV;}
{wtspc}"%"{wtspc} 					{flag = 1; return MOD;}
{wtspc}"<"{wtspc} 					{flag = 1; return LT;}
{wtspc}"<="{wtspc} 					{flag = 1; return LTE;}
{wtspc}">"{wtspc} 					{flag = 1; return GT;}
{wtspc}">="{wtspc} 					{flag = 1; return GTE;}
{wtspc}"=="{wtspc} 					{flag = 1; return EQUATE;}
{wtspc}"!="{wtspc} 					{flag = 1; return NEQ;}

{wtspc}"if"{wtspc} 					{flag = 1; return IF;}
{wtspc}"else"{wtspc} 				{flag = 1; return ELSE;}
{wtspc}"for"{wtspc} 				{flag = 1; return WORD_FOR;}
{wtspc}"while"{wtspc} 				{flag = 1; return WORD_WHILE;}
{wtspc}"return"{wtspc} 				{flag = 1; return RET;}
{wtspc}"switch"{wtspc} 				{flag = 1; return WORD_SWITCH;}
{wtspc}"break"{wtspc} 				{flag = 1; return BREAK;}
{wtspc}"default"{wtspc} 			{flag = 1; return DEFAULT;}
{wtspc}"case"{wtspc} 				{flag = 1; return CASET;}
{wtspc}"int"{wtspc} 				{flag = 1; return INT;}
{wtspc}"float"{wtspc} 				{flag = 1; return FLT;}
{wtspc}"void"{wtspc} 				{flag = 1; return VOID;}
{wtspc}"printf"{wtspc} 				{flag = 1; return PRINT;}
{wtspc}"$$"{wtspc} 					{flag = 1; return DOL;}

{wtspc}";"{wtspc}					{flag = 1; return SC;}
{wtspc}":"{wtspc}					{flag = 1; return COLON;}
{wtspc}","{wtspc}					{flag = 1; return COMMA;}
{wtspc}"="{wtspc} 					{flag = 1; return EQ;}
{wtspc}"||"{wtspc} 					{flag = 1; return OR;}
{wtspc}"&&"{wtspc} 					{flag = 1; return AND;}
{wtspc}"!"{wtspc} 					{flag = 1; return NOT;}

{wtspc}"("{wtspc} 					{flag = 1; return OPENPARA;}
{wtspc}")"{wtspc} 					{flag = 0; return CLOSEPARA;}
{wtspc}"{"{wtspc} 					{flag = 1; return OPENCURL;}
{wtspc}"}"{wtspc} 					{flag = 1; return CLOSECURL;}
{wtspc}"["{wtspc} 					{flag = 1; return OPENSQR;}
{wtspc}"]"{wtspc} 					{flag = 1; return CLOSESQR;}

{wtspc}{id}{wtspc}   				{
										char in[1000]; 
										remove_space(yytext,in,strlen(yytext));
										strcpy(yylval.attr.text,in);
										flag = 0;
										return ID;
									}

{wtspc}{num}{wtspc} 				{ 
									   	char in[1000]; 
										remove_space(yytext,in,strlen(yytext));
										if(!flag && in[0]=='-')
										{
											int len = strlen(in)-1;
											for(int x=len; x>=1; x--) unput(in[x]);
											flag=1;
											return MINUS;
										}

										strcpy(yylval.attr.text, in);
										flag=0;
										return NUM;
									}

\n 									{total_lines++;}
. 									{}

%%

int yywrap(void) { return 1; }

void print_error()
{
	printf("Invalid Syntax while lexical analysis.\n");
}

void remove_space(char input[], char target[], int l){
	int begin=0, end=l-1;
	while(input[begin]==' ' || input[begin]=='\t') {
		begin++;
	}
	while(input[end]==' ' || input[end]=='\t') {
		end--;
	}
	int x=0;
	for (int i = begin; i <= end; ++i, ++x) target[x]=input[i];
	target[x]='\0';
}
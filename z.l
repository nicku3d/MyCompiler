%{
#include <stdlib.h>
#include <string.h>
#include "def.tab.hh"
extern int yylineno;
const int yyerror(char *msg,...);
%}
%%
\=			{return '=';}
\+			{return '+';} 
\*			{return '*';}
\(			{return '(';}
\)			{return ')';}
\[			{return '[';}
\]			{return ']';}
\{			{return '{';}
\}			{return '}';}
\/			{return '/';}
\-			{return '-';}
\;			{return ';';}
\<			{return '<';}
\>			{return '>';}
\=\=			{return EQ;}
\!\=			{return NE;}
\>\=			{return GE;}
\<\=			{return LE;}
"if"			{return IF;}
"while"			{return WHILE;}
"int"			{return INT;}
"double"		{return DOUBLE;}
"printi"		{return PRINTI;}
"printd"		{return PRINTD;}
"prints"		{return PRINTS;}
"println"		{return PRINTLN;}
"scani"			{return SCANI;}
"scand"			{return SCAND;}
\"[A-Za-z]*\"	{yylval.text = strdup(yytext);
			return STRING;}
(0|[1-9][0-9]*)\.[0-9]+        {printf("liczba rzeczywista\n"); yylval.dval = atof(yytext);
			return LR;}
[1-9][0-9]*|0		{printf("liczba całkowita\n"); yylval.ival = atoi(yytext);
			return LC;}	
[A-Za-z_][A-Za-z0-9_]*	{printf("nazwa\n"); yylval.text = strdup(yytext);
			return ID;}
\ |\t			{;}
\n			{yylineno++ ;}
.			{yyerror("Błąd leksykalny\n");}
%%
const int yyerror(char *msg,...)
{
	printf("%d: %s", yylineno, msg);
	exit(1);
}

%{
#include <stdio.h>
#include <iostream>
#include <stack>
#include <string>
#include <vector>
#include <fstream>
#include <map>
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2
using namespace std;
enum Type{Int, Double, String, IntArray, DoubleArray};
struct element
{
	int type;
	string val;
};
map<string, element> symbols_map; //rozwinąc tablice symboli o wartosc 
//i wtedy usunac tablice stringow bo nie bedzie juz potrzebna ->> zrobione

void RPNtoFile(string);
void czynnikToStack(string, int);
void wyrToStack(string);
void triplesToFile(string);
void toASM();
void printi();
void printd();
void prints(string);
void scani(string);
void scand(string);
int getType(string);
string commentToASM(string comm);
string argToASM(string arg, int type, int tx);
string wyrToASM(string wyr);
string resultToASM(string result, int type);
string getFloatName(string arg);
int floatCounter=0;
extern "C" int yylex();
extern "C" int yyerror(const char *msg, ...);
%}
%union
{char *text;
int	ival;
double dval;};
%token <text> ID STRING
%token <ival> LC
%token <dval> LR
%token EQ LE GE NE
%token INT DOUBLE
%token PRINTI PRINTD PRINTS PRINTLN
%token SCANI SCAND
%token IF WHILE
%%
wiell
	:wiell linia		{printf("wiell l\n");}
	|linia			{printf("poj linia\n");}
	;

linia
	:wyrp ';'		{printf("wyr z ;\n");
					RPNtoFile("\n");}
	|if_expr ';'		{;}
	|io_statment ';'	{;}
	;

io_statment
	:PRINTI	'(' wyr ')'	{cout<<"PRINTI"<<endl;
						printi();}
	|PRINTD	'(' wyr ')'	{;}
	|PRINTS	'(' STRING ')'	{cout<<"PRINTS"<<endl;
							prints($3);}
	|PRINTLN '('')'		{;}
	|SCANI '(' ID ')'	{cout<<"SCANI"<<endl;
						symbols_map[string($3)].type=Int;
						scani($3);}
	|SCAND '(' ID ')'	{;}
	;

if_expr
	:if_begin code_block 	{;}
	;

if_begin
	:IF '(' condition ')' 	{;}
	;

code_block
	: '{' wiell '}'		{;}
	;

condition
	: wyr logicOption wyr 	{;}
	;

logicOption
	: EQ			{;}
	| NE			{;}
	| LE			{;}
	| '>'			{;}
	| GE			{;}
	| '<'			{;}
	;
	
wyrp
	:ID '=' wyr		{printf("wyrazenie z = \n");
				RPNtoFile($1);
				RPNtoFile("=");
				symbols_map[string($1)].type=Int;
				czynnikToStack(string($1), ID);
				wyrToStack("=");};
	;

wyr
	:wyr '+' skladnik	{RPNtoFile("+");
				wyrToStack("+");}
	|wyr '-' skladnik	{RPNtoFile("-");
				wyrToStack("-");}
	|skladnik		{printf("wyrazenie pojedyncze \n");}
	;

skladnik
	:skladnik '*' czynnik	{RPNtoFile("*");
				wyrToStack("*");}
	|skladnik '/' czynnik	{RPNtoFile("/");
				wyrToStack("/");}
	|czynnik		{printf("skladnik pojedynczy \n");}
	;

czynnik
	:ID			{RPNtoFile(string($1));
				symbols_map[string($1)].type=Int;
				cout<<"ID NA STOS"<<endl;
				czynnikToStack(string($1), ID);
				}
	|LC			{string s = to_string($1);
				RPNtoFile(s);
				czynnikToStack(s, LC);
				}
	|LR			{string s = to_string($1);
				//dodanie floata do tablicy symboli
				string floatName="float_value"+to_string(floatCounter);
				floatCounter++;
				symbols_map[floatName].type=Double;
				symbols_map[floatName].val=s;
				RPNtoFile(s);
				czynnikToStack(s, LR);
				}
	|'(' wyr ')'		{printf("wyrazenie w nawiasach\n");}
	;

%%
// kluczem jest identyfikator a wartosc to typ czyli int type;
stack<element> stk;
vector<string> asmBuffer;
ofstream testfile;
ofstream fileRPN;
int counter=0;
int stringCounter=0;

int main(int argc, char *argv[])
{
	//czyszczenie plików
	fileRPN.open("RPN.txt");
	fileRPN.close();
	testfile.open("trojki.txt");
	testfile.close();
	yyparse();

	//zapisywanie mapy symboli do pliku
	testfile.open("symbols.txt");
	for(const auto& it: symbols_map)
	{
		testfile << it.first;
		testfile << " => ";
		testfile << it.second.type;
		testfile << "\n";
	}
	testfile.close();
	toASM();
	return 0;
}

void czynnikToStack(string czynnik, int type)
{
	element el;
	el.val=czynnik;
	el.type=type;
	stk.push(el);
}

void wyrToStack(string wyr)
{
	string result, arg1, arg2, tmp="result";
	int tmpType=0;
	int arg1type, arg2type;
	element el;

	arg2=stk.top().val;
	arg2type=stk.top().type;
	stk.pop();
	arg1=stk.top().val;
	arg1type=stk.top().type;
	stk.pop();
	result+=arg1;
	result+=wyr;
	result+=arg2;
	
	triplesToFile(result);

	//generowanie asemblera do trojek
	if(wyr=="=")
	{
		//zmiana typu zmiennej do ktorej przypisywana jest wartość na odpowiedni do przypisywanej wartosci D:
		if(symbols_map[arg1].type == Double) {
			symbols_map[arg2].type = Double;
			symbols_map[arg2].val = "0";
			cout << "Zamieniam typ zmiennej "<< arg2 <<" na double" << endl;
		}
		//comment
		//lw $t0, resultx
		//sw $t0, zmienna
		asmBuffer.push_back(commentToASM(result));
		asmBuffer.push_back(argToASM(arg1, arg1type, 0));
		asmBuffer.push_back(resultToASM(arg2, arg1type));

	}
	else
	{
		//dodawanie resulta
		counter++;
		tmp+=to_string(counter);
		//jesli ktorys z argumentow rownania jest Double to typ resulta tez bedzie double
		if(arg1type == LR || arg2type == LR) {
			symbols_map[tmp].type=Double;
			symbols_map[tmp].val="0";
			tmpType=LR;
		}
		else {
			symbols_map[tmp].type=Int;
			tmpType=LC;
		}
		el.val=tmp;
		el.type=ID;
		stk.push(el);
		
		asmBuffer.push_back(commentToASM(result));
		asmBuffer.push_back(argToASM(arg1, arg1type, 0));
		asmBuffer.push_back(argToASM(arg2, arg2type, 1));
		asmBuffer.push_back(wyrToASM(wyr));
		asmBuffer.push_back(resultToASM(tmp, tmpType));
	}
}

void triplesToFile(string trojka)
{
	ofstream myfile;
	myfile.open("trojki.txt", ios_base::app);
	myfile << "result";
	myfile << to_string(counter);
	myfile << " = ";
	myfile << trojka;
	myfile << "\n";
	myfile.close();
}

void RPNtoFile(string txt)
{
	fileRPN.open("RPN.txt", ios_base::app);
	fileRPN << txt;
	fileRPN << " ";
	fileRPN.close();
}


string commentToASM(string comm)
{
	return "\n# "+comm;
}

string argToASM(string arg, int type, int tx)
{
	string tmp;
	if(type==ID){
	//TODO:sprawdzenie czy ID jest Int czy DOUBLE
		if(getType(arg) == Int)
		{
			tmp="lw";
			tmp+=" $t"+to_string(tx)+", "+arg;
		}
		else {
			tmp="l.s";
			tmp+=" $f"+to_string(tx)+", "+arg;
		}
	}
	else if(type == LC){ 
		tmp="li";
		tmp+=" $t"+to_string(tx)+", "+arg;
	}
	else if(type == LR){
		tmp='l.s';
		string argName = getFloatName(arg);
		tmp+=" $f"+to_string(tx)+", "+argName;
	} 
	
	return tmp;
}

int getType(string variableName)
{
	return symbols_map[variableName].type;
}

string getFloatName(string arg){
	for(const auto& it: symbols_map)
	{
		if (it.second.val == arg)
        return it.first;
	}
}

string wyrToASM(string wyr)
{
	//add, mul, sub, div
	
	string tmp;
		if(wyr=="+")
			tmp="add";
		else if(wyr=="-")
			tmp="sub";
		else if(wyr=="*")
			tmp="mul";
		else if(wyr=="/")
			tmp="div";
		return tmp+" $t0, $t0, $t1";

		//TODO: Dodac operacje na floatach 
		/*

		*/
}

string resultToASM(string result, int type)
{
	if(type==LC) return "sw $t0, "+result;
	else return "s.s $f0, "+result;
}

void toASM()
{
	testfile.open("ASM.txt");
	testfile <<".data\n";
	for(const auto& it: symbols_map)
	{
		testfile << it.first;
		testfile << ":		";
		if(it.second.type==String){
		testfile <<".asciiz ";
		testfile <<it.second.val;
		}
		else if(it.second.type==Double){
			testfile << ".float ";
			testfile << it.second.val;
		}
		else {
		testfile << ".word ";
		testfile << "0";
		}
		//testfile << it.second;
		testfile << "\n";
	}
	
	testfile << ".text\n";
	for(const auto& it: asmBuffer)
	{
		testfile << it;
		testfile << "\n";
	}
	testfile.close();
}

void printi()
{
	//li $v0 , 1 print
	//li $a0 , 42 liczba do wypisania
	//syscall wywołanie
	asmBuffer.push_back(commentToASM("printi "+stk.top().val));
	asmBuffer.push_back("li $v0, 1");
	string toPrint;
	cout<<"stack size: "<< stk.size()<<endl;
	if(stk.top().type==ID) toPrint="lw $a0, ";
	else toPrint="li $a0, ";
	toPrint+=stk.top().val;
	asmBuffer.push_back(toPrint);
	asmBuffer.push_back("syscall");
	stk.pop();
}

void printd()
{
}
void prints(string strToPrint)
{
	string strName="str"+to_string(stringCounter);
	symbols_map[strName].type=String;
	symbols_map[strName].val=strToPrint;
	stringCounter++;
	asmBuffer.push_back(commentToASM("prints "+strName));
	asmBuffer.push_back("li $v0, 4");
	asmBuffer.push_back("la $a0, "+strName);
	asmBuffer.push_back("syscall");
}

void scani(string var)
{
	//. data
	//x : . word 0
	//. text
	//li $v0 , 5
	//syscall
	//sw $v0 , x
	string tmpstr="sw $v0, " + var;
	asmBuffer.push_back(commentToASM("scani()"));
	asmBuffer.push_back("li $v0, 5");
	asmBuffer.push_back("syscall");
	asmBuffer.push_back(tmpstr);
	//brakuje sprawdzania TYPU


}

void scand(string var)
{
}
/*załadowanie 1 arg
ewentualna konwersja
załadowanie 2 arg
ewentualna konwersja arg 2
wygenerwoanie operacji właściwej
schowanie wyniku
generowanie zmiennej tymczasowej*/

CC=gcc
CPP=g++
LEX=flex
YACC=bison
LD=gcc

all:	leks

leks:	def.tab.o lex.yy.o
	$(CPP) -std=c++11 lex.yy.o def.tab.o -o leks -ll

lex.yy.o:	lex.yy.c
	$(CC) -c lex.yy.c

lex.yy.c: z.l
	$(LEX) z.l

def.tab.o:	def.tab.cc
	$(CPP) -std=c++11 -c def.tab.cc

def.tab.cc:	def.yy
	$(YACC) -d def.yy

clean:
	rm *.o leks *.hh *.cc

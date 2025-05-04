%option noyywrap

%{
#include "ast.h"
#include "Yacc.tab.h"
#undef BEGIN
#include <string.h>
#include <stdlib.h>
#include <stdio.h>


%}

/* Regex Definitions */
digit   [0-9]+
real    [0-9]+\.[0-9]+
id      [a-zA-Z_][a-zA-Z0-9_]*
mainid  "_main_"

%%

"def"           return DEF;
"returns"       return RETURNS;
"return"        return RETURN;
"begin"         return TBEGIN;
"end"           return END;
"if"            return IF;
"else"          return ELSE;
"var"           return VAR;
"call"          return CALL;
"bool"          return BOOL;
"TRUE"          return TRUE;

"int"           return INT;
"real"          return REAL;
"char"          return CHAR;
"type"          return TYPE;

"="             return ASSIGN;
"+"             return PLUS;
"*"             return MULT;
">"             return GT;
"<"             return LT;
":"             return COLON;
";"             return SEMICOLON;
","             return COMMA;
"("             return LPAREN;
")"             return RPAREN;

{mainid} {
    printf("[LEX] MAIN_ID: %s\n", yytext);
    yylval.str = strdup(yytext);
    return MAIN_ID;
}

{real} {
    printf("[LEX] REAL NUM: %s\n", yytext);
    yylval.str = strdup(yytext);
    return NUM;
}

{digit} {
    printf("[LEX] NUM: %s\n", yytext);
    yylval.str = strdup(yytext);
    return NUM;
}

{id} {
    printf("[LEX] ID: %s\n", yytext);
    yylval.str = strdup(yytext);
    return ID;
}

\'[^\'\\]\' {
    printf("[LEX] CHARVAL: %s\n", yytext);
    yylval.str = strdup(yytext);  // Store the character literal including quotes
    return CHARVAL;
}
[ \t\r]+      ;             // Ignore whitespace
\n            { yylineno++; }
.             ;             // Ignore unrecognized characters

%%
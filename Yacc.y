%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "symtable.h"
#include <stdbool.h>

extern char* yytext;
node* root;
extern int yylex();
extern int yylineno;

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s at line %d\n", s, yylineno);
}
%}


%union {
    char* str;
    node* nd;
}

%token <str> DEF RETURNS RETURN TBEGIN END IF ELSE VAR CALL
%token <str> INT REAL CHAR
%token <str> ASSIGN PLUS MULT GT LT COLON SEMICOLON COMMA LPAREN RPAREN
%token <str> ID NUM CHARVAL MAIN_ID
%token <str> TYPE
%token <str> TRUE
%token <str> BOOL

%type <nd> function_list
%type <nd> block maybe_var_block var_block
%type <nd> program function main_func normal_func void_func
%type <nd> param_section param param_list var_declarations
%type <nd> statement statements expression expression_list
%type <str> type
%type <str> maybe_returns


%left PLUS
%left MULT
%left GT LT
%%

program:
    function_list { root = $1; }
;

function_list:
    function_list function {
        $$ = $1;
        addSon($$, $2);
    }
  | function {
        $$ = mknode("CODE", NULL, NULL);
        addSon($$, $1);
    }
;

function:
    main_func
  | normal_func
  | void_func
;

main_func:
    DEF MAIN_ID LPAREN param_section RPAREN maybe_colon maybe_var_block maybe_returns TBEGIN statements END {
        // בדיקת החזרת ערך
        if ($8 && strcmp($8, "void") != 0) {
            fprintf(stderr, "Semantic error: _main_ must return void\n");
            exit(1);
        }

        // בדיקת פרמטרים
        if ($4 && strcmp($4->token, "PARS") == 0 && $4->children_len > 0) {
            fprintf(stderr, "Semantic error: _main_ must not take parameters\n");
            exit(1);
        }

        declare_function("_main_", "void", 0);  // תמיד רושמים אותו כ-void בלי פרמטרים

        $$ = mknode("MAIN", NULL, NULL);
        addSon($$, mknode("_main_", NULL, NULL));
        addSon($$, mknode("RET", "NONE", NULL));
        if ($7) addSon($$, $7);  // ✅ $7 = maybe_var_block

        node* body = mknode("BODY", NULL, NULL);
        if ($10) addSon(body, $10);

        addSon($$, body);
    }
;



maybe_returns:
    RETURNS type { $$ = $2; }
  | /* empty */ { $$ = NULL; }
;

maybe_var_block:
    var_block { $$ = $1; }
  | /* empty */ { $$ = NULL; }
;

var_block:
    VAR var_declarations { $$ = $2; }
;

normal_func:
    DEF ID LPAREN param_section RPAREN maybe_colon RETURNS type maybe_colon TBEGIN statements END {
        declare_function($2, "void", $4 ? $4->children_len : 0);  // או טיפוס אחר לפי ההקשר

        
        $$ = mknode("FUNC", NULL, NULL);
        addSon($$, mknode($2, NULL, NULL));
        addSon($$, $4);
        addSon($$, mknode("RET", $8, NULL));
        node* body = mknode("BODY", NULL, NULL);
        if ($11) addSon(body, $11);
        addSon($$, body);
    }
;

void_func:
    DEF ID LPAREN param_section RPAREN maybe_colon TBEGIN statements END {
        declare_function($2, "void", $4 ? $4->children_len : 0);

        $$ = mknode("FUNC", NULL, NULL);
        addSon($$, mknode($2, NULL, NULL));
        addSon($$, $4);
        addSon($$, mknode("RET", "NONE", NULL));
        node* body = mknode("BODY", NULL, NULL);
        if ($8) addSon(body, $8);
        addSon($$, body);
    }
;

maybe_colon:
    COLON
  | /* empty */
;

param_section:
    param_list {
        $$ = mknode("PARS", NULL, NULL);
        for (int i = 0; i < $1->children_len; i++) addSon($$, $1->children[i]);
    }
  | /* empty */ {
        $$ = mknode("PARS", "NONE", NULL);
    }
;

block:
    TBEGIN statements END {
        $$ = mknode("BLOCK", NULL, NULL);
        if ($2) addSon($$, $2);
    }
;

param_list:
    param SEMICOLON param_list {
        $$ = mknode("PARAMS", NULL, NULL);
        addSon($$, $1);
        for (int i = 0; i < $3->children_len; i++) addSon($$, $3->children[i]);
    }
  | param {
        $$ = mknode("PARAMS", NULL, NULL);
        addSon($$, $1);
    }
;

param:
    ID type COLON ID {
        char* val = (char*)malloc(strlen($2) + strlen($4) + 2);
        sprintf(val, "%s %s", $2, $4);
        $$ = mknode($1, val, NULL);
        free($1); free($4);
    }
;

var_declarations:
    var_declarations type COLON ID SEMICOLON {
        $$ = $1;
        char* val = (char*)malloc(strlen($2) + strlen($4) + 2);
        sprintf(val, "%s %s", $2, $4);
        addSon($$, mknode("VAR", val, NULL));
        free($4);
    }
  | type COLON ID SEMICOLON {
        $$ = mknode("VARS", NULL, NULL);
        char* val = (char*)malloc(strlen($1) + strlen($3) + 2);
        sprintf(val, "%s %s", $1, $3);
        addSon($$, mknode("VAR", val, NULL));
        free($3);
    }
  | TYPE type COLON ID SEMICOLON {
        $$ = mknode("VARS", NULL, NULL);
        char* val = (char*)malloc(strlen($2) + strlen($4) + 2);
        sprintf(val, "%s %s", $2, $4);
        addSon($$, mknode("VAR", val, NULL));
        free($4);
    }
;

type:
      INT   { $$ = "INT"; }
     | REAL  { $$ = "REAL"; }
     | CHAR  { $$ = "CHAR"; }
     | BOOL { $$ = "BOOL"; }
;

statements:
    statement statements {
        $$ = mknode("STMTS", NULL, NULL);
        addSon($$, $1); addSon($$, $2);
    }
  | /* empty */ { $$ = NULL; }
;

statement:
    ID ASSIGN expression SEMICOLON {
        $$ = mknode("=", NULL, NULL);
        addSon($$, mknode($1, NULL, NULL));
        addSon($$, $3);
    }
  | RETURN expression SEMICOLON {
        if (strcmp($2->token, "CHAR") == 0) {
            $$ = mknode("RET", $2->value, NULL);
            free($2);
        } else {
            $$ = mknode("RET", NULL, NULL);
            addSon($$, $2);
        }
    }
  | IF expression COLON block ELSE COLON block {
        $$ = mknode("IF-ELSE", NULL, NULL);
        node* cond = mknode($2->token, NULL, NULL);
        addSon(cond, $2->children[0]);
        addSon(cond, $2->children[1]);
        addSon($$, cond); addSon($$, $4); addSon($$, $7);
    }
  | TYPE type COLON ID SEMICOLON {
        char* val = (char*)malloc(strlen($2) + strlen($4) + 2);
        sprintf(val, "%s %s", $2, $4);
        $$ = mknode("VAR", val, NULL);
        free($4);
    }
  | CALL ID LPAREN RPAREN SEMICOLON {
        $$ = mknode("CALL-STMT", $2, NULL);
    }
  | CALL ID LPAREN expression_list RPAREN SEMICOLON {
        $$ = mknode("CALL-STMT", $2, NULL);
        addSon($$, $4);
    }
  | function {
        $$ = $1;
    }
  | expression SEMICOLON {
        $$ = $1;
    }
;

expression:
    expression PLUS expression {
        $$ = mknode("+", NULL, NULL); addSon($$, $1); addSon($$, $3);
    }
  | expression MULT expression {
        $$ = mknode("*", NULL, NULL); addSon($$, $1); addSon($$, $3);
    }
  | expression GT expression {
        $$ = mknode(">", NULL, NULL); addSon($$, $1); addSon($$, $3);
    }
  | expression LT expression {
        $$ = mknode("<", NULL, NULL); addSon($$, $1); addSon($$, $3);
    }
  | ID {
        $$ = mknode($1, NULL, NULL);
    }
  | NUM {
        $$ = mknode("NUM", $1, NULL);
    }
 | CHARVAL {
    char extracted_char = yytext[1];

    char* quoted_value = (char*)malloc(4);
    quoted_value[0] = '\'';
    quoted_value[1] = extracted_char;
    quoted_value[2] = '\'';
    quoted_value[3] = '\0';

    $$ = mknode("CHAR", quoted_value, NULL);
}



  | ID LPAREN RPAREN {
        $$ = mknode("CALL", $1, NULL);
    }
  | ID LPAREN expression_list RPAREN {
        $$ = mknode("CALL", $1, NULL);
        addSon($$, $3);
    }
  | TRUE {
        $$ = mknode("BOOL", $1, NULL);
    }
;

expression_list:
    expression {
        $$ = mknode("ARGS", NULL, NULL);
        addSon($$, $1);
    }
  | expression COMMA expression_list {
        $$ = mknode("ARGS", NULL, NULL);
        addSon($$, $1);
        for (int i = 0; i < $3->children_len; i++) addSon($$, $3->children[i]);
    }
;

%%

int main() {
    fprintf(stderr, "starting parse\n");
    yyparse();
    if (!validate_main_function()) {
        fprintf(stderr, "Semantic checks failed.\n");
        return 1;
    }
    fprintf(stderr, "parse finished, printing\n");
    printNode(root, 0);
    return 0;
}


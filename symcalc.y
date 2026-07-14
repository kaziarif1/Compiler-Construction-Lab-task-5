%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symcalc.h"

int yylex();
void yyerror(char *s);

/* Symbol table storage */
Symbol symtable[MAX_VARS];
int    sym_count = 0;

/* Error tracking */
int error_count = 0;
%}

%union {
    int   ival;
    char *sval;
    Node *nptr;
}

%token <ival> NUMBER
%token <sval> IDENTIFIER
%token PRINT
%type  <nptr> expr

%left '+' '-'
%left '*' '/'

%%
program:
    /* empty */
  | program stmt
  ;

stmt:
    IDENTIFIER '=' expr '\n' {
        int val = evaluate($3);
        setVar($1, val, 'I');
        printf("  --> %s = %d\n", $1, val);
        freeTree($3);
        free($1);
    }
  | PRINT IDENTIFIER '\n' {
        printf("[ print ] %s = %d\n", $2, getVar($2));
        free($2);
    }
  | expr '\n' {
        printf("  --> Result: %d\n", evaluate($1));
        freeTree($1);
    }
  | '\n' { /* blank line, ignore */ }
  ;

expr:
    expr '+' expr   { $$ = makeNode('+', $1, $3); }
  | expr '-' expr   { $$ = makeNode('-', $1, $3); }
  | expr '*' expr   { $$ = makeNode('*', $1, $3); }
  | expr '/' expr   { $$ = makeNode('/', $1, $3); }
  | NUMBER          { $$ = makeLeaf($1); }
  | IDENTIFIER      { $$ = makeVar($1); free($1); }
  ;
%%

/* ── Symbol Table functions ── */

void setVar(char *name, int value, char type){
    for (int i = 0; i < sym_count; i++){
        if (strcmp(symtable[i].name, name) == 0){
            if (symtable[i].assigned == 1){
                printf("Semantic Error: variable '%s' already assigned\n", name);
                error_count++;
                return;
            }
            symtable[i].value    = value;
            symtable[i].assigned = 1;
            symtable[i].type     = type;
            return;
        }
    }
    strcpy(symtable[sym_count].name, name);
    symtable[sym_count].value    = value;
    symtable[sym_count].assigned = 1;
    symtable[sym_count].type     = type;
    sym_count++;
}

int getVar(char *name){
    for (int i = 0; i < sym_count; i++){
        if (strcmp(symtable[i].name, name) == 0){
            if (symtable[i].assigned == 0){
                printf("Semantic Error: '%s' used before assignment\n", name);
                error_count++;
                return 0;
            }
            return symtable[i].value;
        }
    }
    printf("Semantic Error: '%s' not declared\n", name);
    error_count++;
    return 0;
}

void printSymTable(){
    printf("\n=== Symbol Table ===\n");
    if (sym_count == 0){ printf("  (empty)\n"); return; }
    for (int i = 0; i < sym_count; i++)
        printf("  %s = %d [ type : %c ]\n",
               symtable[i].name,
               symtable[i].value,
               symtable[i].type);
    printf("====================\n");
}

/* ── AST functions ── */

Node *makeNode(char op, Node *left, Node *right){
    Node *n = malloc(sizeof(Node));
    if (!n){ fprintf(stderr, "Out of memory\n"); exit(1); }
    n->op         = op;
    n->value      = 0;
    n->varname[0] = '\0';
    n->left       = left;
    n->right      = right;
    return n;
}

Node *makeLeaf(int value){
    Node *n = malloc(sizeof(Node));
    if (!n){ fprintf(stderr, "Out of memory\n"); exit(1); }
    n->op         = '\0';
    n->value      = value;
    n->varname[0] = '\0';
    n->left       = NULL;
    n->right      = NULL;
    return n;
}

Node *makeVar(char *name){
    Node *n = malloc(sizeof(Node));
    if (!n){ fprintf(stderr, "Out of memory\n"); exit(1); }
    n->op    = 'V';
    n->value = 0;
    strncpy(n->varname, name, 31);
    n->varname[31] = '\0';
    n->left        = NULL;
    n->right       = NULL;
    return n;
}

int evaluate(Node *n){
    if (n == NULL) return 0;
    if (n->op == '\0') return n->value;
    if (n->op == 'V')  return getVar(n->varname);
    int l = evaluate(n->left);
    int r = evaluate(n->right);
    if (n->op == '+') return l + r;
    if (n->op == '-') return l - r;
    if (n->op == '*') return l * r;
    if (n->op == '/'){
        if (r == 0){
            printf("Runtime Error: division by zero\n");
            error_count++;
            return 0;
        }
        return l / r;
    }
    return 0;
}

void freeTree(Node *n){
    if (n == NULL) return;
    freeTree(n->left);
    freeTree(n->right);
    free(n);
}

int main(){
    printf("Variable Calculator (Ctrl+D to quit):\n");
    printf("Usage: x = 5   or   x + 3   or   print x\n\n");
    yyparse();
    printSymTable();
    printf("Total Errors: %d\n", error_count);
    return 0;
}

void yyerror(char *s){
    printf("Syntax Error: %s\n", s);
    error_count++;
}

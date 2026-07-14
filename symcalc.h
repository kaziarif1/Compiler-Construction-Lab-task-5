/* symcalc.h */
#ifndef SYMCALC_H
#define SYMCALC_H

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/* ── AST Node ── */
typedef struct Node {
    char  op;
    int   value;
    char  varname[32];   /* used when op == 'V' (variable node) */
    struct Node *left;
    struct Node *right;
} Node;

/* ── Symbol Table ── */
#define MAX_VARS 64
typedef struct {
    char name[32];
    int  value;
    int  assigned;
    char type;      /* 'I' = integer, 'F' = float */
} Symbol;

extern Symbol symtable[MAX_VARS];
extern int    sym_count;

/* ── Error tracking ── */
extern int error_count;

/* Function declarations */
Node *makeNode(char op, Node *left, Node *right);
Node *makeLeaf(int value);
Node *makeVar(char *name);
int   evaluate(Node *n);
void  setVar(char *name, int value, char type);
int   getVar(char *name);
void  freeTree(Node *n);
void  printSymTable();

#endif

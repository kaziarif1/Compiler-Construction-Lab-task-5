%{
#include <string.h>
#include "symcalc.h"
#include "symcalc.tab.h"
%}

%%
[0-9]+               { yylval.ival = atoi(yytext);
                       return NUMBER; }

"print"              { return PRINT; }

[a-zA-Z][a-zA-Z0-9]* { yylval.sval = strdup(yytext);
                        return IDENTIFIER; }

[+\-*/=\n]           { return yytext[0]; }
[ \t]                { /* skip whitespace */ }
.                    { /* ignore unknown */ }
%%

int yywrap(){ return 1; }

/*
this is Tokenizer.c
*/

#include "Tokenizer.h"


_Bool tokenizer(struct lexics *aLex, int *numLex, FILE *inf) {

    char currentLine[LEXEME_MAX];
    char fullline[LEXEME_MAX];
    char tmparr[LEXEME_MAX];
    char leftPar[1] = "(";
    char rightPar[1] = ")";
 
    int count, countlex, c;

    int i = 0;
    while ( fgets(currentLine, MY_CHAR_MAX, inf) != NULL ) {

        for(i=0; i<LEXEME_MAX; i++) {
            if( currentLine[i] == '\n'){
                fullline[i] = '\0';
                break;
            }
            fullline[i] = currentLine[i];
            count++;
        }
        //count is = to the number of characters in that line
        // printf("%s", fullline);

        for(i=0; i<count; i++){
            if( fullline[i] == ' ' || !isalnum(fullline[i])) {
                tmparr[c] = '\0';
                if (tmparr[0] != '\0'){
                    printf("%s\n", tmparr);
                    //send tmparr to lex struct
                    countlex++;
                }
                c = 0;
            }
            if (fullline[i] != ' '){
                tmparr[c] = fullline[i];
                c++;
            }
        }

    }
    *numLex = countlex;
    return TRUE;
}
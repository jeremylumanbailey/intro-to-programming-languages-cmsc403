/*
this is Tokenizer.c
*/

#include "Tokenizer.h"


_Bool tokenizer(struct lexics *aLex, int *numLex, FILE *inf) {

    char currentLine[LEXEME_MAX];
    char fullline[LEXEME_MAX];
    char tmparr[LEXEME_MAX];
 
    int i, count, countlex, c;

    //fgets parse file line by line putting each line into currentLine array
    while ( fgets(currentLine, MY_CHAR_MAX, inf) != NULL ) {

        //Parse current line one char at a time putting each char in fullline array
        for(i=0; i<LEXEME_MAX; i++) {
            if( currentLine[i] == '\n' || currentLine[i] == '\0'){
                //End of line or file detected? Add terminator to 'fullline'
                fullline[i] = '\0';
                break;
            }
            fullline[i] = currentLine[i];
            count++;
        }

        //Iterate through fullline for lexemes
        for(i=0; i<count; i++){

            //Check if it is end of word or number, add as lexeme if it is         
            if( !isalnum(fullline[i]) && c > 0 && isalnum(tmparr[c-1]) ){
                tmparr[c] = '\0';
                strcpy(aLex[countlex].lexeme, tmparr);
                countlex++;
                c = 0;
                if( isspace(fullline[i]) ) {
                  continue;
                }

            }

            //Check if character is a special character
            if ( !isalnum(fullline[i]) && !isspace(fullline[i]) ) {
                
                //Check for binop != or == using lookahead
                if( (fullline[i] == '!' || fullline[i] == '=' ) && fullline[i+1] == '=' )

                {
                    tmparr[c] = fullline[i];
                    tmparr[c+1] = fullline[i+1];
                    tmparr[c+2] = '\0';
                    strcpy(aLex[countlex].lexeme, tmparr);
                    countlex++;
                    c = 0;
                    i++;
                    continue;
                }
                
                // Add special character as lexeme
                else {
                    tmparr[c] = fullline[i];
                    tmparr[c+1] = '\0';
                    strcpy(aLex[countlex].lexeme, tmparr);
                    countlex++;
                    c = 0;
                    continue;
                }

            }

            //Begin adding word or number as a lexeme
            if (isalnum(fullline[i])) {
                tmparr[c] = fullline[i];
                c++;
                continue;
            }

        }

    //Clear out garbage (some might not be nessisary but just in case)
    memset(fullline, '\0', sizeof(LEXEME_MAX));
    memset(currentLine, '\0', sizeof(LEXEME_MAX));
    memset(tmparr, '\0', sizeof(LEXEME_MAX));
    count = 0;
    c = 0;
    }

    //Set the value of numLex to how many lexemes were counted
    *numLex = countlex;
    return TRUE;
}
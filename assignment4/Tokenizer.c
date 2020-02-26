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
                //end of line detected? Add terminator to full line
                fullline[i] = '\0';
                break;
            }
            fullline[i] = currentLine[i];
            count++;
        }

//        printf("%s", fullline);

        for(i=0; i<count; i++){

            // if(isspace(fullline[i])) {
            //     continue;
            // }
            
            if( !isalnum(fullline[i]) && c > 0 && isalnum(tmparr[c-1]) ){
                tmparr[c] = '\0';
                strcpy(aLex[countlex].lexeme, tmparr);
                countlex++;
                c = 0;
                if( isspace(fullline[i]) ) {
                  continue;
                }

            }

            
            if ( !isalnum(fullline[i]) && !isspace(fullline[i]) ) {

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

                else {
                    tmparr[c] = fullline[i];
                    tmparr[c+1] = '\0';
                    strcpy(aLex[countlex].lexeme, tmparr);
                    countlex++;
                    c = 0;
                    continue;
                }

            }




            if (isalnum(fullline[i])) {
                tmparr[c] = fullline[i];
                c++;
                continue;
            }





        }
    memset(fullline, '\0', sizeof(LEXEME_MAX));
    memset(currentLine, '\0', sizeof(LEXEME_MAX));
    memset(tmparr, '\0', sizeof(LEXEME_MAX));
    count = 0;
    c = 0;
    }
    *numLex = countlex;
    return TRUE;
}
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


    //group these as binops
    char plussign[] = "+";
    char starsign[] = "*";
    char notequal[] = "!=";
    char isequal[] = "==";
    char modsign[] = "%";

    //individuals
    char leftparent[] = "(";
    char rightparent[] = ")";
    char leftbrack[] = "{";
    char rightbrack[] = "}";
    char equalsign[] = "=";
    char commasign[] = ",";
    char semicol[] = ";";
    char whilekey[] = "while";
    char returnkey[] = "return";

    //group these as vartypes
    char vartypevoid[] = "void";
    char vartypeint[] = "int";

    
    //iterate through all the lexemes and find their token
    for(i=0;i<countlex;i++){

        if ( 
            strcmp(aLex[i].lexeme, plussign) == 0 ||
            strcmp(aLex[i].lexeme, starsign) == 0 ||
            strcmp(aLex[i].lexeme, notequal) == 0 ||
            strcmp(aLex[i].lexeme, isequal) == 0 ||
            strcmp(aLex[i].lexeme, modsign) == 0
            ){
        aLex[i].token = BINOP;
        continue;
        }

        if ( strcmp(aLex[i].lexeme, leftparent) == 0){
        aLex[i].token = LEFT_PARENTHESIS;
        continue;
        }
    
        if ( strcmp(aLex[i].lexeme, rightparent) == 0){
        aLex[i].token = RIGHT_PARENTHESIS;
        continue;
        }

        if ( strcmp(aLex[i].lexeme, leftbrack) == 0){
        aLex[i].token = LEFT_BRACKET;
        continue;
        }

        if ( strcmp(aLex[i].lexeme, rightbrack) == 0){
        aLex[i].token = RIGHT_BRACKET;
        continue;
        }

        if ( strcmp(aLex[i].lexeme, equalsign) == 0){
        aLex[i].token = EQUAL;
        continue;
        }
        
        if ( strcmp(aLex[i].lexeme, commasign) == 0){
        aLex[i].token = COMMA;
        continue;
        }

        if ( strcmp(aLex[i].lexeme, semicol) == 0){
        aLex[i].token = EOL;
        continue;
        }

        if ( strcmp(aLex[i].lexeme, whilekey) == 0){
        aLex[i].token = WHILE_KEYWORD;
        continue;
        }

        if ( strcmp(aLex[i].lexeme, returnkey) == 0){
        aLex[i].token = RETURN_KEYWORD;
        continue;
        }

        if ( strcmp(aLex[i].lexeme, vartypeint) == 0 ||
             strcmp(aLex[i].lexeme, vartypevoid)
        ){
        aLex[i].token = VARTYPE;
        continue;
        }

        if ( validNumber(aLex[i].lexeme) ){
            aLex[i].token = NUMBER;
            continue;
        }

        if ( validIdentifier(aLex[i].lexeme) ){
            aLex[i].token = IDENTIFIER;
            continue;
        }

    }

    return TRUE;
}
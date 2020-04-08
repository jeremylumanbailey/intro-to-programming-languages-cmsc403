/*
this is Parser.c
*/

#include "Parser.h"
#include "Givens.h"



_Bool parseFunction(struct lexics *someLexics ){

    if(parseHeader(someLexics)!= TRUE)
        return FALSE;

    if(parseBody(someLexics)!=TRUE)
        return FALSE;

    
}
_Bool parseHeader(struct lexics *someLexics ){
    if ( someLexics[consume].token != VARTYPE )
        return FALSE;

    consume++;

    
    

    return TRUE;
}
_Bool parseArgdecl(struct lexics *someLexics ){
    return TRUE;
}
_Bool parseBody(struct lexics *someLexics ){

    return TRUE;
}




_Bool parser(struct lexics *someLexics, int numberOfLexics) {

    // if (!parseFunction(someLexics))
    //     return FALSE;

    // return TRUE;

    return 7;

}


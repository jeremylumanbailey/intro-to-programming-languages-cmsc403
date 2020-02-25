/*
this is Tokenizer.h
*/

#ifndef TOKENIZER_H 

#define TOKENIZER_H

#include "Givens.h"
#include "Analyzer.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

_Bool tokenizer(struct lexics *aLex, int *numLex, FILE *inf);


#endif
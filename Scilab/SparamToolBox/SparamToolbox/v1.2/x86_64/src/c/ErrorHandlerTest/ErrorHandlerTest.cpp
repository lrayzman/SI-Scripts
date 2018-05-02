#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <ctype.h>
#include "err_codes.h"
#include "err_codes.c"



SparErr Gen_Err()
{
	SparErr sparerr;
    sparerr=CreateSpErr(0, errcode15);
	
	return sparerr;
}




void main()
{
	SparErr sparerr;

	sparerr=Gen_Err();
	DestroySpErr((&sparerr));

	return;

}

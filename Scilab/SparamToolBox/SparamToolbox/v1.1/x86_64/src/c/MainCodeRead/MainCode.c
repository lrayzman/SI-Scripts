//#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
//#include <ctype.h>
//#include <errno.h>
//#define _USE_MATH_DEFINES 
//#include <math.h>
//#include "..\spar_type.h"
//#include "..\err_codes.h"

#include "..\read_tchstn.c"





int main()
{
	char filename[150]="readtest.s72p";	

	int iret=0;
	SParType *SparMat=NULL;
	SparErr sparerr;

	sparerr=read_tchstn(filename, &SparMat);

	free(SparMat);

	return iret;
}


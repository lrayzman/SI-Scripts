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
	char filename[150]="C:\\Downloads\\Input.s2p";	

	int iret=0;
	SParType *SparMat=NULL;
	SparErr sparerr;

	SCommType *SparComments = NULL;      

	
	sparerr=read_tchstn(filename, &SparMat, &SparComments);

	free(SparMat);
	free(SparComments);

	return iret;
}


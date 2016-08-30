#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#define _USE_MATH_DEFINES 
#include <math.h>
#include "..\spar_type.h"
#include "..\err_codes.h"

#include "..\read_tchstn.c"





int main()
{
	char filename[150]="E:\\scilab-5.2.0\\contrib\\SparamToolbox\\tests\\simple.s2p";	
	//char filename[150]="20in_2c_lowSNR01_14_2010_pin2pin.s12p";
	//char filename[150]="onemeter_A5A6A2A3FE.s4p";
	int iret=0;
	SParType *SparMat=NULL;
	SparErr sparerr;

	sparerr=read_tchstn(filename, &SparMat);

	free(SparMat);

	return iret;
}


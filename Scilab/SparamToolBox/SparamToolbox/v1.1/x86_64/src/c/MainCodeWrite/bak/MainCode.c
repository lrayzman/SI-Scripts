#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#define _USE_MATH_DEFINES 
#include <math.h>
#include "..\spar_type.h"
#include "..\err_codes.h"
#include "..\write_tchstn.c"



int main()
{
	char filename[150]="test_spar.s2p";	
	

	SparErr sperr;
	SParType *SparMat=NULL;

	int i;

	SparMat=(SParType*)malloc(sizeof(SParType));

	(*SparMat).nfreq=1;			// Number of frequency points
	(*SparMat).nport=2;			// Number of ports
	(*SparMat).Z0=50;			// Port impedances
	

	if(((*SparMat).freq=(double*)malloc(sizeof(double)*4))==NULL)
	{
		
		return(0);
	}

	if(((*SparMat).real=(double*)malloc(sizeof(double)*4))==NULL)
	{
		
		return(0);
	}


	if(((*SparMat).imag=(double*)malloc(sizeof(double)*4))==NULL)
	{
		
		return(0);
	}


	/* Initialize values here */


	*((*SparMat).freq)=1.005;


	for(i=0; i<4; i++)
	{
		*((*SparMat).real+i)=(double)i;
	}

	for(i=0; i<4; i++)
	{
		*((*SparMat).imag+i)=(double)(i+4);
	}


	sperr=write_tchstn(filename, &SparMat);

	free(SparMat);

	return 0;
}



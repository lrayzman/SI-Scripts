
#include "..\read_tchstn.c"
#include "..\write_tchstn.c"


int main()
{
	char filename_read[150]="..\\MainCodeRead\\20in_2c_lowSNR01_14_2010_pin2pin.s12p";
	//char filename_read[150]="..\\MainCodeRead\\onemeter_A5A6A2A3FE.s4p";
	char filename[150]="test_spar.s2p";	
	

	SparErr sperr;
	SParType *SparMat=NULL;

	SparMat=(SParType*)malloc(sizeof(SparMat));


	sperr=read_tchstn(filename_read, &SparMat);

	sperr=write_tchstn(filename, &SparMat);

	free(SparMat);

	return 0;
}



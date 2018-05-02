
#include "..\read_tchstn.c"
#include "..\write_tchstn.c"


int main()
{
	char filename_read[150]="..\\MainCodeRead\\readtest.s72p";
	char filename[150]="writetest.s12p";	
	

	SparErr sperr;
	SParType *SparMat=NULL;

	SparMat=(SParType*)malloc(sizeof(SparMat));


	sperr=read_tchstn(filename_read, &SparMat);

	sperr=write_tchstn(filename, &SparMat);

	free(SparMat);

	return 0;
}



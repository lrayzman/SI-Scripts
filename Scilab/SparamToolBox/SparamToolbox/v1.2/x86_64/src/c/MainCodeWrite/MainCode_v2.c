
#include "..\read_tchstn.c"
#include "..\write_tchstn.c"


int main()
{
	char filename_read[150]="..\\MainCodeRead\\readtest.s4p";
	char filename[150]="writetest.s12p";	
	

	SparErr sperr;
	SParType *SparMat=NULL;
	//char strComments[]="\nThis is a comment on line 1\nThis is a comment on line 2\n";

	char *strComments=NULL;

	SparMat=(SParType*)malloc(sizeof(SparMat));


	sperr=read_tchstn(filename_read, &SparMat);

	sperr=write_tchstn(filename, &SparMat, strComments);

	free(SparMat);

	return 0;
}



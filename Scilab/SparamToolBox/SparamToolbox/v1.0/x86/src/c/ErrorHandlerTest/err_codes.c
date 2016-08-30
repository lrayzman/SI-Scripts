//=========================S-parameter ToolBox====================== 
//
// S-parameter error codes supporting functions
//  
// 
// (c)2010  L. Rayzman
// 
// Created      : 01/27/2010
// Last Modified: 
// ====================================================================

/* Fill in error code structure  */
SparErr CreateSpErr(int mode, ...)		// mode currently unused
{
	SparErr sperr; 
	va_list args;
	int msglen=0;

	sperr.iErr=0; 
	sperr.pstMsg=NULL;


	va_start(args, mode);

	/* Get error code */
	sperr.iErr=va_arg(args, int);

	/* Get error string */
	msglen = _vscprintf("%s", args )+ 1;
	sperr.pstMsg = (char*)malloc( msglen * sizeof(char) );
 	vsprintf( sperr.pstMsg, "%s", args );

	return sperr;

}

/* Clean up error code structure  */
void DestroySpErr(SparErr *err)
{
	(*err).iErr=0;
	if ((*err).pstMsg != NULL)
	{
		free((*err).pstMsg);
		(*err).pstMsg=NULL;
	}
}




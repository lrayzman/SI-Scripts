//=========================S-parameter ToolBox====================== 
//
// SPTLBX_READTCHSTN()
//  
// Gateway function for READ_TCHSTN()
// 
// (c)2010-2014  L. Rayzman
// 
// Created      : 01/25/2010
// Last Modified: 02/14/2014  - Updated for x64 and 5.4.1
// ====================================================================


#include "api_scilab.h"
//#include "bool.h"
//#include "MALLOC.h"
#include "spar_type.h"
#include "err_codes.h"
#include "read_tchstn.h"



//#ifndef DBG
//#define	DBG
//#endif
/* ==================================================================== */
int sptlbx_readtchstn(char *fname, unsigned long fname_len)
{

  // S-parameter structure
  SParType *SparMat=NULL;		// Structure is initialized in the read_tchstn()
  SparErr spErr;				// Error code structure
 
    // Error management variable
    SciErr sciErr;

    //////////  Input Variables declaration //////////
    int iRows = 0;
    int iCols = 0;
    int *piAddressVar = NULL;
    int *piLen = NULL;
    char** pstData	= NULL;
    
    
    //////////  Output Variables declaration //////////
    int *piDataListAddr = NULL;
    char *pstLabels[] = {"hm", "dims", "entries"}; // For hypermatrix
    int piVecSize[] = {1 , 1, 1};
    
    double *testDouble=NULL;
    


#ifdef DBG
  sciprint("%s info: Entered sptlbx_readtchstn()\n", fname);
#endif  


    ////////// Check the number of input and output arguments //////////
    CheckInputArgument(pvApiCtx, 1, 1) ;
    CheckOutputArgument(pvApiCtx, 2, 2) ;


    ////////// Manage the input argument (string) //////////
    /* get Address of inputs */
    sciErr = getVarAddressFromPosition(pvApiCtx, 1, &piAddressVar);
    if (sciErr.iErr)
    {
        printError(&sciErr, 0);
        return 0;
    }

    /* Check that the first input argument is a string */
    if ( !isStringType(pvApiCtx, piAddressVar))
    {
        Scierror(999, "%s: Wrong type for input argument #%d: A string is expected\n", fname, 1);
        return 0;
    }

    /*  Retrieve input string */
    //first call to retrieve dimensions
    sciErr = getMatrixOfString(pvApiCtx, piAddressVar, &iRows, &iCols, NULL, NULL);
    if (sciErr.iErr)
   	{
        printError(&sciErr, 0);
		      return 0;
	   }
	   
	   //Check size of input string
	   if ((iRows != 1) && (iCols != 1))
	   {
	        Scierror(999, "%s: Wrong size for input argument: A single string is expected\n", fname, 1);
	        return 0;
	   }
	   
	   //Retrieve length of the string
	   piLen=(int*)malloc(sizeof(int)*iRows*iCols);
	   
	   //second call to retrieve length of each string
	   sciErr = getMatrixOfString(pvApiCtx, piAddressVar, &iRows, &iCols, piLen, NULL);
	   if(sciErr.iErr)
	   {
		    printError(&sciErr, 0);
		    return 0;
	   }	   
    pstData = (char**)malloc(sizeof(char*) * iRows * iCols);
    pstData[0] = (char*)malloc(sizeof(char) * (piLen[0] + 1));//+ 1 for null termination

	   //third call to retrieve data
	   sciErr = getMatrixOfString(pvApiCtx, piAddressVar, &iRows, &iCols, piLen, pstData);
	   if(sciErr.iErr)
	   {
		     printError(&sciErr, 0);
		     return 0;
	   }

#ifdef DBG
  sciprint("%s info: Input parameter: %s\n", fname, pstData[0]);
#endif  
   
    ////////// Application code //////////

    spErr = read_tchstn(pstData[0], &SparMat);
    if (spErr.iErr)
    {
        Scierror(999, "%s: touchstone read returned with error code %d: %s.\n", fname, spErr.iErr, spErr.pstMsg);
         return 0;
    }
    

#ifdef DBG
  sciprint("%s info: Finished executing read_tchstn() with error code %d\n", fname, spErr.iErr);
#endif  
       
    ////////// Create the output arguments //////////
    
   
       
    //Copy frequency vector
    sciErr = createMatrixOfDouble(pvApiCtx, nbInputArgument(pvApiCtx) + 1,  1, (*SparMat).nfreq, (*SparMat).freq);
    if(sciErr.iErr)
	   {
		     printError(&sciErr, 0);
		     return 0;
	   }


	   // Create a list for data matrices as hypermatrix
	   sciErr = createMList(pvApiCtx, nbInputArgument(pvApiCtx) + 2, 3, &piDataListAddr);
	   if (sciErr.iErr)
	   {
	        printError(&sciErr, 0);
	        return 0;
	   }
	   
	   sciErr = createMatrixOfStringInList(pvApiCtx, nbInputArgument(pvApiCtx) + 2, piDataListAddr, 1, 1, 3, &pstLabels);
	   if (sciErr.iErr)
	   {
	        printError(&sciErr, 0);
	        return 0;
	   }
	   
	   
	   piVecSize[0]=piVecSize[1]=(*SparMat).nport;
	   piVecSize[2]=(*SparMat).nfreq;
	   
	   sciErr = createMatrixOfInteger32InList(pvApiCtx, nbInputArgument(pvApiCtx) + 2, piDataListAddr,2, 1, 3, piVecSize);
	   if (sciErr.iErr)
	   {
	        printError(&sciErr, 0);
	        return 0;
	   }

#ifdef DBG
  sciprint("%s info: Starting to copy complex matrix into hypermatrix of size %dx%dx%d\n", fname, (*SparMat).nport, (*SparMat).nport, (*SparMat).nfreq);
#endif  
       
	   
	   //Copy entire data. Converted to square matrices
	   sciErr = createComplexMatrixOfDoubleInList(pvApiCtx, nbInputArgument(pvApiCtx) + 2, piDataListAddr, 3, (*SparMat).nport*(*SparMat).nport*((*SparMat).nfreq), 1, (*SparMat).real, (*SparMat).imag);
	   if (sciErr.iErr)
	   {
	        printError(&sciErr, 0);
	        return 0;
	   }

#ifdef DBG
  sciprint("%s info: Placing the output arguments on the stack\n", fname);
#endif  
	
    ////////// Return the output arguments to the Scilab engine //////////

   AssignOutputVariable(pvApiCtx, 1) = nbInputArgument(pvApiCtx) + 1;
   AssignOutputVariable(pvApiCtx, 2) = nbInputArgument(pvApiCtx) + 2;
   ReturnArguments(pvApiCtx);
   
#ifdef DBG
  sciprint("%s info: Cleaning up \n", fname);
#endif     

  
//    free(piAddressVar);
//    free(piLen); 
//    free(pstData);
    free((*SparMat).freq);
    free((*SparMat).real);
    free((*SparMat).imag);
    free(SparMat);
    DestroySpErr(&spErr);
    
#ifdef DBG
  sciprint("%s info: Finished sptlbx_readtchstn() \n", fname);
#endif         

    return 0;
}
/* ==================================================================== */




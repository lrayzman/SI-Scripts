//=========================S-parameter ToolBox====================== 
//
// SPTLBX_READTCHSTN()
//  
// Gateway function for READ_TCHSTN()
// 
// (c)2010  L. Rayzman
// 
// Created      : 01/25/2010
// Last Modified: 
// ====================================================================


#include "stack-c.h" 
#include "api_scilab.h"
#include "Scierror.h"
#include "MALLOC.h"
#include "sciprint.h"
#include "spar_type.h"
#include "err_codes.h"
#include "read_tchstn.h"



//#ifndef DBG
//#define	DBG
//#endif
/* ==================================================================== */
int sptlbx_readtchstn(char *fname)
{
  SciErr sciErr;

  
  
  // Input parameter 1
  int iRows1		= 0;
  int iCols1		= 0;
  int *piAddressVarOne = NULL;
  int *piLen1		= NULL;
  char** pstData1	= NULL;
  int iType1 = 0;  


  // Output parameter 1
  int *piDataListAddr             = NULL;
  char *pstLabels[]   = {"hm","dims","entries"};   // For hypermatrix
  int piVecSize[] = {1, 1, 1};
  int i	=0;



  // S-parameter structure
  SParType *SparMat=NULL;		// Structure is initialized in the read_tchstn()
  SparErr spErr;				// Error code structure
  
  
  static int minlhs=2, maxlhs=2, minrhs=1, maxrhs=1;

  // Check number of input parameters
  CheckRhs(minrhs, maxrhs) ;
  CheckLhs(minlhs,maxlhs) ;   
  
  // get Address of inputs
  sciErr = getVarAddressFromPosition(pvApiCtx, 1, &piAddressVarOne);
  if(sciErr.iErr)
  {
    printError(&sciErr, 0);
    return 0;
  }

  // check input variabl type 
  sciErr = getVarType(pvApiCtx, piAddressVarOne, &iType1);
  if(sciErr.iErr)
  {
    printError(&sciErr, 0);
    return 0;
  } 

  
  if ( iType1 != sci_strings )
  {
    Scierror(999,"%s: Wrong type for input argument: A string expected.\n",fname);
    return 0;
  }
 
  // Retrieve parameter1 string
  //
  //Check the size of input string
  sciErr = getMatrixOfString(pvApiCtx, piAddressVarOne, &iRows1, &iCols1, NULL, NULL);
  if(sciErr.iErr)
  { 
	printError(&sciErr, 0);
	return 0;
 }

   if ( (iRows1 != 1) && (iCols1 != 1) ) 
  {
  	Scierror(999,"%s: Wrong size for input argument: A single string is expected.\n",fname);
  	return 0;
  }

    
   //Retrieve length of the string
   piLen1 = (int*)malloc(sizeof(int));
   sciErr = getMatrixOfString(pvApiCtx, piAddressVarOne, &iRows1, &iCols1, piLen1, NULL);
   if(sciErr.iErr)
   {
 	printError(&sciErr, 0);
	return 0;
    }

   
    // Retrieve string data
    pstData1 = (char**)malloc(sizeof(char*));
    pstData1[0] = (char*)malloc(sizeof(char) * (*piLen1 + 1));  //+ 1 for null termination
    
    sciErr = getMatrixOfString(pvApiCtx, piAddressVarOne, &iRows1, &iCols1, piLen1, pstData1);
    if(sciErr.iErr)
    {
	printError(&sciErr, 0);
	return 0;
    }



   
#ifdef DBG
   sciprint("%s info: Input parameter: %s\n",fname, pstData1[0]);
#endif

  
  // Call the read routine
 spErr = read_tchstn(pstData1[0], &SparMat);
 if (spErr.iErr)
 {
	 Scierror(999,"%s: touchstone read returned with error code %d: %s.\n",fname, spErr.iErr, spErr.pstMsg);
    return 0;
 }


 #ifdef DBG
   sciprint("%s info: Rhs is: %d\n",fname, Rhs);
#endif
 

 //Copy frequency vector
 sciErr = createMatrixOfDouble(pvApiCtx, Rhs + 1, 1, (*SparMat).nfreq, (*SparMat).freq);
 if(sciErr.iErr)
 {
		printError(&sciErr, 0);
		return 0;
 }


//Create a list for data matrices as hypermatrix
 sciErr = createMList(pvApiCtx, Rhs+2, 3, &piDataListAddr);
 if(sciErr.iErr)
 {
		printError(&sciErr, 0);
		return 0;
 }


 sciErr = createMatrixOfStringInList(pvApiCtx, Rhs+2, piDataListAddr, 1, 1, 3, &pstLabels);
 if(sciErr.iErr)
 {
		printError(&sciErr, 0);
		return 0;
 }


 piVecSize[0]=piVecSize[1]=(*SparMat).nport;
 piVecSize[2]=(*SparMat).nfreq;


 sciErr =  createMatrixOfInteger32InList(pvApiCtx, Rhs+2, piDataListAddr, 2, 1, 3, piVecSize);
 if(sciErr.iErr)
 {
		printError(&sciErr, 0);
		return 0;
 }

 
 //Copy entire data. Converted to square matrices
 sciErr = createComplexMatrixOfDoubleInList(pvApiCtx, Rhs + 2, piDataListAddr, 3, (*SparMat).nport*(*SparMat).nport*(*SparMat).nfreq, 1, (*SparMat).real, (*SparMat).imag);
 if(sciErr.iErr)
 {
		printError(&sciErr, 0);
		return 0;
 }
 
  
 // Throw on the stack
 LhsVar(1) = Rhs + 1;   
 LhsVar(2) = Rhs + 2; 
  
  /* This function put on scilab stack, the lhs variable
  which are at the position lhs(i) on calling stack */
  /* You need to add PutLhsVar here because WITHOUT_ADD_PUTLHSVAR 
  was defined and equal to %t */
  /* without this, you do not need to add PutLhsVar here */
 PutLhsVar();
 
 // Clean up
 free(piAddressVarOne);
 free(piLen1); 
 free(pstData1[0]);
 free(pstData1);
 free((*SparMat).freq);
 free((*SparMat).real);
 free((*SparMat).imag);
 free(SparMat);
 DestroySpErr(&spErr);


  return 0;
}
/* ==================================================================== */




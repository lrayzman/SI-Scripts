//=========================S-parameter ToolBox====================== 
//
// SPTLBX_WRITETCHSTN()
//  
// Gateway function for WRITE_TCHSTN()
// 
// (c)2010  L. Rayzman
// 
// Created      : 02/01/2010
// Last Modified: 
// ====================================================================


#include <string.h>
#include "stack-c.h" 
#include "api_scilab.h"
#include "Scierror.h"
#include "MALLOC.h"
#include "sciprint.h"
#include "spar_type.h"
#include "err_codes.h"
#include "write_tchstn.h"




//#ifndef DBG
//#define	DBG
//#endif
/* ==================================================================== */
int sptlbx_writetchstn(char *fname)
{
  SciErr sciErr;
  
  // Input parameter 1
  int iRows1		= 0;
  int iCols1		= 0;
  int *piAddressVarOne = NULL;
  int *piLen1		= NULL;
  char** pstData1	= NULL;
  int iType1 = 0;  

    // Input parameter 2
  int iRows2		= 0;
  int iCols2		= 0;
  int *piAddressVarTwo = NULL;
  int iType2 = 0;  

      // Input parameter 3
  int iRows3		= 0;
  int iCols3		= 0;
  int *piAddressVarThree = NULL;
  int iType3 = 0;  
  int iListItemNum = 0;
  int *piListItemChild = NULL;
  int *piLen3		= NULL;
  char** pstData3	= NULL;
  int *piDimsData   = NULL;
  int i=0;


  SparErr spErr;				// Error code structure

  static int minlhs=0, maxlhs=0, minrhs=3, maxrhs=3;

  // S-parameter structure
  SParType *SparMat=NULL;				// Structure is initialized in the read_tchstn()
  SparMat=(SParType*)malloc(sizeof(SParType));

  (*SparMat).Z0=50;
  
  // Check number of input parameters
  CheckRhs(minrhs, maxrhs);
 // CheckLhs(minlhs,maxlhs);   

/* Argument 1 - Filename */
  
  // get Address of inputs
  sciErr = getVarAddressFromPosition(pvApiCtx, 1, &piAddressVarOne);
  if(sciErr.iErr)
  {
	

    printError(&sciErr, 0);
    return 0;
  }


  // check input variable type for argument 1
  sciErr = getVarType(pvApiCtx, piAddressVarOne, &iType1);
  if(sciErr.iErr)
  {
    free(piAddressVarOne);
    printError(&sciErr, 0);
    return 0;
  } 

  
  if ( iType1 != sci_strings )
  {
     free(piAddressVarOne);
    Scierror(999,"%s: Wrong type for input argument 1: A string expected.\n",fname);
    return 0;
  }
 
  // Retrieve parameter1 string
  //
  //Check the size of input string
  sciErr = getMatrixOfString(pvApiCtx, piAddressVarOne, &iRows1, &iCols1, NULL, NULL);
  if(sciErr.iErr)
  { 
    free(piAddressVarOne);
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
     free(piAddressVarOne);
	 free(piLen1); 
	 printError(&sciErr, 0);
	return 0;
    }

   
    // Retrieve string data
    pstData1 = (char**)malloc(sizeof(char*));
    pstData1[0] = (char*)malloc(sizeof(char) * (*piLen1 + 1));  //+ 1 for null termination
    
    sciErr = getMatrixOfString(pvApiCtx, piAddressVarOne, &iRows1, &iCols1, piLen1, pstData1);
    if(sciErr.iErr)
    {
		free(piAddressVarOne);
		free(piLen1); 
		free(pstData1[0]);
		free(pstData1);
	
		printError(&sciErr, 0);
		return 0;
    }

#ifdef DBG
   sciprint("%s info: Got input parameter 1: %s\n",fname, pstData1[0]);
#endif



/* Argument 2 - Frequency vector */

   // get Address of inputs
  sciErr = getVarAddressFromPosition(pvApiCtx, 2, &piAddressVarTwo);
  if(sciErr.iErr)
  {
		free(piAddressVarOne);
		free(piLen1); 
		free(pstData1[0]);
		free(pstData1);

		printError(&sciErr, 0);
    return 0;
  }

   // check input variable type for argument 2
  sciErr = getVarType(pvApiCtx, piAddressVarTwo, &iType2);
  if(sciErr.iErr)
  {
	  free(piAddressVarOne);
	  free(piLen1); 
	  free(pstData1[0]);
	  free(pstData1);
	
	  free(piAddressVarTwo);
	 
    printError(&sciErr, 0);
    return 0;
  } 

  //Check that the vector a matrix type
  if( iType2 != sci_matrix )
  {
    free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	  
	Scierror(999,"%s: Wrong type for input argument 2: A vector is expected.\n",fname);
    return 0;
  }

  //Check that the vector is real-valued
  if(isVarComplex(pvApiCtx, piAddressVarTwo))
  {
    free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 
	  
	  Scierror(999,"%s: Wrong type for input argument 2: A real valued vector is expected.\n",fname);
    return 0;
  }

 //Check the dimensions
 sciErr = getVarDimension(pvApiCtx, piAddressVarTwo, &iRows2, &iCols2);
 if(sciErr.iErr)
 {
	 free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);

    
	 printError(&sciErr, 0);
    return 0;
 } 

 if(iRows2 != 1)
 {
	 free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 
	 Scierror(999,"%s: Wrong dimension for input argument 2: Frequency vector must be a single row vector\n",fname);
    return 0;
 }


 //Size of vector
 (*SparMat).nfreq=iCols2;


 //Get frequency values
 sciErr =  getMatrixOfDouble(pvApiCtx, piAddressVarTwo, &iRows2, &iCols2, &((*SparMat).freq));
 if(sciErr.iErr)
 {
    free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 printError(&sciErr, 0);
    return 0;
 } 

#ifdef DBG
   sciprint("%s info: Got input parameter 2 of size: %d\n",fname, (*SparMat).nfreq);
#endif

/* Argument 3 - Data matrices */

    // get Address of inputs
  sciErr = getVarAddressFromPosition(pvApiCtx, 3, &piAddressVarThree);
  if(sciErr.iErr)
  {
    
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 
	 printError(&sciErr, 0);
    return 0;
  }

    // check input variable type for argument 3
  sciErr = getVarType(pvApiCtx, piAddressVarThree, &iType3);
  if(sciErr.iErr)
  {
    
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	  printError(&sciErr, 0);
    return 0;
  } 

  
  if ( iType3 != sci_mlist )
  {
    free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	  
	  Scierror(999,"%s: Wrong type for input argument 3: A hypermatrix is expected.\n",fname);
    return 0;
  }

#ifdef DBG
   sciprint("%s info: Got to check type of input parameter 3\n",fname);
#endif




  //Get number of items in a list
  sciErr = getListItemNumber(pvApiCtx, piAddressVarThree, &iListItemNum);
  if(sciErr.iErr)
  {
	
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	  printError(&sciErr, 0);
		return 0;
  }

  if (iListItemNum != 3)
  {
	free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 
	  Scierror(999,"%s: Wrong type for input argument 3: A hypermatrix is expected.\n",fname);
    return 0;
  }

#ifdef DBG
   sciprint("%s info: Got to check number of entries of input parameter 3\n",fname);
#endif

  //Confirm hypermatrix string in first position on the list
  sciErr = getListItemAddress(pvApiCtx, piAddressVarThree, 1, &piListItemChild);
  if(sciErr.iErr)
  {
	
	free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
     printError(&sciErr, 0);
	return 0;
  }

  sciErr = getVarType(pvApiCtx, piListItemChild, &iType3);
  if(sciErr.iErr)
  {
    free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 	  
	  printError(&sciErr, 0);
    return 0;
  } 

  
  if ( iType3 != sci_strings )
  {
    
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
     Scierror(999,"%s: Wrong type for input argument 3: A hypermatrix is expected.\n",fname);
    return 0;
  }

#ifdef DBG
   sciprint("%s info: Got to check string type of input parameter 3\n",fname);
#endif

  sciErr = getMatrixOfStringInList(pvApiCtx, piAddressVarThree, 1, &iRows3, &iCols3, NULL, NULL);
  if(sciErr.iErr)
  {
	free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	  
	  printError(&sciErr, 0);
	return 0;
  }

   if ( (iRows3 != 1) && (iCols3 != 3) ) 
  {
  	
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	  
	  Scierror(999,"%s: Wrong type for input argument 3: A hypermatrix is expected.\n",fname);
  	return 0;
  }

#ifdef DBG
   sciprint("%s info: Got to check string matrix size of input parameter 3\n",fname);
#endif

  piLen3 = (int*)malloc(sizeof(int) * iRows3 * iCols3);
  sciErr = getMatrixOfStringInList(pvApiCtx, piAddressVarThree, 1, &iRows3, &iCols3, piLen3, NULL);
  if(sciErr.iErr)
  {

	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	  
	  printError(&sciErr, 0);
		return 0;
  }

  pstData3 = (char**)malloc(sizeof(char*) * iRows3 * iCols3);
  for(i = 0; i < iRows3 * iCols3; i++)
  {
		pstData3[i] = (char*)malloc(sizeof(char) * (piLen3[i] + 1));//+ 1 for null termination
  }

  sciErr = getMatrixOfStringInList(pvApiCtx, piAddressVarThree, 1, &iRows3, &iCols3, piLen3, pstData3);
  if(sciErr.iErr)
  {
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);
		
	  printError(&sciErr, 0);
		return 0;
  }

#ifdef DBG
  sciprint("%s info: String values of input parameter 3: %s, %s, %s\n",fname, pstData3[0], pstData3[1], pstData3[2]);
#endif

   if(strcmp(pstData3[0], "hm") || strcmp(pstData3[1], "dims") || strcmp(pstData3[2], "entries"))
   {
	
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);

	  
	  Scierror(999,"%s: Wrong type for input argument 3: A hypermatrix is expected.\n",fname);
  	return 0;
  }

#ifdef DBG
   sciprint("%s info: Got to check string values of input parameter 3\n",fname);
#endif

  //Get the hypermatrix dimensions as second item on the list
  sciErr = getListItemAddress(pvApiCtx, piAddressVarThree, 2, &piListItemChild);
  if(sciErr.iErr)
  {
	free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);
	  printError(&sciErr, 0);
		return 0;
  }

  sciErr = getVarType(pvApiCtx, piListItemChild, &iType3);
  if(sciErr.iErr)
  {
    
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);
 
	 printError(&sciErr, 0);
    return 0;
  } 

  if (iType3 != sci_ints )
  {
    
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);

	 Scierror(999,"%s: Wrong type for input argument 3: A hypermatrix is expected.\n",fname);
    return 0;
  }

#ifdef DBG
   sciprint("%s info: Got to check dimension vector type of input parameter 3\n",fname);
#endif

  sciErr = getVarDimension(pvApiCtx, piListItemChild, &iRows3, &iCols3);
  if(sciErr.iErr)
  {
    free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 	  
	  printError(&sciErr, 0);
    return 0;
  } 


  if(iRows3 != 1 || iCols3 != 3)
  {

	      free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 Scierror(999,"%s: Wrong type for input argument 3: A hypermatrix is expected.\n",fname);
     return 0;
  }

#ifdef DBG
   sciprint("%s info: Got to check dimensions of dimension vector type of input parameter 3\n",fname);
#endif
  

  sciErr = getMatrixOfInteger32InList(pvApiCtx, piAddressVarThree, 2, &iRows3, &iCols3, &piDimsData);
  if(sciErr.iErr)
  {
    
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);

    printError(&sciErr, 0);
    return 0;
  } 


  //Matrix must be square
  if(piDimsData[0] != piDimsData[1])
  {
    
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);
	 free(piDimsData);


	  Scierror(999,"%s: Wrong matrix dimensions for input argument 3: Matrices must be square.\n",fname);
    return 0;
  }

  if(piDimsData[0] < 1)
  {
    free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);
	 free(piDimsData);

    Scierror(999,"%s: Wrong matrix dimensions for input argument 3: Matrices cannot be empty\n",fname);
    return 0;
  }

  (*SparMat).nport=piDimsData[0];

  //Check that number of frequency points is correct
  if(piDimsData[2] != (*SparMat).nfreq)
  {
	free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);
	 free(piDimsData);

	  Scierror(999,"%s: Incompatible dimensions of frequency vector and data matrices\n",fname);
    return 0;
  }


  //Copy the data that is the third item on the list
  sciErr = getListItemAddress(pvApiCtx, piAddressVarThree, 3, &piListItemChild);
  if(sciErr.iErr)
  {
	free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);
	 free(piDimsData);

	  printError(&sciErr, 0);
		return 0;
  }

   sciErr = getVarType(pvApiCtx, piListItemChild, &iType3);
  if(sciErr.iErr)
  {
    
	  free(piAddressVarOne);
		 free(piLen1); 
		 free(pstData1[0]);
		 free(pstData1);

		 free(piAddressVarTwo);
		 
		 free(piAddressVarThree);
		 free(piListItemChild);
		 free(piLen3); 
		 free(pstData3[0]);
		 free(pstData3[1]);
		 free(pstData3[2]);
		 free(pstData3);
		 free(piDimsData);
	  
	  printError(&sciErr, 0);
    return 0;
  } 

  if (iType3 != sci_matrix )
  {
    free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);
	 free(piDimsData);

	  Scierror(999,"%s: Wrong type for input argument 3: A hypermatrix is expected.\n",fname);
    return 0;
  }

#ifdef DBG
	sciprint("%s info: Number of ports saved in SparMat: %d\n",fname, (*SparMat).nport);
#endif

  sciErr = getComplexMatrixOfDoubleInList(pvApiCtx, piAddressVarThree, 3, &iRows3, &iCols3, &((*SparMat).real), &((*SparMat).imag));
  if(sciErr.iErr)
  {
	  free(piAddressVarOne);
	 free(piLen1); 
	 free(pstData1[0]);
	 free(pstData1);

	 free(piAddressVarTwo);
	 
	 free(piAddressVarThree);
	 free(piListItemChild);
	 free(piLen3); 
	 free(pstData3[0]);
	 free(pstData3[1]);
	 free(pstData3[2]);
	 free(pstData3);
	 free(piDimsData);

    printError(&sciErr, 0);
    return 0;
  }

#ifdef DBG
	sciprint("%s info: Input parameter 3 read in %dx%d entries\n",fname, iRows3, iCols3);
#endif


#ifdef DBG
	sciprint("%s info: Got input parameter 3 of size: %dx%dx%d\n",fname, piDimsData[0], piDimsData[1], piDimsData[2] );
	sciprint("%s info: Number of ports saved in SparMat: %d\n",fname, (*SparMat).nport);
#endif


 // Call the write routine
 spErr = write_tchstn(pstData1[0], &SparMat);
 if (spErr.iErr)
 {
	 Scierror(999,"%s: touchstone write returned with error code %d: %s.\n",fname, spErr.iErr, spErr.pstMsg);
 }

  
 // Nothing to throw on the stack
 
 
 // Clean up
 free(piAddressVarOne);

 free(piLen1); 
 free(pstData1[0]);
 free(pstData1);

 free(piAddressVarTwo);

 free(piAddressVarThree);
 free(piListItemChild);
 free(piLen3); 
 free(pstData3[0]);
 free(pstData3[1]);
 free(pstData3[2]);
 free(pstData3);
 free(piDimsData);


 //free((*SparMat).freq);	// Assume these are cleaned up by the "get" function???
 //free((*SparMat).real);
 //free((*SparMat).imag);
 free(SparMat);
 DestroySpErr(&spErr);


 return 0;
}
/* ==================================================================== */





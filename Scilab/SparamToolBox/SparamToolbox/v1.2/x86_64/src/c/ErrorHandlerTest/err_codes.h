//=========================S-parameter ToolBox====================== 
//
// S-parameter error codes definition
//  
// 
// (c)2010  L. Rayzman
// 
// Created      : 01/17/2010
// Last Modified: 
// ====================================================================

#ifndef __ERR_CODE_H__
#define __ERR_CODE_H__

typedef struct Spar_Err
{
	int iErr; /* error code */
	char* pstMsg; /* error message */
} SparErr;


#define errcode0 0, "Return OK"			// Return OK
#define errcode1 1, "Invalid filename"
#define errcode2 2, "File extension has invalid format"
#define errcode3 3,	"Unable to access file"
#define errcode4 4,	"Unable to allocate memory for file read"
#define errcode5 5,	"Error reading file"
#define errcode6 6,	"Unable to allocate memory"
#define errcode7 7,	"Parsing error: expecting commented line or options line"
#define errcode8 8,	"Parsing error: reached end-of-file before options line"
#define errcode9 9,	"Parsing error: invalid parameter in options line"
#define errcode10 10, "Parsing error: unsupported touchstone format in options line"
#define errcode11 11, "Unable to allocate memory for S-param matrix"
#define errcode12 12, "Parsing error: invalid format of floating-point value"
#define errcode13 13, "Parsing error:  unexpected number of tokens in data line"
#define errcode14 14, "Unexpected format type"
#define errcode15 15, "Parsing error: expecting frequency to increase"
#define errcode1000 1000, "Unexpected error"

/* Fill in error code structure  */

SparErr CreateSpErr(int mode, ...);
void DestroySpErr(SparErr *err);

#endif /* __ERR_CODE_H__ */



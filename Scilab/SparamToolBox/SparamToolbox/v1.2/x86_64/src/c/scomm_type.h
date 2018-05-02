//=========================S-parameter ToolBox====================== 
//
// S-parameter comment definition
//  
// 
// (c)2015  L. Rayzman
// 
// Created      : 08/18/2015
// Last Modified: 
// ====================================================================

#ifndef __SCOMM_STRUCT_H__
#define __SCOMM_STRUCT_H__

typedef struct SComm
{
	int nlines;	      // Number of comment lines in array
	char **commArr;   // Comments array
	
} SCommType;

#endif /* __SCOMM_STRUCT_H__ */


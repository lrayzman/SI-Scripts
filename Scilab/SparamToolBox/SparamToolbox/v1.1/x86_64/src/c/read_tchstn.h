//=========================S-parameter ToolBox====================== 
//
// READ_TCHSTN()
//  
// Touchstone file reader header file
// 
// (c)2010  L. Rayzman
// 
// Created      : 01/17/2010
// Last Modified: 
// ====================================================================

#ifndef __READTCHSTN_H__
#define __READTCHSTN_H__

int fetchline(char *pindatastream, char **pdataline, int* pIdx, int iFileEndIdx);
SparErr read_tchstn(char *filename, SParType **spmat);


#endif /* __READTCHSTN_H__ */


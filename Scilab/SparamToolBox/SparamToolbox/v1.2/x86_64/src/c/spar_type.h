//=========================S-parameter ToolBox====================== 
//
// S-parameter structure definition
//  
// 
// (c)2010  L. Rayzman
// 
// Created      : 01/17/2010
// Last Modified: 
// ====================================================================

#ifndef __SPAR_STRUCT_H__
#define __SPAR_STRUCT_H__

typedef struct SPar
{
	int nport;		// Number of ports
	int nfreq;		// Number of frequencies
	double Z0;		// Port impedance
	double *freq;		// Frequency vector
	double *real;		// Real part of s-param matrix
	double *imag;		// imag part of s-param matrix
	
} SParType;

#endif /* __SPAR_STRUCT_H__ */


//**************************************************
// Simple script to calculate Parallel Plate 
// capacitance given it's Width & Length (area), 
// plate separation, and Relative dielectric constant
//
// Assuming lumped capacitance (i.e. plate geometry
// is electrically much smaller than plane noise)
//
//
// Based on equations found H. Johnson's 
// Advanced Signal Propagation
// 

//*****************SPECIFY*************************

W=1;                               //Trace width (inches)
L=1;                               //Length (inches)
S=0.006;                           //Plate separation (inches)
er=4.5;                            //Relative dielectric constant
//*************************************************

function [C]=Cplate(W,L,S,er)
C=2.249e-13*(er*W*L/S)*1e12
endfunction

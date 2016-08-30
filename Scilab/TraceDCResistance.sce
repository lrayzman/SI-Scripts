//**************************************************
// Simple script to calculate Trace DC resistance
// given it's length and width
//
// Rectangular trace width assumed
//
// Based on equations found H. Johnson's 
// Advanced Signal Propagation
// 

//*****************SPECIFY*************************

W=0.01;                            //Trace width (inches)
L=1;                               //Length (inches)
Oz=0.5;                            //Copper weight (Oz)
//*************************************************

function [Rdc]=Rdc(W,L,Oz)
Rdc=(4.798*10e-4/((W/39.37007874015748031496062992126)*Oz))*(L/39.37007874015748031496062992126);
endfunction

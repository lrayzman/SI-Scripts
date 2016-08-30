// Q-function
//
// (c)2011  L. Rayzman
// Created :      10/18/2011
// Last Modified: 10/18/2011 - Added Eye Measurement Tool

//////////////////////////////////////Q-Function////////////////////////////////////
function Qofx = Qfunc(x)

//  Extracts waveform data from CSDF ASCII files
//
// Inputs:
//        x     - Self-explanatory
//
//  Outputs:
//     Qofx     - Self-explanatory

Qofx = 0.5 * erfc(x/sqrt(2)); 
endfunction

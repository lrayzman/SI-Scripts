// LCRY_ASA4 EQ TF check
//
// (c)2013  L. Rayzman
// Created :      02/12/2013
// Last Modified: 02/12/2013
//
// TODO: 
// 

//stacksize(96*1024*1024);
clear;		


//////////////////////////////////   SPECIFY   /////////////////////////////////

ADC=1;                                      // ADC  0.4=6dB gain, 1=0dB gain
DCGDB=6;

Hf_fpole1=5e9;                              // Frequency of pole 1
Hf_fpole2=20e9;                             // Frequency of pole 2                               

////////////////////////////////////////////////////////////////////////////////

p=poly(0, 's');

v=1e7:10e6:100e9;                                //Generate frequency matrix
frequencies=%i*v*2*%pi;

GDC=10^(DCGDB/20)/ADC;

Hf_ohmegap1=2*%pi*Hf_fpole1
Hf_ohmegap2=2*%pi*Hf_fpole2
//Hf_ohmegaz1=2*%pi*Hf_fpole1*ADC                 // Compute zeros and poles


/////////////////EQ Transfer Function ////////////////////////////

Hf_ofs = GDC*Hf_ohmegap2*(p+Hf_ohmegap1*ADC)/((p+Hf_ohmegap1)*(p+Hf_ohmegap2));

Hf_Response = freq(Hf_ofs.num, Hf_ofs.den, frequencies);

scf(0);
gainplot(v, [Hf_Response]);                                            // Plot
xtitle(" ", "Frequency (Hz)", "Magnitude(dB)");

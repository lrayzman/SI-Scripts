// PERT Sync Phase-Error vs Modulation Frequency response
//
// (c)2011  L. Rayzman
// Created :      11/09/2011
// Last Modified: 11/09/2011
//
// TODO: 
// 

//stacksize(96*1024*1024);
clear;		


//////////////////////////////////   SPECIFY   /////////////////////////////////

Hf_zeta = 0.707;                            // FPGA transmitter zeta
Hf_3db = 2e6;                              // FPGA transmitter -3dB frequency

tau=5e-9;                                 // Delay delta between FPGA branch and Direct branch

////////////////////////////////////////////////////////////////////////////////

p=poly(0, 's');

v=0.001e6:0.01e6:100e6; 									//Generate frequency matrix
frequencies=%i*v*2*%pi;



/////////////////FPGA Transmitter Transfer Function ////////////////////////////

Hf_ohmega_n = Hf_3db * 2*%pi / (sqrt(1+2*Hf_zeta^2 + sqrt((1+2*Hf_zeta^2)^2 + 1)));

Hf = (2*p*Hf_zeta*Hf_ohmega_n + Hf_ohmega_n^2) / (p^2 + 2*p*Hf_zeta*Hf_ohmega_n + Hf_ohmega_n^2);

Hf_Response = freq(Hf.num, Hf.den, frequencies);

//xinit(1);
scf(1);
gainplot(v, [Hf_Response]);                                            // Plot
xtitle(" ", "Frequency (Hz)", "Magnitude(dB)");



/////////////////MAIN PATH DELAY ////////////////////////////
//******************** Delay ******************************														
																																

/////////////////FPGA PATH DELAY ////////////////////////////
HDelayTau_Response = (exp(-tau * frequencies));

/////////////////Phase error transfer Function ////////////////////////////

H_of_s_Response1 = ((%i*frequencies)^(-1)).*(1-Hf_Response);
H_of_s_Response2 = ((%i*frequencies)^(-1)).*(1-Hf_Response.*HDelayTau_Response);


scf(2);
gainplot(v, [H_of_s_Response1.*frequencies; H_of_s_Response2.*frequencies],["Delay Delta=0ns"; "Delay=5ns"]);                       // Plot of phase/phase gain                                 
xtitle(" ", "Frequency (Hz)", "Phase Error  (sec/sec dB)");

scf(3);
gainplot(v, [H_of_s_Response1; H_of_s_Response2],["Delay Delta=0ns"; "Delay Delta=5ns"]);                                   // Plot of phase/FM gain         
xtitle(" ", "Frequency (Hz)", "Phase Error Gain (sec/Hz dB)");

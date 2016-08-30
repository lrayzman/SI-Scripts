//**************************************************
// Guassian Low Pass Filter PSPICE subckt creator
//
// Based on equations found in chapter 4 of H. Johnson's 
// Advanced Signal Propagation
// 

//*****************SPECIFY*************************

Filename="GaussLPF.lib";										//Output filename

Trf=50e-12;																//Rise/fall time
Delay=2.5e-9;																//Filter response delay

UppFreq=100e9;																//Upper frequency point
NumFPts=2501;																//Number of frequency points

//*************************************************


Fhandle=file('open', Filename, 'old');

fprintf(Fhandle, "*	IN OUT \n");
fprintf(Fhandle, ".SUBCKT GaussLPF 1 2 3\n");
fprintf(Fhandle, "EGAUSS 2 3 FREQ {V(1, 3)} = R_I\n");

for  i=0:NumFPts-1,
	Freq=i*(UppFreq/(NumFPts-1));
	fprintf(Fhandle, "+(%0.2f, %0.14e, 0)\n", Freq, exp(-(Freq^2)*1/0.31*(Trf)^2));
end
//																															^ This factor was experimentally determined

if Delay > 0 then
	fprintf(Fhandle, "+DELAY=%e\n", Delay);
end


fprintf(Fhandle, ".ENDS\n");

file('close', Fhandle);

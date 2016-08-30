//**************************************************
// Guassian Low Pass Filter HSPICE subckt creator
//
// Based on equations found in chapter 4 of H. Johnson's 
// Advanced Signal Propagation
// 

//*****************SPECIFY*************************

Filename="GaussLPF.sub";										//Output filename

Trf=30e-12;																//Rise/fall time (10%-90%)
Delay=0.2e-9;																//Filter response delay

UppFreq=300e9;																//Upper frequency point
NumFPts=30001;																//Number of frequency points

//*************************************************


Fhandle=file('open', Filename, 'old');


fprintf(Fhandle, "*	Trf=%0.3f ps,  \n", Trf*1e12);
fprintf(Fhandle, "*	Min Timestep =%0.3f ps,  \n", 1/UppFreq*1e12);, 
fprintf(Fhandle, "*	IN OUT GND \n");
fprintf(Fhandle, ".SUBCKT GaussLPF 1 2 3\n");
fprintf(Fhandle, "EGAUSS 2 3 FREQ 1 3 \n");

DeltaF = (UppFreq/(NumFPts-1));

for  i=0:NumFPts-1,
	Freq=i*DeltaF;
	Ph = -i*DeltaF*2*Delay*180;
	fprintf(Fhandle, "+ %0.2f %0.14e %0.14e\n", Freq, 20*log10(exp(-(Freq^2)*1/0.31*(Trf)^2)), Ph );
end
//																															            ^ This factor was determined empirically

//if Delay > 0 then
//	fprintf(Fhandle, "+DELAY=%e\n", Delay);
//end


fprintf(Fhandle, ".ENDS\n");

file('close', Fhandle);

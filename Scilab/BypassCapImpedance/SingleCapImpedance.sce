//  Impedance profile of a single capacitor (simplified LRC model)
// Output being a csv file that can be used to drive SPICE simulations


stacksize(64*1024*1024);

clear;																							//Clear user variables


//////////////////////////////////////////////////SPECIFY//////////////////////////////////////////////////////
		
C1 = 100e-9;                                    //Series capacitance
L1 = 1e-9;                                      //Series inductance        
R1 = 0.01;                                       //Series resistance

NumOfCaps=2;                                    //Number of parallel caps

FreqRange=1e6:1e6:10e9;                         //Frequency range

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

C1=C1*NumOfCaps;
L1=L1/NumOfCaps;
R1=R1/NumOfCaps

//Plot single cap
Z_freq=sqrt(R1^2+FreqRange^2*L1^2-2*L1/C1+(FreqRange^2*C1^2)^(-1));


plot2d(FreqRange, Z_freq , logflag="ll", style=5);

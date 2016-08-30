//  Impedance profile of two parallel capacitors (simplified LRC model)
// Output being a csv file that can be used to drive SPICE simulations


stacksize(64*1024*1024);

clear;																							//Clear user variables


//////////////////////////////////////////////////SPECIFY//////////////////////////////////////////////////////
		                                            //Cap1
C1 = 100e-9;                                    //Series capacitance
L1 = 1e-9;                                      //Series inductance        
R1 = 0.01;                                       //Series resistance
NumOfCaps1=1;
                                                //Cap2
C2 = 10e-9;                                    //Series capacitance
L2 = 0.8e-9;                                      //Series inductance        
R2 = 0.01;                                       //Series resistance
NumOfCaps2=1;

FreqRange=1e6:1e6:10e9;                         //Frequency range

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

C1=C1*NumOfCaps1;
L1=L1/NumOfCaps1;
R1=R1/NumOfCaps1;

C2=C2*NumOfCaps2;
L2=L2/NumOfCaps2;
R2=R2/NumOfCaps2;

//Plot single cap
X1=FreqRange*L1-(FreqRange*C1)^(-1);
X2=FreqRange*L2-(FreqRange*C2)^(-1);

Z_freqRe=(R2*R1^2+R1*R2^2+R1*X2.*(X1+X2)+R2*X1.*(X1+X2)-R1*X1.*X2-R2*X1.*X2)./((R1^2+2*R1*R2+R2^2)+(X1+X2)^2);
Z_freqIm=(-R1*R2*(X1+X2)+R1^2*X2+R1*R2*X2+R1*R2*X1+R2^2*X1+X1.*X2.*(X1+X2))./((R1^2+2*R1*R2+R2^2)+(X1+X2)^2);


Z_freq=sqrt(Z_freqRe^2+Z_freqIm^2);

resonance=sqrt((C1+C2)/((L1+L2)*C1*C2));
printf("Anti-resonance is at %f MHz\n", resonance/1e6)

plot2d(FreqRange, Z_freq, logflag="ll", style=2);

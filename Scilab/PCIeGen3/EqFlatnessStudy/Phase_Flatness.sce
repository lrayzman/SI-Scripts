//Simulation of Lossy transmission line based on algorithms outlined in 
// Dr. H. Johnson's High Speed Signal Propagation , Ch 4.

stacksize(16*1024*1024);

clear;																													//Clear all user created variables


//Data Sequences Constants

K=2;																													//Oversampling ratio

Tbit=125*10^(-12);																													// Bit interval

//Constants

deltaT =  Tbit / K;																													//Sampling resolution

Nbit = 1024;																											        // Number of bits in sequence

N=round(2^(ceil(log(Nbit*K)/log(2))));																								                    //Length of sample vector

k=[0:1:N-1];  																													//Index of frequency points

f=k/(N*deltaT);																													//Vector of frequency points (Hz)

f(1)=f(2)/10^9;


//SPECIFY
LPF=50*10^(-12);																													//LPF: rise/fall time(S)																								

Rs=50;																													//Source resistance
Ls=0*10^(-9);																													//Source inductance

TRdc=6.1;																													//TLine DC resistance
Tf0= 2*%pi*10^9;																													//TLine ohmega zero
TR0=40.7;																													//TLine AC resistance
Ttheta0=0.027;																													//TLine dielectric loss angle
TZ0=50;																													//TLine characteriztic impedance
Tv0=1.4457*10^8;																													//Tline velocity (m/s)
TL=0.2;																													//Tline length (m)


Rl=50;																													//Load resistance
Cl=0.0*10^(-12);																													//Load capacitance

//******************* Gaussian LPF ************************//

function [x] = Gausk(r, deltaT, N, k)
qgaussian =0.275 * r;
x=zeros(k);
for m=0:N/2-1
 if ((2 * %pi * m)/(N * deltaT) * qgaussian) > 7 then
 		x(m+1) = 0;
 else
 	 x(m+1) = exp (-((2 * %pi * m) / (N * deltaT))^2 * qgaussian^2); 
 
 end
end

for m=0:N/2-1
  x(m+N/2+1) = x(N/2 - m)
end

endfunction

//***********************************************************//






//**************Source, Line, Load impedances***************//

//Source Impedance
//Input:
//				res: source resistance
//			  ind:  series inductance
//				fr: evaluate at frequency(hz)

function [Z]=ZS(res, ind, fr)
Z=res + %i*2*%pi*fr*ind;
endfunction



//Tline transfer function
//Input:
//				Rdc: DC resistance of conductor				
//       R0: real part of AC resistance at fr0
//				theta0: angle formed by real and imaginary parts of complex permittivity at fr0
//				zc0: characteristic impedance at fr0
//				v0: velocity at fr0 (m/s)
//				len; length of tline (m)
//			  fr0: frequency at which parameters are specified
//				fr: evaluated at frequency(hz)
function [H]=HT(Rdc, R0, theta0, zc0, v0, len,  fr0,  fr)

Rac = R0 * (1 + %i)*sqrt(2*%pi*fr / fr0);

R = sqrt(Rdc^2 + Rac^2);

L = zc0 / v0;

C = (1 / (zc0  * v0)) * (%i * 2 * %pi *fr / fr0)^(-2/%pi * theta0);

gam = sqrt ( ((%i * 2 * %pi * fr * L) + R) .* (%i * 2 * %pi * fr  .* C));

H=exp(-len*gam)
endfunction


//Tline characteristic impedance
//Input:
//				Rdc: DC resistance of conductor				
//       R0: real part of AC resistance at fr0
//				theta0: angle formed by real and imaginary parts of complex permittivity at fr0
//				zc0: characteristic impedance at fr0
//				v0: velocity at fr0 (m/s)
//				len; length of tline (m)
//			  fr0: frequency at which parameters are specified
//				fr: evaluated at frequency(hz)
function [Z]=ZC(Rdc, R0, theta0, zc0, v0, len, fr0, fr)
Rac = R0 * (1 + %i)*sqrt(2*%pi*fr / fr0);

R = sqrt(Rdc^2 + Rac^2);

L = zc0 / v0;

C = (1 / (zc0  * v0)) * (%i * 2 * %pi *fr / fr0)^(-2/%pi * theta0);

Z = sqrt (((%i * 2 * %pi * fr * L) + R) .* (%i * 2 * %pi * fr  .* C)^(-1));

endfunction

//Load impedance
//Input:
//				res: shunt resistance
//				cap: shunt capacitance
//				fr: evaluated at frequency(hz)
function [Z]=ZL(res, cap, fr)
Z=res * (1 + %i*2*%pi*fr*cap*res)^(-1)
endfunction


//***********************************************************//

//*******************2-tap De-emphasis FIR*******************//
//2-tap De-emphasis FIR circuit
//Input:
//				deemph: de-emphasis level (dB)
//             tbit: Unit interval of FIR
//				fr: evaluated at frequency(hz)
//
// Coefficients are to be calculated according to:
// a1 = (1 + 10^(-de-emph/20))/2         Main cursor
// a2 = (1 - 10^(-de-emph/20))/2          Post cursor
// 
//
function [P]=FIR2tap(deemph, tbit, fr)
a1 = (1 + 10^(-deemph/20))/2;
a2 = (1 - 10^(-deemph/20))/2;

P=a1-a2*exp(-%i*2*%pi*fr*tbit);
  
endfunction
//***********************************************************//


//**************System transfer function***************//
T = HT(TRdc, TR0, Ttheta0, TZ0, Tv0, TL,  Tf0, f);    // Transmission Line H(s)
  
zc= ZC(TRdc, TR0, Ttheta0, TZ0, Tv0, TL, Tf0, f);     // Transmission Line characteristic impedance

zs = ZS(Rs, Ls, f);                                   // Source impedance

zl = ZL(Rl, Cl, f);                                    // Load impedance


G= 2*(((T^(-1) + T) / 2)  .* (1 + zs .* zl^(-1)) + ((T^(-1) - T) / 2)  .* (zs .* zc^(-1) + zc .* zl^(-1)))^(-1);    //Transmission Line transfer function


//***********************************************************//




//**********************Find maximum phase flatness *******************//

gderr=[];
deemphgainvect=0:0.01:10;

for i=deemphgainvect,
   P=FIR2tap(i, Tbit, f);       
   H=P.*G;
   gdofohmega=-diff(phasemag(H(1:N/K/2)*%pi/180))*(N*deltaT/(2*%pi));
   gderr=cat(1, gderr, stdev(gdofohmega));
end  

//Plot density error
scf(3);
clf(3);
plot2d(deemphgainvect(vectorfind(gderr, min(gderr), 'r')), gderr(vectorfind(gderr, min(gderr), 'r')), style=[-2 0]);
plot2d(deemphgainvect, gderr);

legend(sprintf("Min group delay error at %0.2f dB", deemphgainvect(vectorfind(gderr, min(gderr), 'r')))); 
xgrid(4);
xtitle("Group Delay error", "De-emph Level (dB)", "Group Delay Error in StdDev");


P=FIR2tap(deemphgainvect(vectorfind(gderr, min(gderr), 'r')), Tbit, f);                     //Compute the transfer function for optimal gain
H=P.*G;


//***********************************************************//

//**********************Plot Group Delay Functions*******************//

//Plot Transmission Line gain
scf(0);
clf(0);
plot2d(f(1:$-1)/1e9, -diff(phasemag(G)*%pi/180)*(N*deltaT/(2*%pi))/1e-9);
xgrid(4);
xtitle("T-Line Group Delay Plot", "Freq(GHz)", "Group Delay(nS)");

//Plot De-emph circuit gain
scf(1);
clf(1);
plot2d(f(1:$-1)/1e9, -diff(phasemag(P)*%pi/180)*(N*deltaT/(2*%pi))/1e-9);
xgrid(4);
xtitle("De-emphasis Group Delay Plot", "Freq(GHz)", "Group Delay(nS)");


//Plot End-to-End gain
scf(2);
clf(2);
plot2d(f(1:$-1)/1e9, -diff(phasemag(H)*%pi/180)*(N*deltaT/(2*%pi))/1e-9);
xgrid(4);
xtitle("Overall Group Delay Plot", "Freq(GHz)", "Group Delay(nS)");






























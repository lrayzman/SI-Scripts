//Simulation of Lossy transmission line based on algorithms outlined in 
// Dr. H. Johnson's High Speed Signal Propagation , Ch 4.

stacksize(16*1024*1024);

clear;																													//Clear all user created variables
getf("HSPiceUtilities.sci");                                                                                    // Include extraction function


//Data Sequences Constants

K=8;																													//Oversampling ratio

Tbit=125*10^(-12);																													// Bit interval

Nbit = 1024;																													// Number of bits in sequence


//Constants

deltaT =  Tbit / K;																													//Sampling resolution

N=round(2^(ceil(log(Nbit*K)/log(2))));																								                    //Length of sample vector

n=[0:1:N-1];																													//Index of time points

tofn=n*deltaT;																													//Vector of time points

k=[0:1:N-1];  																													//Index of frequency points

f=k/(N*deltaT);																													//Vector of frequency points (Hz)

f(1)=f(2)/10^9;

//ohmega=2*%pi*f;																													//Vector of frequency points (rad)


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

EqGainStep=0.05;                                                                                                //De-emphasis circuit gain step(dB)



//******************* Gaussian LPF ************************//

function [x] = Gausk(r, deltaT, N, k)
qgaussian =0.275 * r;
x=zeros(n);
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

//*******************Generate Data Sequences****************//

u=[0:1:Nbit-1];																								//Bits vector
v=[0:1:K-1];						 																		//Samples per bit vector

usize=size(u,2);
vsize=size(v,2);

xofu=zeros(u);

for m=1:usize;
	rand('uniform'); 																							//Uniform distribution in range [0:1]
	r=rand();
	if r > 0.5 then
		xofu(m) = 1;
	else
		xofu(m) = -1;
	end;
end;

xprimeofu = zeros(1, usize * vsize);

for m=0:(usize-1)																								//Fill in samples vector
	for n=1:vsize
	xprimeofu(vsize*m+n) = xofu(m+1);
	end;
end;


Xkofu = deltaT * fft(xprimeofu, -1);

//***********************************************************//






//**************System transfer function***************//
T = HT(TRdc, TR0, Ttheta0, TZ0, Tv0, TL,  Tf0, f);    // Transmission Line H(s)
  
zc= ZC(TRdc, TR0, Ttheta0, TZ0, Tv0, TL, Tf0, f);     // Transmission Line characteristic impedance

zs = ZS(Rs, Ls, f);                                   // Source impedance

zl = ZL(Rl, Cl, f);                                    // Load impedance



G= 2*(((T^(-1) + T) / 2)  .* (1 + zs .* zl^(-1)) + ((T^(-1) - T) / 2)  .* (zs .* zc^(-1) + zc .* zl^(-1)))^(-1);    //Transmission Line transfer function
//***********************************************************//


//*********Sweep through all De-emphasis settings*************//

deemphgainvect=0:EqGainStep:5;
results=[];
for i=deemphgainvect,
  
    P=FIR2tap(i, Tbit, f);                                            //Compute the equalizer transfer function

//    Xk = Xkofu .* Gausk(LPF, deltaT, N, k)' .* P .*  G ;
    Xk = Xkofu .* P .*  G ;
    xn = 1/ deltaT * fft(Xk, 1);


    //Measure eye 
    [tUI, eh, ew] = eye_measure(tofn, real(xn), 0.01, 0, Tbit);


      // Log eye parameters
      results=cat(2, results, [i; tUI ; eh ; ew]);
        
      //Post results for simulation
      printf("\n*Measurements for %0.2fdB:", i);
      printf("\n*Measured bit-period: %0.2fps", tUI*1e12);
      printf("\n*Measured Eye Height: %0.3fV", eh);
      printf("\n*Measured Eye Width: %0.2fps\n", ew*1e12 );

end

//***********************************************************//

//*******************Post Results****************//


    printf("|-----");
    printf("|------------------------------|\n| dB ");
    printf("|   tUI    |   EH   |    EW    |\n|-----");
    printf("|------------------------------|\n");


    //Print Body
    for a=1:length(,
        printf("|%.2f", deemphgainvect);
        printf(" %.2fps | %0.3fV | %6.2fps |\n", results(2,a)*1e12, results(3,a), results(4,a)*1e12);
    end

    printf("|-----");
    printf("|------------------------------|\n");






        //Plot Eye Height and Eye Width Results
    drawlater;
    clf();
    subplot(2,1,1);
    plot2d3(results(1,:),results(4,:)*1e12, style=2);
    xtitle("Eye Width","Sim #", "Eye opening (ps)");
    //a=get("current_axes");
    //a.x_ticks.locations = linspace(1,numofsweeps,numofsweeps)';
    xgrid(4);
    subplot(2,1,2);
    plot2d3(results(1,:),results(3,:), style=2);
    //a=get("current_axes");
    //a.x_ticks.locations = linspace(1,numofsweeps,numofsweeps)';
    xtitle("Eye Height","Sim #", "Eye opening (V)");
    xgrid(4);
    drawnow; 

    

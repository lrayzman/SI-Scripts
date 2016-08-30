// Frequency Table application to Pulse Responses
//
// (c)2009  L. Rayzman
// Created :      08/15/2008
// Last Modified: 08/15/2008 - Initial


//////////////////////////////////////Linear Filter Convolution////////////////////////////////////
function [t, D] = FT_pr(tpulse, Dpulse,  tUI, f_FT, H_FT)

//  Applies Linear Filter from frequency table to pulse response in time-domain 
//
// Inputs:
//        tpulse     - time points of input pulse response
//        Dpulse     - Waveform data vector of input pulse response
//          tUI      - Unit interval
//        f_FT       - frequency vector 
//        H_FT       - Complex valued frequency table vector. Must be same length
//                     as frequency vector
//
//  Outputs:
//        t     - time points of processed waveform
//        D     - Waveform data vector of processed waveform
//          
//
//   Important notes: 
//  
//
//   TODO: 
//
//////////////////////////////////////SPECIFY//////////////////////////////////////
M=ceil(tUI/2e-12);                              // Number of samples per UI 
///////////////////////////////////////////////////////////////////////////////////


///////////////////
// Error checking
///////////////////

// Let's do some error checking on inputs before we go on
if length(tpulse) ~= length(Dpulse) then
  error("FTpr: Number of samples in time vector does not equal to number of samples of data");
end

if length(H_FT) ~= length(f_FT) then                                 
  error("FTpr: Number of points in frequency table does not match frequency vector");
end

///////////////////
// Initiaization
// stuff
///////////////////

// Variables
H_DCG=0;                            // DC Gain of frequency response



//Restart at t=0
tpulse=tpulse-tpulse(1);

//Remove DC offset
Dpulse=Dpulse-Dpulse(1);


//Remove duplicate initial entry
if(tpulse(1)==tpulse(2)) then
  tpulse=tpulse(2:$);
  Dpulse=Dpulse(2:$);
end

// Force frequency points to be real
f_FT=real(f_FT);

//DBG
//xinit();
//plot2d(tpulse, Dpulse, style=2);
//xtitle("Pulse Response", "Time", "Voltage");

///////////////////
// Sampling Rate Stuff
///////////////////

Nbit = ceil(max(tpulse)/tUI);  												  // Number of bits in pulse response
deltaT =  tUI / M;												  //Sampling resolution (in seconds)
N=round(2^(ceil(log(Nbit*M)/log(2))));										//Length of sample vector (power of two for efficient FFT)
t=([0:1:N-1])*deltaT;												  //Vector of time points
f=(1/deltaT)/2*linspace(0,1,N);                // Vector of frequency points
hofn=[];                                      // intermediate frequency matrix

clear Nbit;
clear M;
clear N;


// Interpolate pulse response
// compute time vector interpolated to resolution of M points per UI
Dpulse=interp1(tpulse, Dpulse, t, 'spline', 0);

//DBG
xinit();
subplot(2,1,1);
plot2d(f_FT, real(H_FT), style=2);
subplot(2,1,2);
plot2d(f_FT, imag(H_FT), style=2);

pause;

// Interpolate FT real, imag separately
H_FT=interp(f,f_FT, real(H_FT), splin(f_FT,real(H_FT),"not_a_knot"))+%i*interp(f, f_FT, imag(H_FT), splin(f_FT,imag(H_FT),"not_a_knot"), "linear");
H_FT(1)=abs(H_FT(1));

// Normalize the response to unity gain at peak point
H_DCG=max(abs(H_FT));
H_FT=H_FT/H_DCG;

//DBG
subplot(2,1,1);
plot2d(f, real(H_FT), style=3);
subplot(2,1,2);
plot2d(f, imag(H_FT), style=3);

// take FFT of interpolated pulse response, convolve with filter
hofn=deltaT*fft(Dpulse,-1).*H_FT;

// Take iFFT of overall pulse-response
D=1/deltaT*real(fft(hofn, 1));
D=D*H_DCG;

// truncate output to original time 
D=D(find(t<=tpulse($)));
t=t(find(t<=tpulse($)));

//DBG
//xinit();
//plot2d(t, D, style=3);


//Clean up
clear Dpulse;
clear hofn;
clear f;

endfunction

//////////////////////////////////////////////////////////////////////////////////////



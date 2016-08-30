// DFE emulation function for application to Pulse Responses
//
// (c)2009  L. Rayzman
// Created :      08/09/2008
// Last Modified: 08/09/2008 - Initial


//////////////////////////////////////DFE emulation////////////////////////////////////
function [t, D, opt_coeff, err] = DFE_pr(tpulse, Dpulse, coeffs, tUI, opt_type)

//  Applies DFE to pulse response in time-domain 
//
// Inputs:
//        tpulse     - time points of input pulse response
//        Dpulse     - Waveform data vector of input pulse response
//        coeffs     - Nx4 matrix specifying range max, min, number of descrete steps, and peak voltage of DFE,
//                     where N is number of post-cursor taps:
//                    | Max cursor 1       Min cursor 1       # of steps for cursor 1  peak voltage |
//                    | Max cursor 2       Min cursor 2       # of steps for cursor 2  peak voltage |
//                    |      .                  .                        .                  .       |
//                    |      .                  .                        .                  .       |
//                    |      .                  .                        .                  .       |
//                    | Max cursor N       Min cursor N       # of steps for cursor N  peak voltage |
//           
//                     Conditions: -1 < Max < 1
//                                 -1 < Min < 1
//                                  Min < Max
//                                  Coefficient for each tap is referenced to it's respective peak voltage
//                                  Peak voltage must be a positive number
//                                  
//          
//            tUI    - Unit interval
//       opt_type    - Cursor optimization algorithm type
//                     1 = Minimal midpoint error
//                     2 = minimal full-UI error

//
//  Outputs:
//        t     - time points of processed waveform
//        D     - Waveform data vector of processed waveform
//opt_coeff     - Optimal coefficients vector
//      err     - pulse response RMS error (weighted by peak value)

//          
//
//   Important notes: 
//              - Only post-cursors are being implemented
//              - Cursor coeffients take on absolute values as a function of peak-voltage specification for each cursor
//              - If multiple peak points of same level occur, only the last one is considered the peak
//  
//
//   TODO: 
//          CHECK FOR CORNER CONDITION WHEN LAST UI IS INCOMPLETE
//

//////////////////////////////////////SPECIFY//////////////////////////////////////

// Peak-find algorithm parameters
npeakwind=5;                                    // Number of samples (+/- around peak point) for peak-find algorithm
tpeakminres=10;                                 // Minimum time spacing resolution factor

// DFE window paramters
trfwin=20e-12;                                  // Edge rate of DFE window (Note: rise/fall edge must be less than 50% of tUI)
M=ceil(tUI/2e-12);                              // Number of samples per UI (Gaussian LPF for DFE window);
///////////////////////////////////////////////////////////////////////////////////


///////////////////
// Error checking
///////////////////

// Let's do some error checking on inputs before we go on
if size(coeffs,1) < 1 then                                  // Check that size of number of taps is at least one
  error("DFE: Invalid format of coefficients");
end

if size(coeffs,2) ~= 4 then                                 // Check that size of specification matrix is correct
  error("DFE: Invalid format of coefficients");
end

for i=1:size(coeffs,1),                                     
   if coeffs(i, 4) <= 0 then                                                //Check that coefficients peak voltage is given as a positive number
    error("DFE: Invalid peak voltage definition for coefficient %d", i);
   end 
  
   if (coeffs(i,1) < -1) | (coeffs(i,1) > 1) then
     error("DFE: Invalid value definition for max cursor for coefficient %d", i);
    end 
 
    if (coeffs(i,2) < -1) | (coeffs(i,2) > 1) then
     error("DFE: Invalid value definition for min cursor for coefficient %d", i);
    end 
 
    if coeffs(i,1) <= coeffs(i,2) then
     error("DFE: Max cursor value is smaller than min cursor value for coefficient %d", i);
   end 
end



if length(tpulse) ~= length(Dpulse) then
  error("DFE: Number of samples in time vector does not equal to number of samples of data");
end

if (opt_type < 1) | (opt_type > 2) then
  error("DFE: Invalid optimization algorithm type");
end

///////////////////
// Initiaization
// stuff
///////////////////

//Restart at t=0
tpulse=tpulse-tpulse(1);

//Remove DC offset
Dpulse=Dpulse-Dpulse(1);


//Remove duplicate initial entry
if(tpulse(1)==tpulse(2)) then
  tpulse=tpulse(2:$);
  Dpulse=Dpulse(2:$);
end

///////////////////
// Function variables
///////////////////

//Function variables
numoftaps=size(coeffs,1);                       // Number of taps
opt_coeff=zeros(size(coeffs,1));                // Optimal coefficients

prtpeakidx=[0 0];                               // Time index of waveform peak
prtpeak=0;                                      // Time of waveform peak
prmaxval=0;                                     // Peak value of waveform (negative for negative-going waveform)
tpeakwin=[];                                    // Time vector for peak-find altorithm
Dpeakwin=[];                                    // peak-find algorithm window waveform
tpeakmin=0;                                     // Minimum time spacing around peak point in data

Ddfewin=[];                                     // DFE window time-domain waveform
hofDdfe=[];                                     // DFE windows frequency-domain data



Nbit = ceil(max(tpulse)/tUI);  												  // Number of bits in pulse response
deltaT =  tUI / M;												  //Sampling resolution (in seconds)
N=round(2^(ceil(log(Nbit*M)/log(2))));										//Length of sample vector (power of two for efficient FFT)
tofn=([0:1:N-1])*deltaT;												  //Vector of time points
//f=(1/deltaT)/2*linspace(0,1,N/2+1);             // Vector of frequency points

clear Nbit;
clear M;


///////////////////
// Peak-finding
// algorithm
///////////////////
// Find time and amplitude of the peak based on data
prtpeakidx(1)=max(find(Dpulse==max(abs(Dpulse))));    


//find minimum voltage at +/-npeakwind points out
vpeakmin=min([Dpulse(prtpeakidx(1)+npeakwind)  Dpulse(prtpeakidx(1)-npeakwind)]);

//find min time between any two adjacent time points in the waveform
tpeakmin=min(diff(tpulse(find(Dpulse >= vpeakmin))))/tpeakminres;

prtpeakidx(1)=min(find(Dpulse >= vpeakmin));
prtpeakidx(2)=max(find(Dpulse >= vpeakmin))

// Compute time vector between +/-5 sample window around peak point at tpeakmin resolution
tpeakwin=linspace(tpulse(prtpeakidx(1)), tpulse(prtpeakidx(2)),  (tpulse(prtpeakidx(2))-tpulse(prtpeakidx(1)))/tpeakmin+1);

// Spline interpolation waveform points at high resolution
Dpeakwin=interp1(tpulse(prtpeakidx(1):prtpeakidx(2)), Dpulse(prtpeakidx(1):prtpeakidx(2)), tpeakwin, 'spline');

                                                                   
prtpeak=tpeakwin(find(Dpeakwin==max(abs(Dpeakwin))));                        
prmaxval=Dpeakwin(find(Dpeakwin==max(abs(Dpeakwin))));  

//DBG
//xinit();
//plot2d(tpulse(prtpeakidx(1):prtpeakidx(2)), Dpulse(prtpeakidx(1):prtpeakidx(2)));
//plot2d(tpeakwin, Dpeakwin);

clear tpeakmin;
clear npeakwind;
clear tpeakwin;
clear tpeakminres;
clear Dpeakwin;
clear prtpeakidx;

///////////////////
// DFE coefficients 
///////////////////

// Minimal midpoint error algorithm
if opt_type == 1 then 
  for i=1:numoftaps,
    pridxtemp=max(find(tpulse <= prtpeak + i*tUI));                                                                               // Find time index of center of UI
    if pridxtemp == [] then
        error("DFE: Minimal midpoint error algorithm unable to find center of UI");
    end
    opt_coeff(i)=(-1)*interpln([tpulse(pridxtemp) tpulse(pridxtemp+1); Dpulse(pridxtemp) Dpulse(pridxtemp+1)], prtpeak + i*tUI);   // Linearly interpolate to obtain offset
  end      
  
  opt_coeff(i)=quantizerNbit(opt_coeff(i), coeffs(i,1)*coeffs(i,4), coeffs(i,2)*coeffs(i,4), coeffs(i,3));                       // quantize
  clear pridxtemp;
end


// Minimal full-UI error algorithm
if opt_type == 2 then 
 for i=1:numoftaps,
 
    pridxtemp=intersect(find(tpulse >= (prtpeak + tUI*(i-0.5))), find(tpulse < (prtpeak + tUI*(i+0.5))));                       //Find window of the uI
    Dpos=(Dpulse(pridxtemp).*(Dpulse(pridxtemp)>0));                                                                            // compute rms error positive values
    Drmspos=sqrt(1/length(pridxtemp)*sum(Dpos^2));
    
    Dneg=(Dpulse(pridxtemp).*(Dpulse(pridxtemp)<0));                                                                            // compute rms error for negative values
    Drmsneg=sqrt(1/length(pridxtemp)*sum(Dneg^2));

    opt_coeff(i)=(-1)*(Drmspos-Drmsneg)/2;                                                                                        // Obtain error offset
  end  
  
  
  opt_coeff(i)=quantizerNbit(opt_coeff(i), coeffs(i,1)*coeffs(i,4), coeffs(i,2)*coeffs(i,4), coeffs(i,3));                       // quantize
  clear pridxtemp;
  clear Dpos;
  clear Dneg;
  clear Drmspos;
  clear Drmsneg;
end


///////////////////
//  DFE window
//
///////////////////
Ddfewin=zeros(D);

for i=1:numoftaps,
     Ddfewin(intersect(find(tpulse >= (prtpeak + tUI*(i-0.5))), find(tpulse < (prtpeak + tUI*(i+0.5)))))=opt_coeff(i);
end

//DBG
//xinit();
//plot2d(tpulse, Ddfewin, style=2);
//xtitle("DFE window", "Time", "Voltage");

// compute time vector interpolated to resolution of M points per UI
Ddfewin=interp1(tpulse, Ddfewin, tofn, 'linear', Ddfewin($));

// Apply filter to DFE window
hofDdfe=deltaT*fft(Ddfewin,-1).*Gausk(trfwin, deltaT, N)';

// Take iFFT of DFE window
Ddfewin=1/ deltaT*real(fft(hofDdfe,1));

// Interpolate back and truncate to original time points 
Ddfewin=interp1(tofn, Ddfewin, tpulse, 'linear', Ddfewin($));


//DBG
//plot2d(tpulse, Ddfewin, style=3);
//xtitle("Filtered DFE window", "Time", "Voltage");


//clean up
clear hofDdfe;
clear tofn;

///////////////////
// Compute pulse
// response
///////////////////
D=Dpulse+Ddfewin;
t=tpulse;

///////////////////
// Compute pulse 
// response residual
// error
///////////////////
Dpulse=D(find(tpulse > (prtpeak + tUI*0.5)));
err=(sqrt(1/length(Dpulse)*sum(((Dpulse.*(Dpulse>0)))^2))+sqrt(1/length(Dpulse)*sum(((Dpulse.*(Dpulse>0)))^2)))/prmaxval;

//Clean up
clear Ddfewin;
clear numoftaps;
clear trfwin;
clear prmaxval;
clear prtpeak;
clear hofDdfe;
clear Dpulse;
clear tpulse;

endfunction

//////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////Quantizer Function////////////////////////////////////
function y = quantizerNbit(x, ymax, ymin, N)
// N-step quantizer that converts continous amplitude
//   sequence x into quantized amplitude sequence y
   
//
// Inputs:
//        x     - input point(s)
//      ymax    - Maximum permitted value
//      ymin    - Minimum permitted value
//        N     - Number of steps
//


if modulo(N,2)==0 then             // N is even

  x=x-ymin;                        // transform to normalized value
  x=x*((N-1)/(ymax-ymin));
  y=round(x);                      // quantize
  y=y/((N-1)/(ymax-ymin));         // transform back to original scale
  y=y+ymin; 
  
end

if modulo(N,2)==1 then             // N is odd

  x=x-(ymax+ymin)/2;               // transform to normalized value
  x=x*((N-1)/(ymax-ymin));
  y=round(x);                      // quantize
  y=y/((N-1)/(ymax-ymin));         // transform back to original scale
  y=y+(ymax+ymin)/2; 
  
end


y(y>(ymax))=ymax;                // clip anything above peak
y(y<(-ymax))=ymin;

endfunction
////////////////////////////////Gaussian LFP Function////////////////////////
function [x] = Gausk(r, deltaT, N)
// Ideal gaussian edge low-pass filter function
//
//
// Inputs:
//        r      - edge rise/fall-time 
//        deltaT - sampling time-step
//        N      - number of points in FFT
//
// Outputs:
//       x      - Frequency domain data
//     
  
qgaussian =0.31 * r;
x=zeros(N);
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

//////////////////////////////////////////////////////////////////////////////////////





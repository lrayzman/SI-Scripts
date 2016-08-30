// Convolution of Pulse Response from HSpice *.tr files and 
// random (PRBS) bitstream.
//
// Use for bus simulations from Intel
//
//
// (c)2009  L. Rayzman
// Created :      03/15/2009
// Last Modified: 03/15/2009 - Initial
//
//
// NOTES:
//      - Script assumes length of PRBS sequence is longer than of pulse response. 
//        
//


//stacksize(16*1024*1024);

clear;																													//Clear all user created variables
getf("HSPiceUtilities.sci");                                                                                    // Include CSDF extraction function

//////////////////////////////////////SPECIFY////////////////////////////////////

///// Sampling Rate Specifications /////
k=8;																													//Oversampling ratio (samples per UI)

tUI=125*10^(-12);																													// Bit interval (time)


///// LFSR Specifications /////
//n=23;                                                                                                           //Length of LFSR
n=15;
//c=[23 22 20 16];      //Location of feedback coefficients 
c=[15 14];
                      //Do not include bit zero (always implied)
                      //Ex: X^3+X^2+1 => [3 2]
                      //    Corresponds to 3 bit LFSR with feedback at outputs Q2 and Q1
                      //    
                      //    Corresponds to 3 bit LFSR with feedback at outputs Q2 and Q1
                      //                       /----//
                      //                      /    //---------------------|
                      // |-------------------|     ||                     |
                      // |                    \    \\---|                 |
                      // |                     \----\\  |                 |
                      // |                              |                 |
                      // |                              |                 |
                      // |  |--------|     |---------|  |  |---------|    |
                      // |--| D0  Q0 |-----| D1   Q1 |-----| D2   Q2 |------>  output
                      //    |        |     |         |     |         |
                      //    |        |     |         |     |         |
                      //    |--------|     |---------|     |---------|
                      


/////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////LFSR Sequence Generation////////////////////////////////////
//Seed all LFSR registers to 1s
S=ones(1,n);


//Generation of polynomial coefficients vector
cfs=zeros(1,n);

for i=1:length(c),
  cfs(length(cfs)-c(i)+1)=1;
end



//
//LFSR generator
//
//
//
// This function generates a sequence of n bits produced by the linear feedback
// recurrence relation that is governed by the coefficient vector c.
// The initial values of the bits are given by the vector k
//
//
// Inputs:
//        c   -   coefficients vector
//        k   -   initial register values
//        n   -   Length of LFSR sequence

//
//  Outputs:
//        n  - LFSR bistream
function y = lfsr(c,k,n)

y=zeros(1,n);                                           //Initialize bitstream

kln=length(k);

winId=progressionbar('LFSR calculation progress');     //Create progress bar

progbardiv=int(n/33);
c_prime=c';

for j=1:n,
   if j<=kln then
      y(j)=k(j);
   else
      y(j)=modulo(y(j-kln:j-1)*c_prime,2);   
    end   
    
    if 0==modulo(j, progbardiv) then      //Advance progress bar
      progressionbar(winId);
    end 
end
    winclose(winId);   //Remove progression bar
    
endfunction
/////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////Main Routine////////////////////////////////////

fsource = emptystr();                             // Filename of HSpice source file
fwvfrm = emptystr();                             // Converted waveform filename
fcnvpar = emptystr();                              // Converter instructions file
cmdlinestr=emptystr();                            // HSpice converter command line string.
olddir=emptystr();                                // Original directory path
dialogstr=emptystr();                           // Temporary string for storing dialog information
waveformstr=emptystr();                         // Waveform to be converted

t = [];                                           // Time points vector from CSDF file
Doft = [];                                        // Waveform vector from CSDF file
pofn = [];                                        // Pulse response been interpolated and zero padded to sample rate
lfsrseq=[];                                       // LFSR bitstream
lfsrseqofn=[];                                    // LFSR sequence as a function of t of n
ystartidx=0;                                      // Starting sample of output sequence
yendidx=0;                                        // Last sample of output sequence
hyst=0;                                           // Hysteresis for eye measure
dj=0;                                             // Dj to be convolved with results
DCOffset=0;                                       // DC Offset
MeasUIout=0;                                      // Measured UI period
MeasEH=0;                                         // Measured Eye Height
MeasEW=0;                                         // Measured Eye Width


///////////////////
// Load PWL file
///////////////////
fsource=tk_getfile("*.tr*", Title="Please choose input *.tr* file");                                                // Source file
if fsource==emptystr() then
  buttondialog("Invalid file selection. Script aborted", "Abort");
  abort;
end


//Set new directory name for Hspice conversion
olddir=getcwd();
chdir(fileparts(fsource, "path"));

//Get waveform info
dialogstr=x_mdialog('Enter waveform name:', ' ', 'V(out_p,out_n)');
if length(dialogstr)==0 then
  buttondialog("Invalid parameters selection. Script aborted", "Abort");
  chdir(olddir);
  abort;
end
waveformstr=strcat(tokens(dialogstr(1), " "));         // Strip spaces in the waveform string (workaround Hspice bug)


//Create conversion command line  
cmdlinestr="converter -t PWL -i "  + strcat([fileparts(fsource, "fname"), fileparts(fsource, "extension")]) + " -o " + strcat([fileparts(fsource, "fname"), ".dat"]) + " < cnvparams.txt";

//Create converter input file
fcnvpar=strcat([fileparts(fsource, "path"), "cnvparams.txt"]);                                          // Set instructions file. 


[fhandle,err]=mopen(fcnvpar, "w");  
if err<0 then
   chdir(olddir);
   error("Unable to create conversion instructions file");  
   abort;
end   

mfprintf(fhandle,"1\n%s\n\n%s\n\n\n",waveformstr,waveformstr); 

mclose(fhandle);


//run converter
  if unix(cmdlinestr) ~= 0 then                                          // Run simulation
     buttondialog("Conversion Failed. Script aborted", "Abort");
     chdir(olddir);
     abort;
  end


fwvfrm = strcat([fileparts(fsource, "fname"), ".dat", part(fileparts(fsource, "extension"), [4:length(fileparts(fsource, "extension"))])]);
            

//Extract frequency response from file
[t, Doft]=extract_from_PWL(fwvfrm);


//Revert to original directory
chdir(olddir);


 
//Plot the unmodified data
xinit()
plot2d(t, Doft, style=2);
xtitle("Pulse Response", "Time(s)", waveformstr);

clear fsource;
clear fwvfrm;
clear fcnvpar;
clear dialogstr;
clear waveformstr;
clear mdlinestr;


///////////////////
// Sampling Rate Stuff
///////////////////

lenpr=ceil(max(t)/tUI);                                                                                         //Length of pulse response (in bits)

lenlfsr=2^n-1;                                                                                                  //Length of LFSR sequence (do not modify)  
Nbit = lenlfsr+lenpr;  																												    // Number of bits in sequence

deltaT =  tUI / k;																													//Sampling resolution (in seconds)

N=round(2^(ceil(log(Nbit*k)/log(2))));																								                   //Length of sample vector (power of two for efficient FFT)

tofn=([0:1:N-1])*deltaT;																													//Vector of time points

///////////////////
// Interpolate Waveform
// to constant 
// sampling rate
///////////////////

//Interpolate waveform to sampling points
pofn=interp1(t, Doft, tofn, 'spline', Doft($));
DCOffset=Doft(1);


///////////////////
// Compute
// time boundaries
///////////////////

//Start output at peak of the first UI
ystartidx=vectorfind(pofn, max(pofn),'c');

//End of pulse response in terms of time index tofn
// (end index always greater than or equal to end of 
// pulse response time)
yendidx=max(find(tofn<max(t)))+1;

//Check that length of LFSR does not exceed
//critical length such that time aliasing
//occurs due to convolution

if (N-(lenlfsr+ceil(ystartidx/k))*k-yendidx) < 0 then
   error("Operation aborted. Time aliasing will occur!");  
   abort;
end  

clear t;
clear Doft;
clear wvfrm;
clear Desc;


///////////////////
// Compute LFSR 
// sequence
///////////////////
lfsrseq_short=lfsr(cfs,S,lenlfsr)-0.5;  

//Concatenate LFSR sequence with extension that lasts the length of 
//time from t=0 to first peak
lfsrseq_short=[lfsrseq_short, lfsrseq_short(1:ceil(ystartidx/k))];

//Decimate LFSR sequence into pulses at periods of k
lfsrseqofn=zeros(1, N);
lfsrseqofn([0:length(lfsrseq_short)-1]*k+1)=lfsrseq_short;      


//End output at end of LFSR sequence
yendidx=length(lfsrseq_short)*k+ystartidx;                         
clear lfsrseq_short;

///////////////////
// Compute circular
// convolution via
// FFT
///////////////////

pofohmega=fft(pofn-DCOffset);
clear pofn;
lfsrseqofohmega=fft(lfsrseqofn);
clear lfsrseqofn;

yofohmega=pofohmega.*lfsrseqofohmega;
yofn=real(ifft(yofohmega));
clear pofohmega;
clear lfsrseqofohmega;
clear yofohmega;

///////////////////
// Eye
///////////////////

for i=10:15,
    
    tic();
  // [MeastUI, MeasEH, MeasEW]= eye_measure(tofn(ystartidx:yendidx), yofn(ystartidx:yendidx), hyst, dj, tUI);
   [MeastUI, MeasEH, MeasEW]= eye_measure(tofn(ystartidx:2^i), yofn(ystartidx:2^i), hyst, dj, tUI);
   toc()
   //Post results for simulation
   printf("\n*Measured bit-period: %0.2fps", MeastUI*1e12);
   printf("\n*Measured Eye Height: %0.3fV", MeasEH);
   printf("\n*Measured Eye Width: %0.2fps\n", MeasEW*1e12 );
end   









    

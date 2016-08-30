// Pulse Response to impulse response (Freq Domain) converter.
// Imports pulse response from HSpice *.tr files and 
// computes impulse response in frequency domain file
// 
//
// Use for bus simulations from Intel
//
//
// (c)2009  L. Rayzman
// Created :      03/16/2009
// Last Modified: 03/16/2009 - Initial
//                03/22/2009 - Improvements to de-convolution algorithm
//                03/30/2009 - Correction to converter command line string
//                           - Changed interpolation to use last point of original data 
//                             to extrapolate out in time.
//                03/31/2009 - Reset time vector to t=0
//                             Linearly remove wander
//                            
//
//
// NOTES:
//        
//


//stacksize(16*1024*1024);

clear;																													//Clear all user created variables
getf("HSPiceUtilities.sci");                                                                                    // Include PWL extraction function

//////////////////////////////////////SPECIFY////////////////////////////////////

///// Sampling Rate Specifications /////
M=32;																													//Oversampling ratio (samples per UI)

tUI=125*10^(-12);																													// Bit interval (time)


//////////////////////////////////////Main Routine////////////////////////////////////

fsource = emptystr();                             // Filename of HSpice source file
fwvfrm = emptystr();                             // Converted waveform filename
fcnvpar = emptystr();                              // Converter instructions file
fhspout=emptystr();                                   // S-parameter output
cmdlinestr=emptystr();                            // HSpice converter command line string.
olddir=emptystr();                                // Original directory path
dialogstr=emptystr();                           // Temporary string for storing dialog information
waveformstr=emptystr();                         // Waveform to be converted
Sparam=[];                                      // Empty vector

t = [];                                           // Time points vector from tr* file
Doft = [];                                        // Waveform vector from tr*  file
pofn = [];                                        // Pulse response been interpolated and zero padded to sample rate
hofn=[];                                        // Ideal source pulse


///////////////////
// Load PWL file
///////////////////
version_str=getversion();
version_str=tokens(version_str,'-');
version_str=tokens(version_str(2),'.');
version(1)=msscanf(version_str(1), '%d');
version(2)=msscanf(version_str(2), '%d');
version(3)=msscanf(version_str(3), '%d');

  if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
    fsource=uigetfile("*.tr*", boxTitle="Please choose input *.tr* file");                                                
  else
    fsource=tk_getfile("*.tr*", Title="Please choose input *.tr* file");     
  end


if fsource==emptystr() then
   if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file check
     messagebox("Invalid file selection. Script aborted", "","error","Abort");                                                   
  else
     buttondialog("Invalid file selection. Script aborted", "Abort");    
  end
  abort;
end


fhspout=tk_savefile("*.s2p", strsubst(fileparts(fsource, "path"),"\","/"), Title="Please choose output .s2p file");      // S2P file


if fhspout==emptystr() then
  
  if (version(1)==5) & (version(2) >= 1) then                                                                           // S2P file check
     messagebox("Invalid file selection. Script aborted", "","error","Abort");                                                  
  else
       buttondialog("Invalid file selection. Script aborted", "Abort");
  end
  abort;
end


//Set new directory name for Hspice conversion
olddir=getcwd();
chdir(fileparts(fsource, "path"));

//Get waveform info
dialogstr=x_mdialog('Enter waveform name:', ' ', 'diff_lecroy_lai2');
if length(dialogstr)==0 then
  
  if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
     messagebox("Invalid parameters selection. Script aborted", "","error","Abort");                                                
  else
         buttondialog("Invalid parameters selection. Script aborted", "Abort");
  end

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

disp("***Begin tr* conversion***");

//run converter
  if unix(cmdlinestr) ~= 0 then                                          // Run simulation
    
   if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
     messagebox("Conversion Failed. Script aborted", "","error","Abort");                                                
  else
     buttondialog("Conversion Failed. Script aborted", "Abort");
  end
     chdir(olddir);
     abort;
  end


//fwvfrm = strcat([fileparts(fsource, "fname"), ".dat", part(fileparts(fsource, "extension"), [4:length(fileparts(fsource, "extension"))])]);
fwvfrm = strcat([fileparts(fsource, "fname"), ".dat0"]);


        
disp("***Begin data extraction***");
//Extract frequency response from file
[t, Doft]=extract_from_PWL(fwvfrm);


//Revert to original directory
chdir(olddir);


 
//Plot the unmodified data
xinit()
plot2d(t, Doft, style=2);
xtitle("Pulse Response", "Time(s)", waveformstr);

//Remove duplicate initial entry
if(t(1)==t(2)) then
  t=t(2:$);
  Doft=Doft(2:$);
end

//Restart at t=0
t=t-t(1);


//Remove low frequency wander to ensure proper FFT
Doft=Doft-(t/t($))*(Doft($)-Doft(1));

//Remove DC offset
Doft=Doft-Doft(1);

//clear fsource;
clear fwvfrm;
clear fcnvpar;
clear dialogstr;
clear waveformstr;
clear mdlinestr;


///////////////////
// Sampling Rate Stuff
///////////////////

lenpr=ceil(max(t)/tUI);                                                                                         //Length of pulse response (in bits)

Nbit = lenpr;  																												    // Number of bits in sequence

deltaT =  tUI / M;																													//Sampling resolution (in seconds)

N=round(2^(ceil(log(Nbit*M)/log(2))));																								                   //Length of sample vector (power of two for efficient FFT)

tofn=([0:1:N-1])*deltaT;																													//Vector of time points

f=(1/deltaT)/2*linspace(0,1,N/2+1);                                                                             // Vector of frequency points

//f(1)=f(2)/10^9;

///////////////////
// Interpolate Waveform
// to constant 
// sampling rate
///////////////////

disp("***Begin pulse response interpolation***");




//Interpolate waveform to sampling points
pofn=interp1(t, Doft, tofn, 'spline', Doft($));



xinit()
plot2d(tofn, pofn, style=2);
xtitle("Interpolated Pulse Response", "Sample #", "pofn");


///////////////////
// Compute
// time boundaries
///////////////////

//Check that length of pulse response+ideal pulse does not exceed
//critical length such that time aliasing
//occurs due to convolution

//if (N-(lenlfsr+ceil(ystartidx/k))*k-yendidx) < 0 then
//   error("Operation aborted. Time aliasing will occur!");  
//   abort;
//end  

clear t;
clear Doft;
clear wvfrm;
clear Desc;


///////////////////
// Deconvolve to
// find impulse response
// h[n]
///////////////////

// recognizing that
//       ___N-1
//  p[n]=\   h[n-k] 
//       /
//       ----
//       k=0
//
//  since s[n]=1 for 0<= n< N
//
//  and h[n]=0 for n<0
//
//  or p[n]=h[n]+h[n-1]+...h[n-(N-1)]
//
//  thus, 
// 
//  p[0]=h[0]
//  p[1]=h[1]+h[0]
//  p[2]=h[2]+h[1]+h[0]
//  ...

disp("***Begin deconvolution***");

winId=waitbar('Deconvolution calculation progress');     //Create progress bar
progbardiv=int(N/100);

hofn=zeros(1,N);
hofn2=zeros(1,N);

//Algorithm Ver1


//for i=1:N,
//  if i>M then
//    hofn(i)=pofn(i)-sum(hofn((i-M+1):i));
//  else
//    hofn(i)=pofn(i)-sum(hofn(1:i));
//   end
//end  

//hofn($-length(tofn)*0.75:$)=0;

//Algorithm Ver2

termsmscolm=zeros(1,N);
termsmscolm(1:M:$)=1;
termsmscolm(2:M:$)=-1;
termsmscolm=termsmscolm(:,$:-1:1);


for i=1:N,
  hofn(i)=pofn*[termsmscolm($-i+1:$),zeros(1,N-(i))]';
  
  if 0==modulo(i, progbardiv) then      //Advance progress bar
      waitbar(i/N, winId);
  end 
end

winclose(winId);   //Remove progression bar

//Decay the noise (window)
//hofn(0.75*N+1:$)=hofn(0.75*N+1:$).*linspace(1,0,N/4);

hofohmega=fft(hofn,-1);

//Try to clean up the FFT
for i=1:(N/M):N,
  if i>1 then
       hofohmega(i)=(real(hofohmega(i-1))+real(hofohmega(i+1)))/2+%i*(imag(hofohmega(i-1))+imag(hofohmega(i+1)))/2;
  end
end  

hofn2=real(fft(hofohmega,1));

//Combine clean parts
hofn(find(hofn==max(hofn))+1:$)=hofn2(find(hofn==max(hofn))+1:$);


//Shift
//lastidx=0;
//zerosofhofn=find(hofn<0);

//for i=zerosofhofn(2:$),
//   if hofn(i-1)==0 then
//      lastidx=i;  
//   end
//end

//hofn=[hofn(lastidx+1:$), hofn($)*ones(1,lastidx)];

//hofn(1:lastidx)=hofn($);
//hofn(lastidx+1)=(hofn(lastidx)+hofn(lastidx+2))/2;
//hofn=hofn-hofn(1);


hofohmega=fft(hofn,-1);

xinit();
plot2d(tofn, hofn, style=2);
xtitle("Impulse response", "Time(s)", "hofn");

clear hofn;
clear hofn2;
clear termsmscolm;


///////////////////
// Check
///////////////////

disp("***Begin sanity check***");
sofn=[ones(1:M), zeros(1:N-M)];
sofohmega=fft(sofn,-1);

yofohmega=hofohmega.*sofohmega;
yofn=real(ifft(yofohmega));

xinit();
plot2d(tofn, yofn, style=3);
xtitle("Sanity check", "Time(s)", "Reconstructed pofn");


///////////////////
// Create S2P file
///////////////////

hofohmega_short=hofohmega(1:length(f));

Sparam(:,1) = f';                                                                                      //Frequency column
Sparam(:,2) = zeros(f)';                                                                               //S11Mag
Sparam(:,3) = zeros(f)';                                                                               //S11Phase
Sparam(:,4) = real(hofohmega_short)';                                                                  //S12Mag
Sparam(:,5) = imag(hofohmega_short)';                                                                  //S12Phase
Sparam(:,6) = real(hofohmega_short)';																										   //S21 = S12
Sparam(:,7) = imag(hofohmega_short)';
Sparam(:,8) = zeros(f)';																										   //S22 = S11
Sparam(:,9) = zeros(f)';

//Write S2P to file

[Fhandle, err]=mopen(fhspout, 'w');

mfprintf(Fhandle, "# Hz S RI R 50\n");
for  i=1:length(f),
	mfprintf(Fhandle, "%0.2f %0.16e %0.16e %0.16e %0.16e %0.16e %0.16e %0.16e %0.16e\n", Sparam(i,1), Sparam(i,2), Sparam(i,3), Sparam(i,4), Sparam(i,5), Sparam(i,6), Sparam(i,7), Sparam(i,8), Sparam(i,9));
end

mclose(Fhandle);


///////////////////
// Create Freq File
///////////////////

//[Fhandle, err]=mopen(fhspout, 'w');

//mfprintf(Fhandle, "*%s\n", fileparts(fsource, "name"));
//mfprintf(Fhandle, "*	IN OUT GND \n");
//mfprintf(Fhandle, ".SUBCKT impulse 1 2 3\n");
//mfprintf(Fhandle, "EGAUSS 2 3 FREQ 1 3 \n");

//[ph, db]=phasemag(hofohmega, 'c');

//for  i=1:length(f),
//	mfprintf(Fhandle, "+ %0.2f %0.20e %0.16f\n", f(i), db(i), ph(i));
//end

//mfprintf(Fhandle, ".ENDS\n");

//mclose(Fhandle);


disp("***Conversion Complete***");








    

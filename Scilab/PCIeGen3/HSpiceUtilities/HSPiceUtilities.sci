// Common function for HSpice similuations
//
// (c)2008-2010  L. Rayzman
// Created :      10/11/2008
// Last Modified: 10/14/2008 - Added Eye Measurement Tool
//                11/08/2008 - Added DJ convolution to eye measure tool
//                           - Added tUI as input to eye measure tool until that time when bit
//                              rate algorithm is perfected.
//                11/08/2008 - Added DJ convolution to eye measure tool
//		          02/10/2009 - Added Pulse Response Tool
//                03/15/2009 - Added PWL read tool (to be used in conjuction with HSpice converter)
//                03/25/2009 - Added pulse response to frequency file conversion 
//                04/03/2009 - Added pulse response to PWL file conversion for StatEye time-domain 
//                05/18/2009 - Removed DC offset in the 'pulse_convolver_td' file
//                08/11/2009 - Fixed issue with convert_str_to_float no recognizing femtoseconds
//                08/15/2009 - Added DFE emulation functions (DFE_pr, quantizerNbit, Gausk)
//                             Added Linear Filter Convolution from frequency table function
//                             Broke pulse_convolver_td function into read_pwl and write_pwl
//                             functions to allow for Linear Filter and DFE
//                10/25/2009 - Fix in DFE emulation to handle negative pulses
//                             Fixed issue with non-symmetrical max and min range in quantizerNbit 
//                01/05/2010 - Corrected major issue in Linear Filter function: imported transfer 
//                             function needed to mirror "negative" frequencies
//                             Added removal of redundant time entries in 'extract_from_PWL'
//
//
//
// TODO: FIX THE BIT RATE EXTRACTION ALGORITHM IN EYE MEASURE TOOL
// 

//////////////////////////////////////Extraction Function////////////////////////////////////
function [t, D, Desc] = extract_from_CSDF(filename)

//  Extracts waveform data from CSDF ASCII files
//
// Inputs:
//        filename -   Filename of the CSDF file
//
//  Outputs:
//        t     - time points
//        D     - Waveform data matrix
//        Desc  - Title and names of the waveforms (string)


stopflag = %F;                          // Stop loop flag

readline=emptystr();
tempstr=emptystr();                      // Temporary string
ttlstr=emptystr();                       // Title
nodecount=0;                             // Nodecount
idxcnt=1;                                // Timestamp index count;

t=[];                                    // Initialize function output vectors
D=[];



//Open File
[fhandle,err]=mopen(filename, "r");  

if err<0 then
   error("Header Parser: Unable to open data file");  
end   

//
//Parse the header
//
//Find start of header
while stopflag == %F,  
  if meof(fhandle) then                                                //If end of file, stop
    stopflag = %T;
    error("Header Parser: Unable to find start of header in file");        
  else      
    readline=mgetl(fhandle,1) 
      if (convstr(part(readline,[1:2]),"u") == "#H") then                     //If reached start of header
        stopflag = %T;    
      end                                                                                                   
  end
end


stopflag=%F;  // Reset stop flag
//Read in the Title Line
while stopflag == %F,  
  if meof(fhandle) then                                                //If end of file, stop
    stopflag = %T;
    error("Header Parser: Unable to find title line in header");        
  else      
    readline=mgetl(fhandle,1) 
    if (convstr(part(readline,[1:5]),"u") == "TITLE") then                    //If reached nodecount line
        tempstr=tokens(readline, "''");
        ttlstr=tempstr(2);
        stopflag = %T;    
      end                                                                                                   
  end
end

stopflag=%F;  // Reset stop flag
//Read in nodecount
while stopflag == %F,  
  if meof(fhandle) then                                                //If end of file, stop
    stopflag = %T;
    error("Header Parser: Unable to find nodecount line in header");        
  else      
    readline=mgetl(fhandle,1)  
    if (convstr(part(readline,[1:5]),"u") == "NODES") then                     //If reached nodecount
        tempstr=tokens(readline, "''");
        nodecount=sscanf(tempstr(2),"%d");
        stopflag = %T;    
     end                                                                                                   
  end
end

nodenames=emptystr(1, nodecount);                                      // Nodenames

stopflag=%F;  // Reset stop flag
// Look For Node name line
while stopflag == %F,  
  if meof(fhandle) then                                                //If end of file, stop
    stopflag = %T;
    error("Header Parser: Unable to find nodenames line in header");        
  else      
    readline=mgetl(fhandle,1)  
    if (convstr(part(readline,[1:2]),"u") == "#N") then                //If reached nodename line
        tempstr=strsplit(readline,2);                                  //Process first nodename line
        tempstr=tempstr(2);                                           
        readline=mgetl(fhandle,1);                                     //Process subsequent lines until start of data portion
        while (part(readline, 1) ~= "#") & (~meof(fhandle)),
           tempstr = tempstr + readline;
           readline=mgetl(fhandle,1); 
        end
        stopflag = %T;   
        tempstr=strcat(tokens(tempstr));                            // Process all names
        nodenames=tokens(tempstr, "''");
      end                                                                                                   
  end
end

if size(nodenames,1) ~= nodecount then
   error("Header Parser: Node count does not match number of node names");
end 

Desc = [ttlstr,nodenames'];

stopflag=%F;  // Reset stop flag

while stopflag == %F,  
  if meof(fhandle) then                                                //If end of file, stop
    stopflag = %T;
    error("Data Parser: Premature end of file");        
  else      
    if (convstr(part(readline,[1:2]),"u") == "#C") then                //If reached data line for current timestamp
        tempstr=strsplit(readline,2);                                  //Process data linet
        tempstr=tempstr(2);                                           
        readline=mgetl(fhandle,1);                                     //Process subsequent lines until start of next timestep
        while (part(readline, [1:2]) ~= "#C") & (part(readline, [1:2]) ~= "#;") & (~meof(fhandle)) ,
           tempstr = tempstr + readline;
           readline=mgetl(fhandle,1); 
        end
         tempstr=tokens(tempstr);                                     // Process all data entries
         t(idxcnt)=sscanf(tempstr(1), "%f");                               // Get timestamp
         if sscanf(tempstr(2), "%d") ~= nodecount then
              error("Data Parser: Reported node count does not match the count in data");
         end
         for k=1:(size(tempstr,1)-2),
            D(idxcnt,k)=sscanf(tempstr(k+2), "%f");
        end
       idxcnt = idxcnt + 1;
    end
    if (convstr(part(readline,[1:2]),"u") == "#;") then               // End of file
      stopflag = %T; 
    end      
  end
end
     
mclose(fhandle);

// Cleanup variables
clear stopflag;                          
clear readline;
clear tempstr;
clear ttlstr;
clear nodecount;
clear idxcnt;   

endfunction



//////////////////////////////////String to Floating Point conversion//////////////////////////////////


function y = convert_str_to_float(str)
  
//  Conversion function to take in 
//  a string in format:
//
//  xx.xxxxz  
//    where xx is numbers
//          z is multiplier (one of "p", "n", or "m")
//  
//   Sscanf could do this but SCILAB is Piece of Shit,
//   so I have to dupe it
// Inputs:
//        str -   Input string
//
//  Outputs:
//        y     - floating point number

mult=1;
y=0;

//Find multiplier
c=part(str, length(str));
select c,
          case 'f' then mult=1e-15;
          case 'p' then mult=1e-12;
          case 'n' then mult=1e-9;
          case 'u' then mult=1e-6;
          case 'm' then mult=1e-3;
end  

//find location of decimal point
decidx=strindex(str, '.');

//get raw string
if mult <> 1 then
  rawstring=strcat(tokens(part(str, (1:length(str)-1)), '.'));
else
  rawstring=strcat(tokens(str, '.'));
end

//Compute y
pwr=10^(decidx-[1:length(rawstring)]-1);
y=sum(pwr.*str2code(rawstring)')*mult;

endfunction


//////////////////////////////////////PWL File Extraction Function////////////////////////////////////
function [t, D] = extract_from_PWL(filename)

//  Extracts waveform data from PWL ASCII files
//  This file is to be generated from *.tr? files 
//  using HSpice converter utility
// 
//  Only a single node is supported in this version
//
// 
//
// Inputs:
//        filename -   Filename of the PWL file
//
//  Outputs:
//        t     - time points
//        D     - Waveform data matrix

stopflag = %F;                          // Stop loop flag
dupentrytrue= %F;                       // Found identical time entries

readline=emptystr();
tempstr=emptystr();                      // Temporary string
tempt=0;                                 // Temporary time
idxcnt=0;                                // Data line index count;


t=[];                                    // Initialize function output vectors
D=[];



//Open File
[fhandle,err]=mopen(filename, "r");  

if err<0 then

   error("PWL Parser: Unable to open data file");  
end   

//
//Parse the header
//
//Find start of header
while stopflag == %F,  
  readline=mgetl(fhandle,1) 
  if meof(fhandle) then                                                //If end of file, stop
    stopflag = %T;
    if  (idxcnt == 0) then
      error("PWL Parser: Unable to find data in file"); 
    end  
  else      
      if (part(readline,[1:2]) == " +") then                                     //If reached data line
         tempstr=tokens(readline); 
         tempt=convert_str_to_float(tempstr(2));    
         if t(idxcnt)<> tempt then                                  // Remove reduntant time
            idxcnt = idxcnt + 1;
         else
            dupentrytrue=%T;
         end
         
         t(idxcnt)= tempt
         D(idxcnt)=sscanf(tempstr(3), "%f");
       end
    end                                                                                                   
end


mclose(fhandle);

// Report if found duplicate time entries
if dupentrytrue==%T then
  warning("PWL Parser: Found and removed identical time entries in file"); 
end

// Cleanup variables
clear stopflag;                          
clear readline;
clear tempstr;
clear idxcnt;   

endfunction



//////////////////////////////////////Eye Measure////////////////////////////////////
function [tUIm, eh, ew] = eye_measure(t, D, hyst, dj, tUI)

//  Extracts eye information from waveform data 
//
// Inputs:
//        t     - time points from waveform (output from  function "extract_from_CSDF")
//        D     - Waveform data vector (output from  function "extract_from_CSDF")
//        hyst  - Hysteresis voltage (reject noise/ripples below this level as false transitions)
//        dj    - Dj to convolve with computed waveform. 
//        tUI   - Nominal Unit Interval (seconds). 
//                NOTE: variable is planned to be obsoleted once accurate bit rate extraction algorithm is perfected
//
//  Outputs:
//        tUIm  - Measured Unit Interval (seconds)
//                NOTE: currently this return value is identical to the tUI input parameter, until such time
//                as bit rate extraction algorithm is perfected
//        eh    - Measured eye height (volts)
//        ew    - Measured eye width.         
//
//   Important notes: 
//              - Edges must be monotonic
//              - This tool operates only on zero-volt balanced waveforms
//
//   TODO: 
//        FIX BIT RATE extraction algorithm
//


// Let's do some error checking on inputs before we go on
if length(t) ~= length(D) then
  error("EM: Number of samples in time vector does not equal to number of samples of data");
end

if dj < 0 then
    error("EM:  Dj parameter cannot be negative value");
end

if tUI <= 0 then
    error("EM: tUI must be greater than 0 seconds");
end

//Function variables
startidx=0;         // Start marker of transition region to be interpolated
endidx=0;           // End marker of transition regition to be interpolated
numsample=0;        // Size of waveform vector(# of samples)
numUI=0;            // Number of UIs
posedgebin=[];     // Time points of positive edges
negedgebin=[];     // Time points of negative edges
posleadedge=%F;    // Leading edge is positive
eyetimes=[];       // Eye widths of all eye times 
lte=%F;            // Unit interval error level flag
eyevolt=0;         // Voltage level used for eye height measurements


numsample=length(t);


//Rectify positive and negative hemisphere around hysteresis

Drect = (D.*(D>hyst))+ (D.*(D<-hyst));

for n=2:numsample,                                        //For each sample in a collapsed waveform
    if (Drect(n-1) > 0) & (Drect(n) <= 0) then                   //  if previous to current = falling & current is zero
        startidx=n-1;
        
    end
    if (Drect(n-1) >=0) & (Drect(n) < 0) then                   // if previous is zero & previous to current = falling
        endidx=n;
        if (startidx ~= 0) & (endidx ~= 0) then           //    if detected negative zero xing
        for k=startidx:endidx,                            // interpolate zero xing and put into negative edge bin
          if (D(k-1) > 0) & (D(k) < 0) then
            negedgebin=cat(2, negedgebin, [interpln([D(k-1) D(k);t(k-1) t(k)],0); (k-1); k] );
          end
        end
        startidx=0;                                                                       // Ready markers for next transition
        endidx=0;
        end
    end

    if (Drect(n-1) < 0) & (Drect(n) >= 0) then                                                      //  if previous to current = rising & current = zero
        startidx=n-1;
    end
    if (Drect(n-1) <=0) & (Drect(n) > 0) then                //  if previous is zero and previous to current = rising
        endidx=n;
        if (startidx ~= 0) & (endidx ~= 0) then           //    if detected negative zero xing
          for k=startidx:endidx,                          // interpolate zero xing and put into positive edge bin
            if (D(k-1) < 0) & (D(k) > 0) then
              posedgebin=cat(2, posedgebin, [interpln([D(k-1) D(k);t(k-1) t(k)], 0); (k-1); k]);
            end
          end
        startidx=0;                                                                        // Ready markers for next transition
        endidx=0;
        end
    end

end

clear Drect;

//Check that number of positive and negative edges is within 1
if abs(size(negedgebin,1) - size(posedgebin,1)) > 1 then
  error("EM: Large disparity in number of positive versuse negative transitions");
end

//Figure out which transition occurs first
if negedgebin(1,1) > posedgebin(1,1) then
  posleadedge=%T;
end


//Obtain the eye times
for m=1:min(size(negedgebin,2),size(posedgebin,2))-1,
    for l=1:2,
        if posleadedge==%T then                                                         // If positive edge leads
          if l==1 then
            eyetimes=cat(2, eyetimes, [(negedgebin(1, m)-posedgebin(1, m)); 0]);
          else
            eyetimes=cat(2, eyetimes, [(posedgebin(1,m+1)-negedgebin(1, m)); 0]);            
          end                                                                           // If negative edge leads
        else 
           if l==1 then
            eyetimes=cat(2, eyetimes, [(posedgebin(1, m)-negedgebin(1, m)); 0]);
          else

            eyetimes=cat(2, eyetimes, [(negedgebin(1, m+1)-posedgebin(1, m)); 0]);            
          end 
        end
    end
end  

//Bit rate extraction: REVIEW AND IMPROVE
maxui=max(eyetimes(1,:));
minui=min(eyetimes(1,:));
maxinmincnt=round(maxui/minui);
//oldtUI=(minui+(maxui-(maxinmincnt-1)*minui))/2;      // Take average of these to find average over max and min <<===== ALGORITHM DIDN'T WORK
eyetimes(2,:)=round(eyetimes(1,:)/tUI);           // Find number of UI per eyetime <<===== ALGORITHM DIDN'T WORK

// Calculate average UI
numUI=sum(eyetimes(2,:));   
//while  lte==%F,                                    //!!!!! <<===== ALGORITHM DIDN'T WORK
//  oldtUI=tUI;
//  tUIaccum=eyetimes(1,:)-(eyetimes(2,:))*oldtUI;
//  tUIerr=median(tUIaccum);
//tUIerr=(max(tUIaccum)-min(tUIaccum))/2+min(tUIaccum);
//  tUI=tUI+tUIerr;
//  if (abs(tUI-oldtUI)/tUI) < 1e-12 then
//      lte=%T;
//  end
//end  

tUIm=tUI;

//Find the starting offset
if posleadedge==%T then   
  soffset=posedgebin(1, 1);
  offsetaccum=modulo(posedgebin(1,:)-posedgebin(1, 1), tUI);
  for a=1:length(offsetaccum),
    if offsetaccum(a) >= tUI/2 then
      offsetaccum(a) = offsetaccum(a)-tUI;
    end
  end
  soffseterr=(max(offsetaccum)-min(offsetaccum))/2+min(offsetaccum);
  soffset=soffset+soffseterr;
else
  soffset=negedgebin(1, 1);
  offsetaccum=modulo(negedgebin(1,:)-negedgebin(1, 1), tUI);
  for a=1:length(offsetaccum),
    if offsetaccum(a) >= tUI/2 then
      offsetaccum(a) = offsetaccum(a)-tUI;
    end
  end
  soffseterr=(max(offsetaccum)-min(offsetaccum))/2+min(offsetaccum);
  soffset=soffset+soffseterr;
end

//
//Calculate eye width

offsetaccum=cat(2, modulo(posedgebin(1,:)-soffset, tUI), modulo(negedgebin(1,:)-soffset, tUI));      //Find phase between nominal location and all edges
  for a=1:length(offsetaccum),                                                                       // Unwrap for negative phase error
    if offsetaccum(a) >= tUI/2 then
      offsetaccum(a) = offsetaccum(a)-tUI;
    end
end
ew=tUI-abs(max(offsetaccum)-min(offsetaccum))-dj;                                                    // Calculate eye width

//
//Calculate eye height
//
for x=0:(numUI-1),                                                                                  // Measure voltage for all eyes
  eyecenter=soffset+(x+0.5)*tUI;
    for h=2:numsample,      // Search for start point
     if (t(h-1)<= eyecenter) & (t(h)>eyecenter) then
      eyevolt=cat(2, eyevolt, mean([D(h-1) D(h)]));
     end
   end
end    


eyevolt=cat(2, eyevolt.*(eyevolt>=0), eyevolt.*(eyevolt<0));                                        // Find the minimum eye height
eyevolt=unique(eyevolt);
eh=abs(eyevolt(vectorfind(eyevolt, 0, "c")+1)-eyevolt(vectorfind(eyevolt, 0, "c")-1));

startidx=1;
endidx=1;

//xinit();
clf();
drawlater;
//Plot the Eye
                                                                                    //Plot eye twice, first for positive DJ
for j=1:numUI,
  tidealstime=soffset+dj/2+(j-0.5)*tUI;                                                                    
  tidealptime=soffset+dj/2+(j+1+0.5)*tUI;
    for h=2:numsample,      // Search for start point
       if (t(h-1)<= tidealstime) & (t(h)>tidealstime) then
          startidx=h;        
       end
     end
    for h=startidx:numsample,      // Search for end point
      if (t(h-1)< tidealptime) & (t(h)>=tidealptime) then
          endidx=h-1;
       end
    end
    timeaxis=(t(startidx:endidx)-tidealstime - 0.5*tUI)/1e-12 ;
    plot2d(timeaxis, D(startidx:endidx), frameflag=8, style=2);
end  

for j=1:numUI,                                                                    //....second for negative
  tidealstime=soffset-dj/2+(j-0.5)*tUI;                                                                    
  tidealptime=soffset-dj/2+(j+1+0.5)*tUI;
    for h=2:numsample,      // Search for start point
       if (t(h-1)<= tidealstime) & (t(h)>tidealstime) then
          startidx=h;        
       end
     end
    for h=startidx:numsample,      // Search for end point
      if (t(h-1)< tidealptime) & (t(h)>=tidealptime) then
          endidx=h-1;
       end
    end
    timeaxis=(t(startidx:endidx)-tidealstime - 0.5*tUI)/1e-12 ;
    plot2d(timeaxis, D(startidx:endidx), frameflag=8, style=2);
  end  
xgrid(4);
xtitle('','Time (ps)', 'Volts') ;
drawnow;




// Cleanup variables
clear startidx;
clear endidx;
clear numsample;
clear numUI;
clear posedgebin;
clear negedgebin;
clear posleadedge;
clear eyetimes;
clear maxui;
clear minui;
clear maxinmincnt;
clear oldtUI;
clear lte;
clear tUIaccum;
clear tUIerr;
clear soffset;
clear offsetaccum;
clear soffseterr;
clear eyevolt;


endfunction


///////////////////////////////////Pulse Response ////////////////////////////////////
function [PreErr, PostErr] = pulse_response(t, D, tUI )

//  Measures post- & pre-cursor errors 
//
// Inputs:
//        t     - time points from waveform (output from  function "extract_from_CSDF")
//        D     - Waveform data vector (output from  function "extract_from_CSDF")
//        tUI   - Nominal Unit Interval (seconds). 
//
//  Outputs:
//        PreErr    - Integrated voltage error in Pre-cursors
//        PostErr   - Integrated voltage error in Post-cursors
//
//   Important notes: 
//              - This tool operates only on zero-volt referenced waveforms
//
//   TODO: 
//



// Let's do some error checking on inputs before we go on
if length(t) ~= length(D) then
  error("EM: Number of samples in time vector does not equal to number of samples of data");
end

// Function variables
tpeakidx=0;                // Index of the peak location
tnorm=t;                   // Initialize peak-referenced time vector
tUI=t;                     // Initialize the UI time vector
numsample=length(t);       // Number of time samples


// Find location of and set time vector t=0 at that location
tpeakidx=vectorfind(D,max(abs(D)),'c');
tnorm=tnorm-(tnorm(tpeakidx));

// Bin the samples into UI time-slots
tUI=tnorm/tUI;

clear tnorm;
clear tpeakidx;




// Compute the integrated voltage of the main cursors


// Compute the integrated voltage of the other cursors

// Compute relative post- & pre-cursor error


PreErr = 0;
PostErr = 0;

endfunction


//////////////////////////////////////Pulse Response to Frequency File Conversion////////////////////////////////////
function [] = pulse_convolver_sp(FilenameIn, FilenameOut, wavename, M, tUI)

//  Extracts eye information from waveform data 
//
// Inputs:
//        FilenameIn  - Filename of the source *.tr* file
//        FilenameOut - Filename of the output *.s*p file
//        wavename  - Name of the waveform to be converted
//        M        - Oversampling rate (bits per UI)
//        tUI      - Nominal Unit Interval (seconds). 
//
//  Outputs:
//        none
//
//
//   TODO: 
//        Add support for crosstalk (aggressor-victim-aggressor)



fwvfrm = emptystr();                            // Converted waveform filename
fcnvpar = emptystr();                           // Converter instructions file
cmdlinestr=emptystr();                          // HSpice converter command line string.
olddir=emptystr();                              // Original directory path
Sparam=[];                                      // Empty vector

t = [];                                           // Time points vector from tr* file
D = [];                                           // Waveform vector from tr*  file
pofn = [];                                        // Pulse response been interpolated and zero padded to sample rate
hofn=[];                                          // Ideal source pulse


///////////////////
// Load PWL file
///////////////////
version_str=getversion();
version_str=tokens(version_str,'-');
version_str=tokens(version_str(2),'.');
version(1)=msscanf(version_str(1), '%d');
version(2)=msscanf(version_str(2), '%d');


//Set new directory name for Hspice conversion
olddir=getcwd();
chdir(fileparts(FilenameIn, "path"));

//Create conversion command line  
cmdlinestr="converter -t PWL -i "  + strcat([fileparts(FilenameIn, "fname"), fileparts(FilenameIn, "extension")]) + " -o " + strcat([fileparts(FilenameIn, "fname"), ".dat"]) + " < cnvparams.txt";

//Create converter input file
fcnvpar=strcat([fileparts(FilenameIn, "path"), "cnvparams.txt"]);                                          // Set instructions file. 


[fhandle,err]=mopen(fcnvpar, "w");  
if err<0 then
   chdir(olddir);
   error("Pulse Convolver: Unable to create conversion instructions file");  
   abort;
end   

mfprintf(fhandle,"1\n%s\n\n%s\n\n\n",wavename,wavename); 

mclose(fhandle);

//run converter
  if unix(cmdlinestr) ~= 0 then                                          // Run simulation
    
   if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
     messagebox("Pulse Convolver: Conversion Failed. Script aborted", "","error","Abort");                                                
  else
     buttondialog("Pulse Convolver: Conversion Failed. Script aborted", "Abort");
  end
     chdir(olddir);
     abort;
  end


fwvfrm = strcat([fileparts(FilenameIn, "fname"), ".dat0"]);

   
//Extract frequency response from file
[t, D]=extract_from_PWL(fwvfrm);

//Revert to original directory
chdir(olddir);


//Remove DC offset
D=D-D(1);

//Remove duplicate initial entry
if(t(1)==t(2)) then
  t=t(2:$);
  D=D(2:$);
end

//Restart at t=0
t=t-t(1);

//Remove low frequency wander to ensure proper FFT
D=D-(t/t($))*(D($)-D(1));

clear fwvfrm;
clear fcnvpar;
clear olddir;


///////////////////
// Sampling Rate Stuff
///////////////////

lenpr=ceil(max(t)/tUI);                                                                                         //Length of pulse response (in bits)
Nbit = lenpr;  																												    // Number of bits in sequence
deltaT =  tUI / M;																													//Sampling resolution (in seconds)
N=round(2^(ceil(log(Nbit*M)/log(2))));																								                   //Length of sample vector (power of two for efficient FFT)
tofn=([0:1:N-1])*deltaT;																													//Vector of time points
f=(1/deltaT)/2*linspace(0,1,N/2+1);                                                                             // Vector of frequency points

clear lenpr;
clear Nbit;
clear deltaT;

///////////////////
// Interpolate Waveform
// to constant 
// sampling rate
///////////////////

//Interpolate waveform to sampling points
pofn=interp1(t, D, tofn, 'spline', D($));

///DBG
//xinit()
//plot2d(tofn, pofn, style=2);
//xtitle("Interpolated Pulse Response", "Sample #", "pofn");

clear t;
clear D;

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

winId=waitbar('Deconvolution calculation progress');     //Create progress bar
progbardiv=int(N/100);

hofn=zeros(1,N);
hofn2=zeros(1,N);

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

H=fft(hofn,-1);

//Try to clean up the FFT
for i=1:(N/M):N,
  if i>1 then
       H(i)=(real(H(i-1))+real(H(i+1)))/2+%i*(imag(H(i-1))+imag(H(i+1)))/2;
  end
end  


hofn2=real(fft(H,1));

//Combine clean parts
hofn(find(hofn==max(hofn))+1:$)=hofn2(find(hofn==max(hofn))+1:$);


H=fft(hofn,-1);

///DBG
sofn=[ones(1:M), zeros(1:N-M)];
S=fft(sofn,-1);

Y=H.*S;
yofn=real(ifft(Y));
clf();
plot2d(tofn, yofn, style=2);
xtitle("Impulse response", "Time(s)", "hofn");
clear S;
clear sofn;
clear yofn;
clear Y;

H=H(1:length(f));

clear tofn;
clear hofn;
clear hofn2;

///////////////////
// Create S2P file
///////////////////

Sparam(:,1) = f';                                                                                      //Frequency column
Sparam(:,2) = zeros(f)';                                                                               //S11Mag
Sparam(:,3) = zeros(f)';                                                                               //S11Phase
Sparam(:,4) = real(H)';                                                                  //S12Mag
Sparam(:,5) = imag(H)';                                                                  //S12Phase
Sparam(:,6) = real(H)';																										   //S21 = S12
Sparam(:,7) = imag(H)';
Sparam(:,8) = zeros(f)';																										   //S22 = S11
Sparam(:,9) = zeros(f)';

//Write S2P to file

[fhandle, err]=mopen(FilenameOut, 'w');

mfprintf(fhandle, "# Hz S RI R 50\n");
for  i=1:length(f),
	mfprintf(fhandle, "%0.2f %0.16e %0.16e %0.16e %0.16e %0.16e %0.16e %0.16e %0.16e\n", Sparam(i,1), Sparam(i,2), Sparam(i,3), Sparam(i,4), Sparam(i,5), Sparam(i,6), Sparam(i,7), Sparam(i,8), Sparam(i,9));
end

mclose(fhandle);

clear H;
clear fhandle;
clear err;
clear Sparam;

endfunction

//////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////Pulse Response to PWL File Conversion////////////////////////////////////
function [t, D] = read_pwl(FilenameIn, wavename)

//  Extracts eye information from waveform data 
//
// Inputs:
//        FilenameIn  - Filename of the source *.tr* file
//        wavename  - Name of the waveform to be converted
//
//  Outputs:
//        t     - time points of read waveform
//        D     - Waveform data vector of read waveform
//
//
//   TODO: 



fwvfrm = emptystr();                            // Converted waveform filename
fcnvpar = emptystr();                           // Converter instructions file
cmdlinestr=emptystr();                          // HSpice converter command line string.
olddir=emptystr();                              // Original directory path

t = [];                                           // Time points vector from tr* file
D = [];                                           // Waveform vector from tr*  file

///////////////////
// Load PWL file
///////////////////
version_str=getversion();
version_str=tokens(version_str,'-');
version_str=tokens(version_str(2),'.');
version(1)=msscanf(version_str(1), '%d');
version(2)=msscanf(version_str(2), '%d');


//Set new directory name for Hspice conversion
olddir=getcwd();
chdir(fileparts(FilenameIn, "path"));

//Create conversion command line  
cmdlinestr="converter -t PWL -i "  + strcat([fileparts(FilenameIn, "fname"), fileparts(FilenameIn, "extension")]) + " -o " + strcat([fileparts(FilenameIn, "fname"), ".dat"]) + " < cnvparams.txt";

//Create converter input file
fcnvpar=strcat([fileparts(FilenameIn, "path"), "cnvparams.txt"]);                                          // Set instructions file. 


[fhandle,err]=mopen(fcnvpar, "w");  
if err<0 then
   chdir(olddir);
   error("Pulse Convolver: Unable to create conversion instructions file");  
   abort;
end   

mfprintf(fhandle,"1\n%s\n\n%s\n\n\n",wavename,wavename); 

mclose(fhandle);

//run converter
  if unix(cmdlinestr) ~= 0 then                                          // Run simulation
    
   if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
     messagebox("Read_pwl: Conversion Failed. Script aborted", "","error","Abort");                                                
  else
     buttondialog("Read_pwl: Conversion Failed. Script aborted", "Abort");
  end
     chdir(olddir);
     abort;
  end

fwvfrm = strcat([fileparts(FilenameIn, "fname"), ".dat0"]);

   
//Extract frequency response from file
[t, D]=extract_from_PWL(fwvfrm);


//Revert to original directory
chdir(olddir);

clear fwvfrm;
clear fcnvpar;
clear olddir;


endfunction

//////////////////////////////////////////////////////////////////////////////////////

function [] = write_pwl(t, D, FilenameOut)

//  Extracts eye information from waveform data 
//
//  Inputs:
//              t     - time points of waveform to be output
//              D     - Waveform data vector of waveform to be output
//        FilenameOut - Filename of the output *.inc file
//  Outputs:
//        none
//
//
//   TODO: 


///////////////////
// Create PWL source file
///////////////////
[fhandle, err]=mopen(FilenameOut, 'w');

mfprintf(fhandle, ".SUBCKT impulse_src Out Gnd_Src\n");
mfprintf(fhandle, "Vsrc Out Gnd_Src PWL (\n");
for  i=1:length(t),
	mfprintf(fhandle, "+ %0.6e %0.16e\n", t(i),D(i));
end

mfprintf(fhandle, ")\n");
mfprintf(fhandle, ".ENDS\n");

mclose(fhandle);

clear fhandle;
clear err;

endfunction

//////////////////////////////////////////////////////////////////////////////////////

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

negpulse=%f;                                    // Negative pulse detected

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
prtpeakidx(1)=max(find(abs(Dpulse)==max(abs(Dpulse))));    

// Check for negative going pulses and invert as necessary
if Dpulse(prtpeakidx(1)) < 0 then                                 
    Dpulse = -Dpulse;   
    negpulse=%t;
end


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
    opt_coeff(i)=quantizerNbit(opt_coeff(i), coeffs(i,1)*coeffs(i,4), coeffs(i,2)*coeffs(i,4), coeffs(i,3));                       // quantize
  end      
  
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
    opt_coeff(i)=quantizerNbit(opt_coeff(i), coeffs(i,1)*coeffs(i,4), coeffs(i,2)*coeffs(i,4), coeffs(i,3));                       // quantize
  end  
  
  
  
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


// Invert pulse back to original, if necessary
if negpulse==%t then
  D=-D;
end
 

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
y(y<(ymin))=ymin;

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
f=(1/deltaT)/2*linspace(0,1,N/2+1);             // Vector of frequency points
hofn=[];                                        // intermediate frequency matrix

clear Nbit;
clear M;
clear N;

// Interpolate pulse response
// compute time vector interpolated to resolution of M points per UI
Dpulse=interp1(tpulse, Dpulse, t, 'linear', 0);

//DBG
//xinit();
//subplot(2,1,1);
//plot2d(f_FT, real(H_FT), style=2);
//subplot(2,1,2);
//plot2d(f_FT, imag(H_FT), style=2);

// Interpolate FT real, imag separately
H_FT=interp(f,f_FT, real(H_FT), splin(f_FT,real(H_FT),"not_a_knot"))+%i*interp(f, f_FT, imag(H_FT), splin(f_FT,imag(H_FT),"not_a_knot"), "linear");
H_FT(1)=abs(H_FT(1));

//DBG
//subplot(2,1,1);
//plot2d(f, real(H_FT), style=3);
//subplot(2,1,2);
//plot2d(f, imag(H_FT), style=3);

//Unfold/mirror/conjugate the negative frequencies
H_FT=cat(2, conj(H_FT), H_FT($-1:-1:2));

// take FFT of interpolated pulse response, convolve with filter
hofn=fft(Dpulse,-1).*H_FT;      

// Take iFFT of overall pulse-response
D=real(fft(hofn, 1));

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



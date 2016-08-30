// Function to read in CSDF files. For use with HSpice transcient similuations
//
// (c)2008  L. Rayzman
// Created :      10/11/2008
// Last Modified: 10/14/2008 - Added Eye Measurement Tool
//                11/08/2008 - Added DJ convolution to eye measure tool
//                           - Added tUI as input to eye measure tool until that time when bit
//                              rate algorithm is perfected.
//                11/08/2008 - Added DJ convolution to eye measure tool
//		  02/10/2009 - Added Pulse Response Tool
//        03/15/2009 - Added PWL read tool (to be used in conjuction with HSpice converter)
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
//          z is multiplier (one of "p", "n", or "m"
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

readline=emptystr();
tempstr=emptystr();                      // Temporary string
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
        idxcnt = idxcnt + 1;
         tempstr=tokens(readline); 
         t(idxcnt)=convert_str_to_float(tempstr(2));
         D(idxcnt)=sscanf(tempstr(3), "%f");
       end
    end                                                                                                   
end


mclose(fhandle);

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


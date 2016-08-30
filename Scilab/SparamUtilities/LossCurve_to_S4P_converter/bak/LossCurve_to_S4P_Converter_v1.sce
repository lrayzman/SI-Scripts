// ======================   Loss Curve to S-param  ====================
// 
// Creates an s2p or s4p file based on canonnical loss equation fit
//   
//
// (c)2014  L. Rayzman
//
//
// Created      : 03/26/2014
// Last Modified:  03/26/2014
//
//
// ====================================================================
// ====================================================================

//clear;	

stacksize(128*1024*1024);	

///////////////////////////////////////////////////////////////////////////////


foutsparam = emptystr();                        // Filename of S2p Output file
spoutfreqs=[];                                  // Output frequency points vector
spoutdata=[];                                   // Output S-param matrix data

numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

entries_choice=emptystr();                      // Text matrix that describes available entries to view
entry_idx=0;                                    //  

M=[];                                           // Transformation matrix

TempM=[];                                       // Temp matrix

freqMax=20.0e9;                                   // Minimum and maximum frequencies
freqMin=0.01e9;                                                   
freqNum=2001;                                   // Number of frequency points

alphaf=-1.45e-4;                                        // Line loss parameters
betaf=-2.2e-9;
gammaf=0;

len_scalar=1;                                    // Length normalization scaling factor
                                                
                                                
srow=1;                                         // Set the Sxy to plot
scol=1;
spdata_row_col=[];                              // Data points from Sxy where x=row y=col


///////////////////
// Get Scilab Version
///////////////////
version_str=getversion();
version_str=tokens(version_str,'-');
version_str=tokens(version_str(2),'.');
version(1)=msscanf(version_str(1), '%d');
version(2)=msscanf(version_str(2), '%d');


if (version(1)<5) then
  error("Invalid Scilab version. Version 5.2 or greater is required");
elseif (version(2) < 2) then
  error("Invalid Scilab version. Version 5.2 or greater is required");
end    

///////////////////
// Get number of ports
///////////////////

sportcnt=x_choices('',list(list('Select number of ports:',1,['2-port','4-port'])));

if sportcnt==1 then //2-port
    numofports=2;
elseif sportcnt==2 then //4-port
   numofports=4;
else
    messagebox("Invalid number of ports selected. Script aborted", "","error","Abort");      
    abort;
    
end

// Set output filename



///////////////////
// Get frequeny range
///////////////////

labels=["Fmin";"Fmax";"Num of pts"];
[ok,freqMin,freqMax,freqNum]=getvalue("Frequency range (GHz)",labels,...
     list("vec",1,"vec",1,"vec",1),[string(freqMin/1e9);string(freqMax/1e9);string(freqNum)])
     
if ok == 0 then
  messagebox("Why did you press cancel. Don''t you like my script?")
  abort;
end     

freqMin=evstr(freqMin)*1e9;
freqMax=evstr(freqMax)*1e9;
freqNum=evstr(freqNum);




///////////////////
// Get scaling factor
///////////////////

[ok,len_scalar]=getvalue(["Length scaling factor"; ""; "Example: 1 meter : 1 foot = 3.28"],"", list("vec",1),"1.00");

if ok == 0 then
  messagebox("Why did you press cancel. Don''t you like my script?")
  abort;
end


///////////////////
// Get equation coefficients
///////////////////


labels=["Alpha";"Beta";"Gamma"];
[ok,alphaf,betaf,gammaf]=getvalue("Coefficients of loss equation",labels,...
     list("vec",1,"vec",1,"vec",1),[string(alphaf);string(betaf);string(gammaf)])
     
if ok == 0 then
  messagebox("Why did you press cancel. Don''t you like my script?")
  abort;
end     


alphaf=evstr(alphaf);
betaf=evstr(betaf);
gammaf=evstr(gammaf);


///////////////////
// Setup files/directories
///////////////////

if numofports==2 then
    foutsparam=uigetfile("*.s2p", "",  "Please choose destination S-parameters file");      
else
    foutsparam=uigetfile("*.s4p", "",  "Please choose destination S-parameters file");          
end
  

if foutsparam==emptystr() then
    messagebox("Invalid destination file selection. Script aborted", "","error","Abort");      
    abort;
end  


///////////////////
// Create S-param
///////////////////

//Generate frequency vector
spoutfreqs=freqMin:(freqMax-freqMin)/(freqNum-1):freqMax;                   //Generate frequency points

numofreqs=length(spoutfreqs);

// Initialize
spoutdata=ones(numofports,numofports,numofreqs)*(10^(-100/20)+1e-9*%i);


if numofports==2 then  //2-ports version
    for i=1:numofreqs,
      spoutdata(2,1,i)=10^((alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))/20)+1e-9*%i;
      spoutdata(1,2,i)=10^((alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))/20)+1e-9*%i;
    end
else  // 4-port version
    for i=1:numofreqs,
      spoutdata(2,1,i)=10^((alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))/20)+1e-9*%i;   // IL
      spoutdata(1,2,i)=10^((alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))/20)+1e-9*%i;
      spoutdata(4,3,i)=10^((alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))/20)+1e-9*%i;
      spoutdata(3,4,i)=10^((alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))/20)+1e-9*%i;      
    end
        
end

// Compute data for each freq


sptlbx_writetchstn(foutsparam, spoutfreqs,  spoutdata);

messagebox("Done!");


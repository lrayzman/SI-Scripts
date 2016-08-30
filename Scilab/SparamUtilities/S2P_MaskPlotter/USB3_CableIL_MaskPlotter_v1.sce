// ======================   S-param Mask Plotter ====================
// 
// Creates an s2p file with mated cable 
// insertion loss mask per USB 3.0 spec
//
// (c)2012  L. Rayzman
//
//
// Created      : 08/08/2012
// Last Modified:  08/08/2012
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

freqMax=7.5e9;                                   // Minimum and maximum frequencies
freqMin=0.1e9;                                                   
freqNum=2001;                                   // Number of frequency points
                                                
                                                
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





// Set output filename

///////////////////
// Setup files/directories
///////////////////

  
foutsparam=uigetfile("*.s2p", "",  "Please choose destination S-parameters file");                                                

if foutsparam==emptystr() then
    messagebox("Invalid destination file selection. Script aborted", "","error","Abort");      
    abort;
end  



///////////////////
// Perform conversion
///////////////////

numofports = 2;

//Generate frequency vector
spoutfreqs=freqMin:(freqMax-freqMin)/(freqNum-1):freqMax;                   //Generate frequency points

numofreqs=length(spoutfreqs);

// Initialize
spoutdata=zeros(2,2,numofreqs);

// Compute data for each freq
for i=1:numofreqs,
  if spoutfreqs(i)<1.25e9 then
      spoutdata(1,1,i)=10^(-10/20)+1e-9*%i;
      spoutdata(2,2,i)=10^(-10/20)+1e-9*%i;
      spoutdata(2,1,i)=10^((-3.5/1.15*(spoutfreqs(i)/1e9)-1.2)/20)+1e-9*%i;
     spoutdata(1,2,i)=10^((-3.5/1.15*(spoutfreqs(i)/1e9)-1.2)/20)+1e-9*%i;
  end
  if (spoutfreqs(i)>= 1.25e9) & (spoutfreqs(i) < 2.5e9) then
      spoutdata(1,1,i)=10^(-10/20)+1e-9*%i;
      spoutdata(2,2,i)=10^(-10/20)+1e-9*%i;
      spoutdata(2,1,i)=10^((-2.5/1.25*(spoutfreqs(i)/1e9)-2.5)/20)+1e-9*%i;
      spoutdata(1,2,i)=10^((-2.5/1.25*(spoutfreqs(i)/1e9)-2.5)/20)+1e-9*%i;
  end
  
  if (spoutfreqs(i)>= 2.5e9) then
      spoutdata(1,1,i)=10^(-10/20)+1e-9*%i;
      spoutdata(2,2,i)=10^(-10/20)+1e-9*%i;
      spoutdata(2,1,i)=10^((-17.5/5*(spoutfreqs(i)/1e9)+1.25)/20)+1e-9*%i;
      spoutdata(1,2,i)=10^((-17.5/5*(spoutfreqs(i)/1e9)+1.25)/20)+1e-9*%i;
  end
end

sptlbx_writetchstn(foutsparam, spoutfreqs,  spoutdata);

messagebox("Done!");


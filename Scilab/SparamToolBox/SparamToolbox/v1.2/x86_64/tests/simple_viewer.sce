// ==========================S-parameter ToolBox=======================
// ======================   Simple Driver ==============================
// 
// Simple driver function to test sptlbx_readtchstn() function 
// Read in S-parameters and plot the result 
//
// (c)2010-2015  L. Rayzman
//
//
// Created      : 02/06/2010
// Last Modified: 02/14/2014 - Added stacksize
//                07/23/2015 - Added reading of port impedance    
//                08/18/2015 - Added support for reading comments
// ====================================================================
// ====================================================================

clear;		
stacksize(200*1024*1024)

/////////////////////////////////////Specify ////////////////////////////////////
fsparam = emptystr();                           // Filename of HSpice source file
spfreqs=[];                                     // Frequency points vector
spdata=[];                                      // Data points matrix
spZ0=50;                                        // Port impedance
spComment=[];                                   // Comment lines

numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

entries_choice=emptystr();                      // Text matrix that describes available entries to view
entry_idx=0;                                    //  


plotmode=1;                                     // Plot Modes:
                                                //      1 - Magnitude(dB)
                                                //      2 - Phase


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
// Setup files/directories
///////////////////

fsparam=uigetfile("*.s*p", "",  "Please choose S-parameters file");                                                

if fsparam==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
    abort;
end

///////////////////
// Read touchstone file
///////////////////
  
[spfreqs,spdata, spZ0, spComment] =sptlbx_readtchstn(fsparam);


plotmode=x_choose(["Magnitude(dB)", "Phase(Deg)"], 'Please select the viewer mode');
if plotmode == 0 then
  messagebox("Script aborted", "Error", "error")
  abort;
end    

///////////////////
// Show list of available
// entries
///////////////////


numofports=size(spdata,1);                                               //Find number of ports
numofreqs=size(spdata,3);                                                //Find number of frequency points

for i=1:numofports,
  for j=1:numofports, 
     entries_choice((i-1)*numofports+j)=strcat(["S(" string(i) "," string(j) ")"])
  end
end

entry_idx=x_choose(entries_choice, 'Please select the S-parameter to view');
if entry_idx == 0 then
  messagebox("Script aborted", "Error", "error")
  abort;
end    

srow=ceil(entry_idx/numofports);
scol=modulo(entry_idx-1, numofports)+1;


///////////////////
// Plot
///////////////////

//Extract all Sxy into a single vector
spdata_row_col=matrix(spdata(srow,scol,:), 1, numofreqs);

//Plot and make pretty
drawlater();

if plotmode==1 then                                                                      // Magnitude plot
  plot2d(spfreqs, 20*log10(abs(spdata_row_col)), style=2);
  xtitle(entries_choice(entry_idx), "Frequency(Hz)", "Magnitude(dB)");
end

if plotmode==2                                                                           // Phase plot
  plot2d(spfreqs, 180/%pi*atan(imag(spdata_row_col), real(spdata_row_col)), style=2);
  xtitle(entries_choice(entry_idx), "Frequency(Hz)", "Phase(Deg)");
end  
  
a=gcf();                                  // Add gray to the colormap
a.color_map(33,:)=[0.85 0.85 0.85];
a=gca();
a.grid=[33,33];                           // Turn on grid
a.children.children.foreground=2;         // Set foreground to blue

xinfo(strcat(["Port impedance: ", sprintf("%0.1f", spZ0), " Ohms"]))

drawnow();


// ====================================================================

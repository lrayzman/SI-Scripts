// ===============   2-Port Passive Probe Load Extract =================
// 
// Extracts impedance magnitude of load from S21 measurements
//
// (c)2012  L. Rayzman
//
// Created      : 02/06/2012
// Last Modified: 
//
//  Notes: Operates only on 2-port parameters. Ensure frequency points are 
//         identical in all touchstone files.
//         
//        General usage procedure: Measure S21 without the probe load. This is 
//                                 the reference s-param. 
//                                 Install the probe load and measure S21. 
//          
//  
// ====================================================================
// ====================================================================

clear;	

//stacksize(140*1024*1024);	

///////////////////////////////////////////////////////////////////////////////
frefsparam = emptystr();                        // Filename of S2p reference file
spreffreqs=[];                                  // Reference frequency points vector
sprefdata=[];                                   // Reference S-param matrix data


fdutsparam = emptystr();                        // Filename of S2p DUT file
spdutfreqs=[];                                  // DUT frequency points vector
spdutdata=[];                                   // DUT S-param matrix data

spdata=[];                                      // Renormalized S21 data
Zl=[];                                          // Load impedance magnitude

numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

Z0=50;                                          // Reference impedance magnitude

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
// Read touchstone files
///////////////////

//
// Read reference s2p file
//
//
frefsparam=uigetfile("*.s2p", "",  "Please choose unloaded S-parameters file");                                                

if frefsparam==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
    abort;
end

[spreffreqs,sprefdata] =sptlbx_readtchstn(frefsparam);

numofports=size(sprefdata,1);                                               //Find number of ports

if numofports <> 2 then
    messagebox("Only 2-port parameters are supported at this time. Script aborted", "","error","Abort");      
    abort;
end

numoffreqs=size(sprefdata,3);                                                //Find number of frequency points

sleep(5000);
//
// Read DUT data 
//
//
fdutsparam=uigetfile("*.s2p", "",  "Please choose loaded S-parameters file");                                                

if fdutsparam==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
    abort;
end

[spdutfreqs,spdutdata] = sptlbx_readtchstn(fdutsparam);

numofports=size(spdutdata,1);                                               //Find number of ports

if numofports <> 2 then
    messagebox("Only 2-port parameters are supported at this time. Script aborted", "","error","Abort");      
    clear;
    abort;
end

if size(spdutdata, 3) <> numoffreqs then                                     // Check for number of frequencies matching
    messagebox("Number of DUT reference points different than reference. Script aborted", "","error","Abort");   
    clear;
    abort
end

// Check for number of frequencies matching
if ~isequal(spreffreqs, spdutfreqs) then
    messagebox("DUT frequency points different from reference. Script aborted", "","error","Abort");   
    clear;
    abort
end


// Enter impedance
Z0=evstr(x_dialog('Enter reference impedance (hint: differential is 100ohm)','50'))


///////////////////
// Compute probe |Z|
///////////////////
spdata(1:numoffreqs)=spdutdata(2,1,:)./sprefdata(2,1,:);                  // Compute S21

Zl=(Z0/2)*abs(spdata./(1-spdata));

///////////////////
// Plot 
///////////////////

//Plot and make pretty
drawlater();

plot2d(spreffreqs/1e9, Zl, style=2);
xtitle("Impedance magnitude", "Frequency(GHz)", "Impedance (Ohms)");
  
a=gcf();                                  // Add gray to the colormap
a.color_map(33,:)=[0.85 0.85 0.85];
a=gca();
a.grid=[33,33];                           // Turn on grid
a.children.children.foreground=2;         // Set foreground to blue

drawnow();

                                                    



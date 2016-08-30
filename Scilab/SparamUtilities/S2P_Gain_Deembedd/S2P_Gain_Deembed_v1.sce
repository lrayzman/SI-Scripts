// ======================   S-params Gain De-Embedd====================
// 
// Gain-based De-Embedder
// Creates an 2-port touchstone file with De-Embedded magnitude
// and ideal return loss
//
// (c)2012  L. Rayzman
//
//
// Created      : 02/03/2012
// Last Modified: 
//
//  Note: Only 2-port S-params supported at this time
// ====================================================================
// ====================================================================

clear;	

stacksize(140*1024*1024);	

///////////////////////////////////////////////////////////////////////////////
frefsparam = emptystr();                        // Filename of S2p reference file
spreffreqs=[];                                  // Reference frequency points vector
sprefdata=[];                                   // Reference S-param matrix data


fdutsparam = emptystr();                        // Filename of S2p DUT file
spdutfreqs=[];                                  // DUT frequency points vector
spdutdata=[];                                   // DUT S-param matrix data

foutsparam = emptystr();                        // Filename of S2p Output file
spoutfreqs=[];                                  // Output frequency points vector
spoutdata=[];                                   // Output S-param matrix data

numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

entries_choice=emptystr();                      // Text matrix that describes available entries to view
entry_idx=0;                                    //  

srow=1;                                         // Set the Sxy to plot
scol=1;
spdata_row_col=[];                              // Data points from Sxy where x=row y=col

retlossmagdB=-300;                              // Return loss magnitude

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
frefsparam=uigetfile("*.s2p", "",  "Please choose reference S-parameters file");                                                

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

//
// Read DUT data 
//
//
fdutsparam=uigetfile("*.s2p", "",  "Please choose DUT S-parameters file");                                                

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

// Get output filename data 

foutsparam=uiputfile("*.s2p", "",  "Please choose output  S-parameters file");                                                

if foutsparam==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
    abort;
end

///////////////////
// Compute and dump
///////////////////

//
spoutfreqs=spreffreqs;

spoutdata(1,1,:)=10^(retlossmagdB/20)*ones(1,numoffreqs);                        // Fill S11, S22
spoutdata(2,2,:)=10^(retlossmagdB/20)*ones(1,numoffreqs);                        // Fill S11, S22


spoutdata(1,2,:)=spdutdata(2,1,:)./sprefdata(2,1,:);          // Compute S21
spoutdata(2,1,:)=spoutdata(1,2,:);


sptlbx_writetchstn(foutsparam, spreffreqs, spoutdata);

messagebox("Done!");

                                                    



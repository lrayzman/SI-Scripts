// ==========================S-parameter ToolBox=======================
// ======================   Read and Write Test =========================
// 
// Simple function to test sptlbx_readtchstn() and  sptlbx_writetchstn()  
// functions.
//
// (c)2010-2014  L. Rayzman
//
//
// Created      : 02/06/2010
// Last Modified: 02/13/2014  Added printed messages of execution steps
//                            Added stacksize
// ====================================================================
// ====================================================================


clear;		
stacksize(200*1024*1024);

/////////////////////////////////////Specify ////////////////////////////////////
fsparam_src = emptystr();                         // Filename of source file
fsparam_dest = emptystr();
spfreqs=[];                                     // Frequency points
spdata=[];                                      // Data points


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

fsparam_src=uigetfile("*.s*p", "",  "Please choose source S-parameters file");                                                

if fsparam_src==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
    abort;
  end
  
fsparam_dest=uigetfile("*.s*p", "",  "Please choose destination S-parameters file");                                                

if fsparam_dest==emptystr() then
    messagebox("Invalid destination file selection. Script aborted", "","error","Abort");      
    abort;
end  
  
  

///////////////////
// Read touchstone file
///////////////////

[spfreqs,spdata] =sptlbx_readtchstn(fsparam_src);

disp("Finished Reading!");

///////////////////
// Write touchstone file
///////////////////

disp("Now Writing!");
sptlbx_writetchstn(fsparam_dest, spfreqs, spdata);


disp("Execution successful!");

// ====================================================================

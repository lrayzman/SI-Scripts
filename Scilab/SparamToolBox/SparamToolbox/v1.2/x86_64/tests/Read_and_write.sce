// ==========================S-parameter ToolBox=======================
// ======================   Read and Write Test =========================
// 
// Simple function to test sptlbx_readtchstn() and  sptlbx_writetchstn()  
// functions.
//
// (c)2010-2015  L. Rayzman
//
//
// Created      : 02/06/2010
// Last Modified: 02/13/2014  Added printed messages of execution steps
//                            Added stacksize
//                07/22/2015
//                08/18/2015  Added support for update functions
// ====================================================================
// ====================================================================


clear;		
stacksize(200*1024*1024);

/////////////////////////////////////Specify ////////////////////////////////////
fsparam_src = emptystr();                         // Filename of source file
fsparam_dest = emptystr();
spfreqs=[];                                     // Frequency points
spdata=[];                                      // Data points
spZ0=0;                                         // Port impedance
spComment=[];                                   // Comment lines


///////////////////
// Get Scilab Version
///////////////////
version_str=getversion();
version_str=tokens(version_str,'-');
version_str=tokens(version_str(2),'.');
version(1)=msscanf(version_str(1), '%d');
version(2)=msscanf(version_str(2), '%d');


if (version(1)<5) then
  error("Invalid Scilab version. Version 5.2 or greater si required");
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

[spfreqs,spdata,spZ0,spComment] =sptlbx_readtchstn(fsparam_src);

disp(sprintf("Read %d frequency points in an %d port matrix with port impedance %0.1f ohms", size(spfreqs,2),size(spdata,1), spZ0))
disp("Finished Reading!");


///////////////////
// Write touchstone file
///////////////////

disp("Now Writing!");
sptlbx_writetchstn(fsparam_dest, spfreqs, spdata, spZ0, spComment);

disp("Execution successful!");

// ====================================================================

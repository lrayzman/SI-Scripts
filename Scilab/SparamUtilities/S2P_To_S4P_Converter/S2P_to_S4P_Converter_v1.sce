// ======================   S-params Converter ====================
// 
// Converts S2P to S4P file by duplicating 2-port to 4-port
//
// 
//
// (c)2012  L. Rayzman
//
//
// Created      : 11/15/2012
// Last Modified:  11/15/2012
//
//
// ====================================================================
// ====================================================================

clear;	

stacksize(128*1024*1024);	

///////////////////////////////////////////////////////////////////////////////
frefsparam = emptystr();                        // Filename of S2p reference file
spreffreqs=[];                                  // Reference frequency points vector
sprefdata=[];                                   // Reference S-param matrix data


foutsparam = emptystr();                        // Filename of S2p Output file
spoutfreqs=[];                                  // Output frequency points vector
spoutdata=[];                                   // Output S-param matrix data

numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

entries_choice=emptystr();                      // Text matrix that describes available entries to view
entry_idx=0;                                    //  

M=[];                                           // Transformation matrix

TempM=[];                                       // Temp matrix

smapmode=0;                                     // S4P mapping mode
                                                //  1 ==> 1-------- 2
                                                //        3-------- 4
                                                //  
                                                //  2 ==> 1 ------- 3
                                                //        2 ------- 4
                                                
                                                
                                            
                                                
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
// Read touchstone files
// Get user input
///////////////////

//
// Read input s2p file
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
    messagebox("Only 2-port S-parameters are supported. Script aborted", "","error","Abort");      
    abort;
end

numofreqs=size(sprefdata,3);                                                //Find number of frequency points




// Select S4P port mapping
smapmode=x_choose(["1----2 3----4", "1----3 2----4"], 'Please select the s4p mapping mode');
if smapmode == 0 then
  messagebox("Script aborted", "Error", "error")
  abort;
end 

// Get output filename
foutsparam=uiputfile("*.s4p", "",  "Please choose converted S-parameters file");                                                
if foutsparam==emptystr() then
    messagebox("Invalid output  file selection. Script aborted", "","error","Abort");      
    abort;
end

///////////////////
// Perform conversion
///////////////////

// Initialize
spoutdata=zeros(4,4,numofreqs);

// Compute data for each freq
for i=1:numofreqs,
  select smapmode
      case 1 then  spoutdata(1:2,1:2,i)=sprefdata(:,:,i);                    // 1-2, 3-4 mapping
                   spoutdata(3:4,3:4,i)=sprefdata(:,:,i);
          case 2 then  spoutdata(1,1,i)=sprefdata(1,1,i);                                       // 1-3, 2-4 mapping
                       spoutdata(2,2,i)=sprefdata(1,1,i);
                       spoutdata(1,3,i)=sprefdata(1,2,i);
                       spoutdata(2,4,i)=sprefdata(1,2,i);
                       spoutdata(3,1,i)=sprefdata(2,1,i);
                       spoutdata(4,2,i)=sprefdata(2,1,i);
                       spoutdata(3,3,i)=sprefdata(2,2,i);
                       spoutdata(4,4,i)=sprefdata(2,2,i);
   end
end

//
sptlbx_writetchstn(foutsparam,spreffreqs, spoutdata);

messagebox("Done!");


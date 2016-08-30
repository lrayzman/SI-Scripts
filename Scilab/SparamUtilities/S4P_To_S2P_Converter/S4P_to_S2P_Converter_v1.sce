// ======================   S-params Converter ====================
// 
// Converts S4P to Mixed-Mode S2P file (of Type SDD, SDC, SCD, or SCC)
//
// (c)2012  L. Rayzman
//
//
// Created      : 01/30/2012
// Last Modified:  01/30/2012
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
                                                
                                                
smixmode=0;                                     // Output matrix mode
                                                // 1  => SDD
                                                // 2  => SDC
                                                // 3  => SCD
                                                // 4  => SCC                                                
                                                
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
// Read reference s4p file
//
//
frefsparam=uigetfile("*.s4p", "",  "Please choose reference S-parameters file");                                                

if frefsparam==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
    abort;
end

[spreffreqs,sprefdata] =sptlbx_readtchstn(frefsparam);

numofports=size(sprefdata,1);                                               //Find number of ports

if numofports <> 4 then
    messagebox("Only 4-port S-parameters are supported at this time. Script aborted", "","error","Abort");      
    abort;
end

numofreqs=size(sprefdata,3);                                                //Find number of frequency points




// Select S4P port mapping
smapmode=x_choose(["1----2 3----4", "1----3 2----4"], 'Please select the s4p mapping mode');
if smapmode == 0 then
  messagebox("Script aborted", "Error", "error")
  abort;
end 


// Compute transform matrix
if smapmode==1 then
    M=(1/sqrt(2))*[1 0 -1 0; 0 1 0 -1; 1 0 1 0; 0 1 0 1];
elseif smapmode==2 then
    M=(1/sqrt(2))*[1 -1 0 0; 0 0 1 0; 1 1 0 -1; 0 0 1  1];
end

Minv=inv(M);                                                            // Find inverse



// Select s2p output mode
smixmode=x_choose(["SDD" "SDC" "SCD" "SCC"], 'Please select the s4p mapping mode');
if smixmode == 0 then
  messagebox("Script aborted", "Error", "error")
  abort;
end 

// Get output filename
foutsparam=uiputfile("*.s2p", "",  "Please choose converted S-parameters file");                                                
if foutsparam==emptystr() then
    messagebox("Invalid output  file selection. Script aborted", "","error","Abort");      
    abort;
end




///////////////////
// Perform conversion
///////////////////

// Initialize
spoutdata=zeros(2,2,numofreqs);

// Compute data for each freq
for i=1:numofreqs,
  TempM=M*sprefdata(:,:,i)*Minv;
  select smixmode
          case 1 then  spoutdata(:,:,i)=TempM(1:2,1:2);                    // SDD
          case 2 then  spoutdata(:,:,i)=TempM(3:4,1:2);                    // SDC
          case 3 then  spoutdata(:,:,i)=TempM(1:2,3:4);                    // SCD
          case 4 then  spoutdata(:,:,i)=TempM(3:4,3:4);                    // SCC
  end
end

//
sptlbx_writetchstn(foutsparam,spreffreqs, spoutdata);

messagebox("Done!");


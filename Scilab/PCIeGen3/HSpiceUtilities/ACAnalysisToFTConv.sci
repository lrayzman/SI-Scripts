// HSpice AC Analysis Frequency Response to S-parameter converter
//
// (c)2009  L. Rayzman
// Created :      05/14/2009
// Last Modified: 05/14/2009
//
// TODO: 
// 


clear;		
//////////////////////////////////////Extraction Function////////////////////////////////////
function [f, D, Desc] = extract_from_CSDF_Freq(filename)

//  Extracts waveform data from CSDF ASCII files
//
// Inputs:
//        filename -   Filename of the CSDF file
//
//  Outputs:
//        f     - time points
//        D     - Frequency data matrix
//        Desc  - Title and names of the waveforms (string)


stopflag = %F;                          // Stop loop flag

readline=emptystr();
tempstr=emptystr();                      // Temporary string
ttlstr=emptystr();                       // Title
nodecount=0;                             // Nodecount
idxcnt=1;                                // Timestamp index count;

f=[];                                    // Initialize function output vectors
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
    if (convstr(part(readline,[1:2]),"u") == "#C") then                //If reached data line for current frequency point
        tempstr=strsplit(readline,2);                                  //Process data linet
        tempstr=tempstr(2);                                           
        readline=mgetl(fhandle,1);                                     //Process subsequent lines until start of next timestep
        while (part(readline, [1:2]) ~= "#C") & (part(readline, [1:2]) ~= "#;") & (~meof(fhandle)) ,
           tempstr = tempstr + readline;
           readline=mgetl(fhandle,1); 
        end
         tempstr=tokens(tempstr);                                     // Process all data entries
         f(idxcnt)=sscanf(tempstr(1), "%f");                               // Get frequency point
         if sscanf(tempstr(2), "%d") ~= nodecount then
              error("Data Parser: Reported node count does not match the count in data");
         end
         for k=1:((size(tempstr,1)-2)/2),
            D(idxcnt,k)=sscanf(tempstr(2*k+1), "%f");
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



/////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////Main Routine////////////////////////////////////

facdata = emptystr();                           // Filename(s) of the pulse response *.ac* file(s)
fmatvardata = emptystr();                       // Filename of frequency matrix file
dialogstr=emptystr();                           // Temporary string for storing dialog information

waveformstr=emptystr();                         // Node to be converted
frdata=[];                                      // Extracted frequency data
Desc=[];                                        // Node name
D=[];                                           // Extracted frequency data
waveidx=0;                                      // Index of the node in the extracted data

FTable=[];                                      // All frequency data

///////////////////
// Get Scilab Version
///////////////////
version_str=getversion();
version_str=tokens(version_str,'-');
version_str=tokens(version_str(2),'.');
version(1)=msscanf(version_str(1), '%d');
version(2)=msscanf(version_str(2), '%d');

///////////////////
// Setup files/directories
///////////////////

if (version(1)==5) & (version(2) >= 1) then                                                                           // tr* file(s)
    facdata=uigetfile("*.ac*", "", "Please choose pulse response *.ac* file(s)", %t);                                                
else
   facdata=tk_getfile("*.ac*", Title="Please choose pulse response *.ac* file(s)", multip="1");                                              
end

if facdata==emptystr() then
  if (version(1)==5) & (version(2) >= 1) then   
    messagebox("Invalid file selection. Script aborted", "","error","Abort");      
   else
     buttondialog("Invalid file selection. Script aborted", "Abort");
   end
  abort;
end

 
ffreqdata=tk_savefile("*.ft", strsubst(fileparts(facdata(1), "path"),"\","/"), Title="Please choose converted frequency file");        // Touchstone file
 if ffreqdata==emptystr() then
    if (version(1)==5) & (version(2) >= 1) then      
         messagebox("Invalid file selection. Script aborted", "","error","Abort");  
    else
       buttondialog("Invalid file selection. Script aborted", "Abort");
    end
   abort;
end

if length(fileparts(ffreqdata, "extension"))==0 then
    ffreqdata=strcat([ffreqdata ".ft"]);
end  

olddir=getcwd();
chdir(fileparts(facdata(1), "path"));


////////////////////
// Waveform Info
///////////////////
dialogstr=x_mdialog(['Enter waveform parameters:'], ['Waveform Name'],['VDB(outp, outn)']);
if length(dialogstr)==0 then
  
  if (version(1)==5) & (version(2) >= 1) then      
     messagebox("Invalid parameters selection. Script aborted", "","error","Abort"); 
  else
    buttondialog("Invalid parameters selection. Script aborted", "Abort");
  end
  chdir(olddir);
  abort;
end
waveformstr=strcat(tokens(dialogstr(1), " "));         // Strip spaces in the waveform string
waveformstr=strcat(tokens(waveformstr, "("));         // Strip '(' in the waveform string
waveformstr=strcat(tokens(waveformstr, ")"));         // Strip '(' in the waveform string

if (convstr(part(waveformstr,[1:3]),"u") == "VDB") then   // Clean up the node name
  waveformstr=part(waveformstr,[4:length(waveformstr)]);
end  

if (convstr(part(waveformstr,[1:2]),"u") == "VP") then   // Clean up the node name
  waveformstr=part(waveformstr,[3:length(waveformstr)]);
end  
  

///////////////////
// Main Conversion
///////////////////

                                                                                                    // Create multi-dim FT matrix

numoffiles=size(facdata,1);

for f=1:numoffiles,                                                                                 //For each ac* pulse response file
    currenttime=getdate();
    printf("\n****Starting conversion of frequency file %d of %d at %0.2d:%0.2d:%0.2d\n", f, numoffiles, currenttime(7), currenttime(8), currenttime(9));
  
    [frdata, D, Desc] = extract_from_CSDF_Freq(facdata(f));                                         // Extract frequency data
    waveidx=grep(Desc, strcat(["vdb(" waveformstr ")"]))-1;    
    
    if waveidx==-1 then
  
        if (version(1)==5) & (version(2) >= 1) then      
              messagebox("Unable to find waveform. Script aborted", "","error","Abort"); 
        else
              buttondialog("nable to find waveform. Script aborted", "Abort");
        end
          chdir(olddir);
            abort;  
        end
    
    
      // Append to matrix
      FTable=lstcat(FTable,[frdata D(:,1)+%i*D(:,2)]);        
      
      //Plot
      clf();
      bode(frdata(find(frdata>=1e7)), D(find(frdata>=1e7), waveidx), D(find(frdata>=1e7), waveidx+1));    //Plot from min of 10MHz
      grph=gcf();                                                                                            //Set pretty colors
      grph.children(1).children.children.foreground=2; 
      grph.children(2).children.children.foreground=2; 
      

end

// Clear out the initial empty matrix
FTable(1)=null();

// Save matrix file
save(ffreqdata, FTable);

//Restore original directory
chdir(olddir);

//clean up
clear FTable;
clear facdata;
clear fmatvardata;
clear dialogstr;
clear waveformstr;
clear frdata;                                   
clear Desc;
clear D;
clear waveidx;


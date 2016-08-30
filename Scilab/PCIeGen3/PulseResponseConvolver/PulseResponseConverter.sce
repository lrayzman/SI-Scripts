// Pulse Response to impulse response (Freq Domain) converter.
// Imports pulse response from HSpice *.tr files and 
// computes impulse response in frequency domain file
// 
//
// Use for bus simulations from Intel
//
//
// (c)2009  L. Rayzman
// Created :      04/03/2009
// Last Modified: 04/03/2009 - Initial
//
//
// NOTES:
//        
//


//stacksize(16*1024*1024);

clear;																													//Clear all user created variables
getf("HSPiceUtilities.sci");                                                                                    // Include PWL extraction function

//////////////////////////////////////SPECIFY////////////////////////////////////

//////////////////////////////////////Main Routine////////////////////////////////////

fsource = emptystr();                             // Filename of HSpice source file
fwvfrm = emptystr();                             // Converted waveform filename
fcnvpar = emptystr();                              // Converter instructions file
fhpwlout=emptystr();                                // PWL output
cmdlinestr=emptystr();                            // HSpice converter command line string.
olddir=emptystr();                                // Original directory path
dialogstr=emptystr();                           // Temporary string for storing dialog information
waveformstr=emptystr();                         // Waveform to be converted


t = [];                                           // Time points vector from tr* file
Doft = [];                                        // Waveform vector from tr*  file

///////////////////
// Load PWL file
///////////////////
version_str=getversion();
version_str=tokens(version_str,'-');
version_str=tokens(version_str(2),'.');
version(1)=msscanf(version_str(1), '%d');
version(2)=msscanf(version_str(2), '%d');

  if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
    fsource=uigetfile("*.tr*", boxTitle="Please choose input *.tr* file");                                                
  else
    fsource=tk_getfile("*.tr*", Title="Please choose input *.tr* file");     
  end


if fsource==emptystr() then
   if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file check
     messagebox("Invalid file selection. Script aborted", "","error","Abort");                                                   
  else
     buttondialog("Invalid file selection. Script aborted", "Abort");    
  end
  abort;
end


fhpwlout=tk_savefile("*.inc", strsubst(fileparts(fsource, "path"),"\","/"), Title="Please choose output file");      // S2P file


if fhpwlout==emptystr() then
  
  if (version(1)==5) & (version(2) >= 1) then                                                                           // S2P file check
     messagebox("Invalid file selection. Script aborted", "","error","Abort");                                                  
  else
       buttondialog("Invalid file selection. Script aborted", "Abort");
  end
  abort;
end


//Set new directory name for Hspice conversion
olddir=getcwd();
chdir(fileparts(fsource, "path"));

//Get waveform info
dialogstr=x_mdialog('Enter waveform name:', ' ', 'diff_lecroy_lai2');
if length(dialogstr)==0 then
  
  if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
     messagebox("Invalid parameters selection. Script aborted", "","error","Abort");                                                
  else
         buttondialog("Invalid parameters selection. Script aborted", "Abort");
  end

  chdir(olddir);
  abort;
end
waveformstr=strcat(tokens(dialogstr(1), " "));         // Strip spaces in the waveform string (workaround Hspice bug)



//Create conversion command line  
cmdlinestr="converter -t PWL -i "  + strcat([fileparts(fsource, "fname"), fileparts(fsource, "extension")]) + " -o " + strcat([fileparts(fsource, "fname"), ".dat"]) + " < cnvparams.txt";

//Create converter input file
fcnvpar=strcat([fileparts(fsource, "path"), "cnvparams.txt"]);                                          // Set instructions file. 


[fhandle,err]=mopen(fcnvpar, "w");  
if err<0 then
   chdir(olddir);
   error("Unable to create conversion instructions file");  
   abort;
end   

mfprintf(fhandle,"1\n%s\n\n%s\n\n\n",waveformstr,waveformstr); 

mclose(fhandle);

disp("***Begin tr* conversion***");

//run converter
  if unix(cmdlinestr) ~= 0 then                                          // Run simulation
    
   if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
     messagebox("Conversion Failed. Script aborted", "","error","Abort");                                                
  else
     buttondialog("Conversion Failed. Script aborted", "Abort");
  end
     chdir(olddir);
     abort;
  end


//fwvfrm = strcat([fileparts(fsource, "fname"), ".dat", part(fileparts(fsource, "extension"), [4:length(fileparts(fsource, "extension"))])]);
fwvfrm = strcat([fileparts(fsource, "fname"), ".dat0"]);


        
disp("***Begin data extraction***");
//Extract frequency response from file
[t, Doft]=extract_from_PWL(fwvfrm);


//Revert to original directory
chdir(olddir);
 
//Plot the unmodified data
xinit()
plot2d(t, Doft, style=2);
xtitle("Pulse Response", "Time(s)", waveformstr);

//Remove duplicate initial entry
if(t(1)==t(2)) then
  t=t(2:$);
  Doft=Doft(2:$);
end

//Restart at t=0
t=t-t(1);


//Remove DC offset
Doft=Doft-Doft(1);

//clear fsource;
clear fwvfrm;
clear fcnvpar;
clear dialogstr;
clear waveformstr;
clear cmdlinestr;

///////////////////
// Create PWL source file
///////////////////


[fhandle, err]=mopen(fhpwlout, 'w');

mfprintf(fhandle, ".SUBCKT impulse_src Out Gnd_Src\n");
mfprintf(fhandle, "Vsrc Out Gnd_Src PWL (\n");
for  i=1:length(t),
	mfprintf(fhandle, "+ %0.6e %0.16e\n", t(i),Doft(i));
end

mfprintf(fhandle, ")\n");
mfprintf(fhandle, ".ENDS\n");

mclose(fhandle);

clear fhandle;
clear t;
clear Doft;


disp("***Conversion Complete***");








    

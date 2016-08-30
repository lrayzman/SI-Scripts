//  DFE Test

clear;		
getf("..\HSpiceUtilities\HSPiceUtilities.sci");                       // Include HSpice utilities
getf("FT_prFunction.sci");                         // Include FT function


/////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////Main Routine////////////////////////////////////

waveformstr=emptystr();                         // Waveform to be analyzed
ftrdata = emptystr();                           // Filename(s) of the pulse response *.tr* file(s)
fcnvpar = emptystr();                           // Converter instructions file
cmdlinestr=emptystr();                          // HSpice converter command line string.
olddir=emptystr();                              // Original directory path

t = [];                                         // Time points vector from tr* file
D = [];                                         // Waveform vector from tr*  file

load("..\HSpiceUtilities\m21482.ft", "FTable");                      // Load frequency table

coeffs_in=[0.25 -0.25 64 1;...                // DFE coefficients specification
0.2 -0.2 64 1;...
0.1 -0.1 64 1];

opt_coeffs_out=[];                              // Optimized coefficients values
Dfe_alg_type=1;                                 // Dfe algorithm type
prerr=0;                                        // Pulse response error


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
    ftrdata=uigetfile("*.tr*", "", "Please choose pulse response *.tr* file(s)", %f);                                                
else
   ftrdata=tk_getfile("*.tr*", "", Title="Please choose pulse response *.tr* file(s)", multip="0");                                              
end

if ftrdata==emptystr() then
  if (version(1)==5) & (version(2) >= 1) then   
    messagebox("Invalid file selection. Script aborted", "","error","Abort");      
   else
     buttondialog("Invalid file selection. Script aborted", "Abort");
   end
  abort;
end


///////////////////
// Waveform Info
///////////////////
dialogstr=x_mdialog(['Enter waveform parameters:'], ['Waveform Name'],['V(rxbump_p, rxbump_n)']);
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


///////////////////
// Run file conversion
///////////////////

//Set new directory name for Hspice conversion
olddir=getcwd();
chdir(fileparts(ftrdata, "path"));

//Create conversion command line  
cmdlinestr="converter -t PWL -i "  + strcat([fileparts(ftrdata, "fname"), fileparts(ftrdata, "extension")]) + " -o " + strcat([fileparts(ftrdata, "fname"), ".dat"]) + " < cnvparams.txt";

//Create converter input file
fcnvpar=strcat([fileparts(ftrdata, "path"), "cnvparams.txt"]);                                          // Set instructions file. 


[fhandle,err]=mopen(fcnvpar, "w");  
if err<0 then
   chdir(olddir);
   error("Pulse Convolver: Unable to create conversion instructions file");  
   abort;
end   

mfprintf(fhandle,"1\n%s\n\n%s\n\n\n",waveformstr,waveformstr); 

mclose(fhandle);

//run converter
  if unix(cmdlinestr) ~= 0 then                                          // Run simulation
    
   if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
     messagebox("Pulse Convolver: Conversion Failed. Script aborted", "","error","Abort");                                                
  else
     buttondialog("Pulse Convolver: Conversion Failed. Script aborted", "Abort");
  end
     chdir(olddir);
     abort;
  end

fwvfrm = strcat([fileparts(ftrdata, "fname"), ".dat0"]);

   
//Extract frequency response from file
[t, D]=extract_from_PWL(fwvfrm);


//Revert to original directory
chdir(olddir);

///////////////////
// Run CTLE
///////////////////
//xinit();


[t, D] = FT_pr(t, D, 125e-12, FTable(1)(:,1), FTable(1)(:,2));



///////////////////
// Run DFE
///////////////////

//[t, D, opt_coeffs_out, prerr]= DFE_pr(t, D, coeffs_in, 125e-12, Dfe_alg_type);

///////////////////
// Create PWL
///////////////////

[fhandle, err]=mopen("impulse.inc", 'w');

mfprintf(fhandle, ".SUBCKT impulse_src Out Gnd_Src\n");
mfprintf(fhandle, "Vsrc Out Gnd_Src PWL (\n");
for  i=1:length(t),
	mfprintf(fhandle, "+ %0.6e %0.16e\n", t(i),D(i));
end

mfprintf(fhandle, ")\n");
mfprintf(fhandle, ".ENDS\n");

mclose(fhandle);

///////////////////
// Post REsults
///////////////////

//xinit();
plot2d(t, D, style=2);
xtitle("Pulse Response after DFE", "Time", "Voltage");

//Post values of optimized coefficients
for i=1:length(opt_coeffs_out)
    printf("\n*Optimized value for coefficient %d= %0.2f", i, opt_coeffs_out(i));
end    
printf("\n*Pulse response residual error    = %0.6f\n", prerr);











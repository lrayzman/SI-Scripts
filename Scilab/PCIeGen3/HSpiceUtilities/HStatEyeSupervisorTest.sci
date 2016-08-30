// HSpiceRF StatEye automation supervisor script 
//
// (c)2009  L. Rayzman
// Created :      03/25/2009
// Last Modified: 03/25/2009
//                04/03/2009 - Added option for time-domain pulse response
//
// TODO: 
// 


clear;		
getf("HSPiceUtilities.sci");                       // Include HSpice utilities

//////////////////////////////////////SPECIFY//////////////////////////////////////

//PCISIG CTLE
param1=list("RX CTLE DCGain",..
["GDC_CTLE"],..
["-3dB";"-4dB"; "-5dB";"-6dB"; "-7dB"; "-8dB"; "-9dB"; "-10dB"; "-11dB"; "-12dB"; "-13dB"],..
[-3;..
-4;..
-5;..
-6;..
-7;..
-8;..
-9;..
-10;..
-11;..
-12;..
-13]);

param2=list("RX CTLE Pole1 Freq",..
["POLE1_CTLE"],..
["2.0GHz";"2.5GHz"],..
[2.0e9*2*%pi;..
2.5e9*2*%pi]);

param=list(param1, param2);


/////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////Main Routine////////////////////////////////////

sweepplan=[];                                   // Sweep plan
cmdlinestr=emptystr();                          // HSpice command line string.
cnvcmdlinestr=emptystr();                       // Converter command line string.
olddir=emptystr();                              // Original directory path
results=emptystr();                             // Measured results output
fsource = emptystr();                           // Filename of HSpice source file
fparams = emptystr();                           // Filename of the parameters includes
ftrdata = emptystr();                           // Filename(s) of the pulse response *.tr* file(s)
ffreqdata = emptystr();                         // Filename of frequency (touchstone) file
fcnvpar=emptystr();                             // Converter instructions file
dialogstr=emptystr();                           // Temporary string for storing dialog information

Rj=0;                                           // Source Rj
tUIin=0;                                        // Unit Interval for all measurements
waveformstr=emptystr();                         // Waveform to be analyzed
fresults = "results";                           // Define results filename
M=0;                                            // Samples per UI
TD_EN=%t;                                       // True=use time-domain-based pulse response


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

if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
    fsource=uigetfile("*.sp", "",  "Please choose input source file");                                                
else
   fsource=tk_getfile("*.sp", Title="Please choose input source file");                                              
end

if fsource==emptystr() then
  if (version(1)==5) & (version(2) >= 1) then                                                                           // Source file
    messagebox("Invalid file selection. Script aborted", "","error","Abort");      
  else
    buttondialog("Invalid file selection. Script aborted", "Abort");
  end
  abort;
end

if (version(1)==5) & (version(2) >= 1) then                                                                           // tr* file(s)
    ftrdata=uigetfile("*.tr*", strsubst(fileparts(fsource, "path"),"\","/"), "Please choose pulse response *.tr* file(s)", %t);                                                
else
   ftrdata=tk_getfile("*.tr*", strsubst(fileparts(fsource, "path"),"\","/"), Title="Please choose pulse response *.tr* file(s)", multip="1");                                              
end

if ftrdata==emptystr() then
  if (version(1)==5) & (version(2) >= 1) then   
    messagebox("Invalid file selection. Script aborted", "","error","Abort");      
   else
     buttondialog("Invalid file selection. Script aborted", "Abort");
   end
  abort;
end

fparams=tk_savefile("*.inc", strsubst(fileparts(fsource, "path"),"\","/"), Title="Please choose parameters source file");        // Parameters file
if fparams==emptystr() then
   if (version(1)==5) & (version(2) >= 1) then      
    messagebox("Invalid file selection. Script aborted", "","error","Abort");      
    else
    buttondialog("Invalid file selection. Script aborted", "Abort");
   end
  abort;
end

if length(fileparts(fparams, "extension"))==0 then
   fparams=strcat([fparams ".inc"]);
end  


if TD_EN==%t then
    ffreqdata=tk_savefile("*.inc", strsubst(fileparts(fsource, "path"),"\","/"), Title="Please choose converted pulse response file");        // Touchstone file
    if ffreqdata==emptystr() then
     if (version(1)==5) & (version(2) >= 1) then      
         messagebox("Invalid file selection. Script aborted", "","error","Abort");  
     else
        buttondialog("Invalid file selection. Script aborted", "Abort");
     end
    abort;
  end

  if length(fileparts(ffreqdata, "extension"))==0 then
     ffreqdata=strcat([ffreqdata ".inc"]);
  end 

else
 
  ffreqdata=tk_savefile("*.s2p", strsubst(fileparts(fsource, "path"),"\","/"), Title="Please choose converted frequency file");        // Touchstone file
  if ffreqdata==emptystr() then
     if (version(1)==5) & (version(2) >= 1) then      
         messagebox("Invalid file selection. Script aborted", "","error","Abort");  
     else
        buttondialog("Invalid file selection. Script aborted", "Abort");
     end
    abort;
  end

  if length(fileparts(ffreqdata, "extension"))==0 then
     ffreqdata=strcat([ffreqdata ".s2p"]);
  end  
end

//Set new directory name for Hspice simulation
olddir=getcwd();
chdir(fileparts(fsource, "path"));

////////////////////
// Waveform Info
///////////////////
dialogstr=x_mdialog(['Enter waveform parameters:'], ['Waveform Name'; 'Rj (ps)'; 'Unit Interval (ps)'; 'Sampling Ratio (per UI)'],['diff_LECROY_LAI2';'0';'125';'32']);
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
Rj=evstr(dialogstr(2))*1e-12;
tUIin=evstr(dialogstr(3))*1e-12;
M=evstr(dialogstr(4));

///////////////////
// Create sweep plan
///////////////////
cancelselection=%F;
numofparams=1;
swpparamslist=[];
swpparams=[];
rangestartidx=1;
rangeendidx=1;

for m=1:length(param),         // String all parameter names
  paramstring(m)=param(m)(1);
end  

while cancelselection==%F,                                      //Obtain list of parameters to be swept
  dialogstr=sprintf("Select parameter %d", numofparams);
  choice=x_choose(paramstring,dialogstr, "Stop");
  if (choice == 0) & (~isempty(swpparamslist))  then
    cancelselection = %T;
  elseif (choice == 0) & (isempty(swpparamslist)) then
     if (version(1)==5) & (version(2) >= 1) then      
        messagebox("At least one parameter must be selected", "error", "No parameter selected");
     else
        buttondialog("At least one parameter must be selected", "No parameter selected");
     end
  else  
    swpparamslist=cat(2, swpparamslist, choice);
    numofparams=numofparams+1;
  end
end


                                                              // TODO: MORE ERROR CHECKING. ERROR LOOP IS DISABLED

for k=1:numofparams-1,                                         // Obtain sweep range for each parameter to be swept
   paramstring=emptystr();
  for m=1:size(param(swpparamslist(k))(3),1),                   // Get description of all values for given parameter
      paramstring(m)=param(swpparamslist(k))(3)(m);
  end
//   cancelselection==%F;
//  while cancelselection==%F do                                              // Get starting value of a given parameter sweep
      dialogstr=sprintf("Select starting range of parameter %d", k);
      choice=x_choose(paramstring, dialogstr, "Cancel");
      if (choice == 0) then
           if (version(1)==5) & (version(2) >= 1) then      
              messagebox("Invalid selection. Please select an entry from the list. Script aborted", "error", "Abort");
            else
                 buttondialog("Invalid selection. Please select an entry from the list. Script aborted", "Abort");
            end
          chdir(olddir);
          abort;
    elseif (choice == size(paramstring,1)) then
         if (version(1)==5) & (version(2) >= 1) then      
          messagebox("Invalid selection. Please do not select last entry from the list. Script aborted","error",  "Abort");
         else
             buttondialog("Invalid selection. Please do not select last entry from the list. Script aborted", "Abort");
         end
          chdir(olddir);
          abort;
      else
        rangestartidx=choice;
        cancelselection = %T;
      end      
//    end   
  
//  cancelselection==%F;
//   while cancelselection==%F do                                              // Get ending value of a given parameter sweep
      dialogstr=sprintf("Select ending range of parameter %d", k);
      choice=x_choose(paramstring,dialogstr, "Cancel");
      if (choice == 0) then
         if (version(1)==5) & (version(2) >= 1) then 
           messagebox("Invalid selection. Please select an entry from the list. Script aborted", "error", "Abort");
          else
          buttondialog("Invalid selection. Please select an entry from the list. Script aborted", "Abort");
         end
          chdir(olddir);
          abort;
    elseif (choice < rangestartidx ) then
          if (version(1)==5) & (version(2) >= 1) then    
             messagebox("Invalid selection. Please select an entry that follows the range starting entry. Script aborted", "error", "Abort");
          else
            buttondialog("Invalid selection. Please select an entry that follows the range starting entry. Script aborted", "Abort");
          end
          chdir(olddir);
          abort;
      else
        rangeendidx=choice;
        cancelselection = %T;
      end      
//   end   
  
  swpparams=cat(2, swpparams, [swpparamslist(k); rangestartidx; rangeendidx]);
end 
  
//Flatten sweep parameters into a sweep plan
numofsweeps=prod(swpparams(3,:)-swpparams(2,:)+1);                    // Obtain total number of sweeps as well

sweepidxtracker=[ones(1, size(swpparams,2)); swpparams(3,:)-swpparams(2,:)+1];       // Reset sweep index tracker and obtain maximum number per parameter

for i=1:numofsweeps,
  tempmtrx=[];
  rolloverflag=%F;
  for j=1:size(swpparams,2),
    tempmtrx=cat(2, tempmtrx, [swpparams(1,j) sweepidxtracker(1, j)+swpparams(2,j)-1]);               // Place current  parameter set into sweep plan
  end
 sweepplan=cat(2, sweepplan, tempmtrx');
 
 for j=size(swpparams,2):-1:1,                                                        //Increment all indices as necessary
    if (j<size(swpparams,2)) & rolloverflag == %T then                                // If not last one and roll over flag is set, clear flag and increment 
        sweepidxtracker(1, j) = sweepidxtracker(1, j) + 1;
        rolloverflag = %F;
     end 
     if j==size(swpparams,2) then                                                   // Else if last one -- increment for last one unconditionally
          sweepidxtracker(1, j) = sweepidxtracker(1, j) + 1;
     end
     if sweepidxtracker(1, j) > sweepidxtracker(2, j) then                          // If roll over, reset to one and signal flag to roll over
        sweepidxtracker(1, j) = 1;
        rolloverflag = %T;
     end
        
 end
end  

// Clean up memory

clear sweepidxtracker;
clear cancelselection;
clear swpparamslist;
clear swpparams;
clear rangestartidx;
clear rangeendidx;

///////////////////
// Execute simulation
///////////////////

absstarttime=getdate();

numoffiles=size(ftrdata,1);

for f=1:numoffiles,                                                                                 //For each tr* pulse response file
    currenttime=getdate();
    printf("\n****Starting conversion of Pulse Response for file %d of %d at %0.2d:%0.2d:%0.2d\n", f, numoffiles, currenttime(7), currenttime(8), currenttime(9));
  
  if TD_EN==%t then
   pulse_convolver_td(ftrdata(f), ffreqdata, waveformstr);                                            // Convert time-domain to PWL file
  else
   pulse_convolver_sp(ftrdata(f), ffreqdata, waveformstr, M, tUIin);                                  // Convert time-domain to frequency domain file
  end
  
  for a=1:numofsweeps,
     fparamshandle=mopen(fparams, "w");                                                             // Create/overwrite parameters include file
  
     for k=1:numofparams-1,                                                                         // Write the parameters
      num=sweepplan(k*2-1, a);                                                                      // Get the number of the parameter
      val=sweepplan(k*2, a);                                                                        // Get the value of the parameter set
    
      for b=1:size(param(num)(2),2)                                                                 // For each parameter string
          mfprintf(fparamshandle, ".PARAM %s=%f\n", param(num)(2)(b), param(num)(4)(val, b));       // concatenate value and parameter into the file
      end
  
     end
   
     mclose(fparamshandle);                                                                         //Close parameters include file

     currenttime=getdate();
     printf("\n****Starting simulation for iteration %d of %d at %0.2d:%0.2d:%0.2d\n", (f-1)*numofsweeps+a, numoffiles*numofsweeps, currenttime(7), currenttime(8), currenttime(9));
     
     cmdlinestr="rmdir /s /q " + fileparts(fsource, "fname") + ".printSte0";               //Remove existing simulation output directory (Hspice RF Bug)
     unix(cmdlinestr);
     
        
     cmdlinestr="start /wait /min hspicerf -a "  + strsubst(fsource,"/","\");                             // Run simulation
   
    if unix(cmdlinestr) ~= 0 then       
       if (version(1)==5) & (version(2) >= 1) then      
         messagebox("HSpice simulation Failed. Script aborted", "error", "Abort");
       else
          buttondialog("HSpice simulation Failed. Script aborted", "Abort");
       end
       chdir(olddir);
        abort;
        end
     
     cmdlinestr="taskkill /IM wgnuplot.exe";                                                         // Close existing gnuplot
     unix(cmdlinestr);  
  
     cmdlinestr="start /wait /min xcopy /s /Y " + fileparts(fsource, "fname") + ".printSte0\* GnuData\";                //Move output to directory
     unix(cmdlinestr);
     
     cmdlinestr="start wgnuplot display";                                                                    //Plot eye
     unix(cmdlinestr);
     
     temp=fscanfMat(fileparts(fsource, "fname") + ".mste0");
     tUI=tUIin;
     ew=temp(1);
     eh=temp(2);
     clear temp;
     
     results=cat(2, results, [f; sweepplan(:, a); tUI ; eh ; ew]);                                   // Log eye parameters
    
    //Post results for simulation
    printf("\n*Measured bit-period: %0.2fps", tUI*1e12);
    printf("\n*Measured Eye Height: %0.3fV", eh);
    printf("\n*Measured Eye Width: %0.2fps\n", ew*1e12 );
  end
end

// 
//
absendtime=getdate();
printf("\n****************************\n")
printf("Total simulation time is %0.2f sec\n", etime(absendtime, absstarttime));
printf("****************************\n")

//Restore original directory
chdir(olddir);

///////////////////
//  Post Results
///////////////////

//Print header to file

fresultshndl=mopen(strcat([fresults '.txt']), 'w');

mfprintf(fresultshndl, "|-----|--------");
for a=1:numofparams-1,
  mfprintf(fresultshndl, "|------------------------------");
end  
mfprintf(fresultshndl, "|------------------------------|\n|     |        ");
for a=1:numofparams-1,
    mfprintf(fresultshndl, "|           Param%d             ", a);
end  
mfprintf(fresultshndl, "|                              |\n|  #  |  File  ");

for a=1:numofparams-1,
  mfprintf(fresultshndl, "|        Name         |  Value "); 
end  

mfprintf(fresultshndl, "|   tUI    |   EH   |    EW    |\n|-----|--------");
for a=1:numofparams-1,
  mfprintf(fresultshndl, "|------------------------------");
end  
mfprintf(fresultshndl, "|------------------------------|\n");


//Print Body
for f=1:numoffiles,
  for a=1:numofsweeps,
      mfprintf(fresultshndl, "|%3d  |   %2d   |" , (f-1)*numofsweeps+a, results(1,(f-1)*numofsweeps+a));
      for b=1:numofparams-1
        mfprintf(fresultshndl, "%20s | %6s |", param(results((b*2),(f-1)*numofsweeps+a))(1), param(results((b*2),(f-1)*numofsweeps+a))(3)(results((b*2)+1,(f-1)*numofsweeps+a)));
      end
      mfprintf(fresultshndl, " %0.2fps | %0.3fV | %6.2fps |\n", results((numofparams-1)*2+2,(f-1)*numofsweeps+a)*1e12, results((numofparams-1)*2+3,(f-1)*numofsweeps+a), results((numofparams-1)*2+4,(f-1)*numofsweeps+a)*1e12);
  end
end
mfprintf(fresultshndl, "|-----|--------");
for a=1:numofparams-1,
  mfprintf(fresultshndl, "|------------------------------");
end  
mfprintf(fresultshndl, "|------------------------------|\n");

mclose(fresultshndl);


cmdlinestr=emptystr();
cmdlinestr=strcat(['notepad ' fresults '.txt']);
unix(cmdlinestr);     // Display results

//Plot Eye Height and Eye Width Results
drawlater;
clf();
subplot(2,1,1);
plot2d3(linspace(1,numoffiles*numofsweeps,numoffiles*numofsweeps),results((numofparams-1)*2+4,:)*1e12, style=2);
xtitle("Eye Width","Sim #", "Eye opening (ps)");
//a=get("current_axes");
//a.x_ticks.locations = linspace(1,numofsweeps,numofsweeps)';
xgrid(4);
subplot(2,1,2);
plot2d3(linspace(1,numoffiles*numofsweeps,numoffiles*numofsweeps),results((numofparams-1)*2+3,:), style=2);
//a=get("current_axes");
//a.x_ticks.locations = linspace(1,numofsweeps,numofsweeps)';
xtitle("Eye Height","Sim #", "Eye opening (V)");
xgrid(4);
drawnow; 
//Save results to a file
xsave(strcat([fresults '.scg']), 0)






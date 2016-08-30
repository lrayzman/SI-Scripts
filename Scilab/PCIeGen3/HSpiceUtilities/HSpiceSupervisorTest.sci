// HSpice automation supervisor script example
//
// (c)2008  L. Rayzman
// Created :      10/17/2008
// Last Modified: 10/20/2008
//                11/05/2008 - Results saved to text and graphics files
//                11/08/2008 - Added user-specified Dj and tUI terms.
//
// TODO: 
// 


clear;		
getf("HSPiceUtilities.sci");                       // Include HSpice utilities

//////////////////////////////////////SPECIFY//////////////////////////////////////

// VSC 33xx Output Level                        // Vitesse VSC33xx parameters
param1=list("Src Output Level",..
["SRCVOUT14" "SRCVOUT13" "SRCVOUT12" "SRCVOUT11" "SRCVOUT10" "SRCVOUT9" "SRCVOUT8" "SRCVOUT7" "SRCVOUT6" "SRCVOUT5" "SRCVOUT4" "SRCVOUT3" "SRCVOUT2" "SRCVOUT1" "SRCVOUT0"],..
["360 mV";"380 mV";"400 mV";"440 mV";"470 mV";"500 mV";"550 mV";"600 mV";"650 mV";"720 mV";"800 mv";"900 mv";"1000 mV"; "Unused1";"Unused2"],..
[0 0 0 0 0 0 0 0 0 0 0 0 0 0 1;..
0 0 0 0 0 0 0 0 0 0 0 0 0 1 1;..
0 0 0 0 0 0 0 0 0 0 0 0 1 1 1;..
0 0 0 0 0 0 0 0 0 0 0 1 1 1 1;..
0 0 0 0 0 0 0 0 0 0 1 1 1 1 1;..
0 0 0 0 0 0 0 0 0 1 1 1 1 1 1;..
0 0 0 0 0 0 0 0 1 1 1 1 1 1 1;..
0 0 0 0 0 0 0 1 1 1 1 1 1 1 1;..
0 0 0 0 0 0 1 1 1 1 1 1 1 1 1;..
0 0 0 0 0 1 1 1 1 1 1 1 1 1 1;..
0 0 0 0 1 1 1 1 1 1 1 1 1 1 1;..
0 0 0 1 1 1 1 1 1 1 1 1 1 1 1;..
0 0 1 1 1 1 1 1 1 1 1 1 1 1 1;..
0 1 1 1 1 1 1 1 1 1 1 1 1 1 1;..
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);

// VSC 33xx Short Preemphasis Time Constant
param2=list("Src Short Preemph TC",..
["SRCPETCS2" "SRCPETCS1" "SRCPETCS0"], ["30 ps";"40 ps";"50 ps";"100 ps";"200 ps";"300 ps";"400 ps";"500 ps"],..
[0 0 0;..
0 0 1;..
0 1 0;..
0 1 1;..
1 0 0;..
1 0 1;..
1 1 0;..
1 1 1]);

// VSC 33xx Long Preemphasis Time Constant
param3=list("Src Long Preemph TC",..
["SRCPETCL2" "SRCPETCL1" "SRCPETCL0"], ["500 ps";"600 ps";"700 ps";"800 ps";"900 ps";"1000 ps";"1200 ps";"1500 ps"],..
[0 0 0;..
0 0 1;..
0 1 0;..
0 1 1;..
1 0 0;..
1 0 1;..
1 1 0;..
1 1 1]);

// VSC 33xx Short Preemphasis Level
param4=list("Src Short Preemph Lvl",..
["SRCPELS3" "SRCPELS2" "SRCPELS1" "SRCPELS0"], ["0.0dB";"1.0dB";"1.5dB";"2.0dB";"2.5dB";"3.0dB";"3.5dB";"4.0dB";"4.5dB";"4.8dB";"5.0dB";"5.3dB";"5.5dB";"5.8dB";"6.0dB";"6.3dB"],..
[1 1 1 1;..
1 1 1 0;..
1 1 0 1;..
1 1 0 0;..
1 0 1 1;..
1 0 1 0;..
1 0 0 1;..
1 0 0 0;..
0 1 1 1;..
0 1 1 0;..
0 1 0 1;..
0 1 0 0;..
0 0 1 1;..
0 0 1 0;..
0 0 0 1;..
0 0 0 0]);

// VSC 33xx Long Preemphasis Level
param5=list("Src Long Preemph Lvl",..
["SRCPELL3" "SRCPELL2" "SRCPELL1" "SRCPELL0"], ["0.0dB";"1.0dB";"1.5dB";"2.0dB";"2.5dB";"3.0dB";"3.5dB";"4.0dB";"4.5dB";"4.8dB";"5.0dB";"5.3dB";"5.5dB";"5.8dB";"6.0dB";"6.3dB"],..
[1 1 1 1;..
1 1 1 0;..
1 1 0 1;..
1 1 0 0;..
1 0 1 1;..
1 0 1 0;..
1 0 0 1;..
1 0 0 0;..
0 1 1 1;..
0 1 1 0;..
0 1 0 1;..
0 1 0 0;..
0 0 1 1;..
0 0 1 0;..
0 0 0 1;..
0 0 0 0]);

                                    // Altera S4GX Receiver Parameters
//S4GX RX EQ Gain  
param6=list("S4Rx EQ Gain",..
["S4RXEQGAIN"],..
["Bypass";"Low 0";"Low 1";"Low 2";"Low 3";"Low 4";"Med 0";"Med 1";"Med 2";"Med 3";"Med 4";"High 0";"High 1";"High 2";"High 3";"High 4"],..
[0;..
1;..
2;..
3;..
4;..
5;..
6;..
7;..
8;..
9;..
10;..
11;..
12;..
13;..
14;..
15]);

//S4GX RX DC Gain  
param7=list("S4Rx DC Gain",..
["S4RXDCGAIN"],..
["0 dB";"3 dB";"6 dB";"9 dB";"12 dB"],..
[0;..
1;..
2;..
3;..
4]);


param8=list("S4Rx Term",..
["S4RXTERM"],..
["150Ohm(Default)";"120Ohm";"100Ohm";"85Ohm";"External(Open Drain)"],..
[0;..
1;..
2;..
3;..
4]);

param=list(param1, param2, param3, param4, param5, param6, param7, param8);


/////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////Main Routine////////////////////////////////////

sweepplan=[];                 // Sweep plan
cmdlinestr=emptystr();        // HSpice command line string.
olddir=emptystr();             // Original directory path
results=emptystr();
fsource = emptystr();                           // Filename of HSpice source file
fparams = emptystr();                           // Filename of the parameters includes
foutput = emptystr();                           // Filename of the simulation CSFD file
dialogstr=emptystr();                           // Temporary string for storing dialog information
hyst=0;                                         // Hysteresis
dj=0;                                           // Dj to be convolved with results
tUIin=0;                                          // Unit Interval for all measurements
waveformstr=emptystr();                         // Waveform to be analyzed
fresults = "results";                           // Define results filename


///////////////////
// Setup files/directories
///////////////////
fsource=tk_getfile("*.sp", Title="Please choose input source file");                                                // Source file
if fsource==emptystr() then
  buttondialog("Invalid file selection. Script aborted", "Abort");
  abort;
end

fparams=tk_savefile("*.inc", strsubst(fileparts(fsource, "path"),"\","/"), Title="Please choose parameters source file");        // Parameters file
if fparams==emptystr() then
  buttondialog("Invalid file selection. Script aborted", "Abort");
  abort;
end

if length(fileparts(fparams, "extension"))==0 then
   fparams=strcat([fparams ".inc"]);
end  

foutput=strcat([fileparts(fsource, "path"), fileparts(fsource, "fname") ".tr0"]);                              // Set output file. Assume same base filename as the source.

//Create simulation command line  
cmdlinestr="hspice -i "  + strsubst(fsource,"/","\");

//Set new directory name for Hspice simulation
olddir=getcwd();
chdir(fileparts(fsource, "path"));

////////////////////
// Waveform Info
///////////////////
dialogstr=x_mdialog(['Enter waveform parameters:'], ['Waveform Name';'Hysteresis(volts)'; 'Dj (ps)'; 'Unit Interval (ps)'],['V(out_p,out_n)';'1e-2';'0';'125']);
if length(dialogstr)==0 then
  buttondialog("Invalid parameters selection. Script aborted", "Abort");
  chdir(olddir);
  abort;
end
waveformstr=dialogstr(1);
hyst=evstr(dialogstr(2));
dj=evstr(dialogstr(3))*1e-12;
tUIin=evstr(dialogstr(4))*1e-12;



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
    buttondialog("At least one parameter must be selected", "Ok");
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
          buttondialog("Invalid selection. Please select an entry from the list. Script aborted", "Abort");
          chdir(olddir);
          abort;
      elseif (choice == length(paramstring)) then
          buttondialog("Invalid selection. Please do not select last entry from the list. Script aborted", "Abort");
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
          buttondialog("Invalid selection. Please select an entry from the list. Script aborted", "Abort");
          chdir(olddir);
          abort;
      elseif (choice < rangestartidx ) then
          buttondialog("Invalid selection. Please select an entry that follows the range starting entry. Script aborted", "Abort");
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


for a=1:numofsweeps,
  
   fparamshandle=mopen(fparams, "w");                                                             // Create/overwrite parameters include file
  
   mfprintf(fparamshandle, ".OPTION CSDF=2\n");                                                   // Enable CSDF output mode in HSpice
                           
   for k=1:numofparams-1,                                                                         // Write the parameters
    num=sweepplan(k*2-1, a);                                                                      // Get the number of the parameter
    val=sweepplan(k*2, a);                                                                        // Get the value of the parameter set
    
    for b=1:size(param(num)(2),2)               // For each parameter string
        mfprintf(fparamshandle, ".PARAM %s=%d\n", param(num)(2)(b), param(num)(4)(val, b));       // concatenate value and parameter into the file
   end
  
   end
   
   mclose(fparamshandle);                                                                         //Close parameters include file

   currenttime=getdate();
   printf("\n****Starting simulation for iteration %d of %d at %0.2d:%0.2d:%0.2d\n", a, numofsweeps, currenttime(7), currenttime(8), currenttime(9));
   
  if unix(cmdlinestr) ~= 0 then                                          // Run simulation
     buttondialog("HSpice simulation Failed. Script aborted", "Abort");
     chdir(olddir);
      abort;
  end
       
  //Extract waveform data from output waveform
  [t, D, Desc]=extract_from_CSDF(foutput);                              // Get data from simulation
  
   descstridx=grep(Desc, convstr(waveformstr));
   if length(descstridx)==0 then
       buttondialog("Data extraction Failed. Invalid waveform name. Script aborted", "Abort");
       chdir(olddir);
      abort;
  end
 [tUI, eh, ew] = eye_measure(t, D(:,descstridx-1), hyst, Dj, tUIin); // Compute eye parameters

  // Log eye parameters
  results=cat(2, results, [sweepplan(:, a); tUI ; eh ; ew]);
    
  //Post results for simulation
  printf("\n*Measured bit-period: %0.2fps", tUI*1e12);
  printf("\n*Measured Eye Height: %0.3fV", eh);
  printf("\n*Measured Eye Width: %0.2fps\n", ew*1e12 );
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

mfprintf(fresultshndl, "|-----");
for a=1:numofparams-1,
  mfprintf(fresultshndl, "|------------------------------");
end  
mfprintf(fresultshndl, "|------------------------------|\n|     ");
for a=1:numofparams-1,
    mfprintf(fresultshndl, "|           Param%d             ", a);
end  
mfprintf(fresultshndl, "|                              |\n|  #  ");

for a=1:numofparams-1,
  mfprintf(fresultshndl, "|        Name         |  Value "); 
end  

mfprintf(fresultshndl, "|   tUI    |   EH   |    EW    |\n|-----");
for a=1:numofparams-1,
  mfprintf(fresultshndl, "|------------------------------");
end  
mfprintf(fresultshndl, "|------------------------------|\n");


//Print Body
for a=1:numofsweeps,
    mfprintf(fresultshndl, "|%3d  |", a);
    for b=1:numofparams-1
      mfprintf(fresultshndl, "%20s | %6s |", param(results((b*2)-1,a))(1), param(results((b*2)-1,a))(3)(results((b*2),a)));
    end
    mfprintf(fresultshndl, " %0.2fps | %0.3fV | %0.2fps |\n", results((numofparams-1)*2+1,a)*1e12, results((numofparams-1)*2+2,a), results((numofparams-1)*2+3,a)*1e12);
end

mfprintf(fresultshndl, "|-----");
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
plot2d3(linspace(1,numofsweeps,numofsweeps),results((numofparams-1)*2+3,:)*1e12, style=2);
xtitle("Eye Width","Sim #", "Eye opening (ps)");
//a=get("current_axes");
//a.x_ticks.locations = linspace(1,numofsweeps,numofsweeps)';
xgrid(4);
subplot(2,1,2);
plot2d3(linspace(1,numofsweeps,numofsweeps),results((numofparams-1)*2+2,:), style=2);
//a=get("current_axes");
//a.x_ticks.locations = linspace(1,numofsweeps,numofsweeps)';
xtitle("Eye Height","Sim #", "Eye opening (V)");
xgrid(4);
drawnow; 
//Save results to a file
xsave(strcat([fresults '.scg']), 0)






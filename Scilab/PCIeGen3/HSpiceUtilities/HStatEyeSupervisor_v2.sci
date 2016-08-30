// HSpiceRF StatEye automation supervisor script 
//
// (c)2009  L. Rayzman
// Created :      03/25/2009
// Last Modified: 03/25/2009
//                04/03/2009 - Added option for time-domain pulse response
//                08/15/2009 - Added support for DFE. Moved CTLE implementation to 
//                             Scilab
//                10/25/2009 - Hardwired the StatEye source file name
//
// TODO: 
// 


clear;		
getf("HSPiceUtilities.sci");                       // Include HSpice utilities

//////////////////////////////////////SPECIFY//////////////////////////////////////

//PCISIG CTLE
//param1=list("RX CTLE DCGain",..
//["GDC_CTLE"],..
//["-3dB";"-4dB"; "-5dB";"-6dB"; "-7dB"; "-8dB"; "-9dB"; "-10dB"; "-11dB"; "-12dB"; "-13dB"],..
//[-3;..
//-4;..
//-5;..
//-6;..
//-7;..
//-8;..
//-9;..
//-10;..
//-11;..
//-12;..
//-13], 1);

//param2=list("RX CTLE Pole1 Freq",..
//["POLE1_CTLE"],..
//["2.0GHz";"2.5GHz"],..
//[2.0e9*2*%pi;..
//2.5e9*2*%pi], 1);


param1=list("S4GX CTLE Setting",..
["s4gx"],..
["0,Bp";"0,L0"; "0,L1";"0,L2"; "0,L3"; "0,L4"; "0,M0"; "0,M1"; "0,M2"; "0,M3"; "0,M4"; "0,H0"; "0,H1"; "0,H2";"0,H3";"0,H4";..
"1,Bp";"1,L0"; "1,L1";"1,L2"; "1,L3"; "1,L4"; "1,M0"; "1,M1"; "1,M2"; "1,M3"; "1,M4"; "1,H0"; "1,H1"; "1,H2";"1,H3";"1,H4";..
"2,Bp";"2,L0"; "2,L1";"2,L2"; "2,L3"; "2,L4"; "2,M0"; "2,M1"; "2,M2"; "2,M3"; "2,M4"; "2,H0"; "2,H1"; "2,H2";"2,H3";"2,H4";..
"3,Bp";"3,L0"; "3,L1";"3,L2"; "3,L3"; "3,L4"; "3,M0"; "3,M1"; "3,M2"; "3,M3"; "3,M4"; "3,H0"; "3,H1"; "3,H2";"3,H3";"3,H4";..
"4,Bp";"4,L0"; "4,L1";"4,L2"; "4,L3"; "4,L4"; "4,M0"; "4,M1"; "4,M2"; "4,M3"; "4,M4"; "4,H0"; "4,H1"; "4,H2";"4,H3";"4,H4";],..
["S4GX_EQT_0";..
"S4GX_EQT_1";..
"S4GX_EQT_2";..
"S4GX_EQT_3";..
"S4GX_EQT_4";..
"S4GX_EQT_5";..
"S4GX_EQT_6";..
"S4GX_EQT_7";..
"S4GX_EQT_8";..
"S4GX_EQT_9";..
"S4GX_EQT_10";..
"S4GX_EQT_11";..
"S4GX_EQT_12";..
"S4GX_EQT_13";..
"S4GX_EQT_14";..
"S4GX_EQT_15";..
"S4GX_EQT_16";..
"S4GX_EQT_17";..
"S4GX_EQT_18";..
"S4GX_EQT_19";..
"S4GX_EQT_20";..
"S4GX_EQT_21";..
"S4GX_EQT_22";..
"S4GX_EQT_23";..
"S4GX_EQT_24";..
"S4GX_EQT_25";..
"S4GX_EQT_26";..
"S4GX_EQT_27";..
"S4GX_EQT_28";..
"S4GX_EQT_29";..
"S4GX_EQT_30";..
"S4GX_EQT_31";..
"S4GX_EQT_32";..
"S4GX_EQT_33";..
"S4GX_EQT_34";..
"S4GX_EQT_35";..
"S4GX_EQT_36";..
"S4GX_EQT_37";..
"S4GX_EQT_38";..
"S4GX_EQT_39";..
"S4GX_EQT_40";..
"S4GX_EQT_41";..
"S4GX_EQT_42";..
"S4GX_EQT_43";..
"S4GX_EQT_44";..
"S4GX_EQT_45";..
"S4GX_EQT_46";..
"S4GX_EQT_47";..
"S4GX_EQT_48";..
"S4GX_EQT_49";..
"S4GX_EQT_50";..
"S4GX_EQT_51";..
"S4GX_EQT_52";..
"S4GX_EQT_53";..
"S4GX_EQT_54";..
"S4GX_EQT_55";..
"S4GX_EQT_56";..
"S4GX_EQT_57";..
"S4GX_EQT_58";..
"S4GX_EQT_59";..
"S4GX_EQT_60";..
"S4GX_EQT_61";..
"S4GX_EQT_62";..
"S4GX_EQT_63";..
"S4GX_EQT_64";..
"S4GX_EQT_65";..
"S4GX_EQT_66";..
"S4GX_EQT_67";..
"S4GX_EQT_68";..
"S4GX_EQT_69";..
"S4GX_EQT_70";..
"S4GX_EQT_71";..
"S4GX_EQT_72";..
"S4GX_EQT_73";..
"S4GX_EQT_74";..
"S4GX_EQT_75";..
"S4GX_EQT_76";..
"S4GX_EQT_77";..
"S4GX_EQT_78";..
"S4GX_EQT_79"],2);

param2=list("M21482 CTLE Setting",..
["m21482"],..
["00h";"20h"; "11h"; "21h"; "31h"; "A1h"; "29h"; "33h"; "37h"; "45h"; "59h"; "5Eh"; "6Eh"; "7Fh"; "FAh"; "FFh"],..
["M21xxx_EQT_0";..
"M21xxx_EQT_1";..
"M21xxx_EQT_2";..
"M21xxx_EQT_3";..
"M21xxx_EQT_4";..
"M21xxx_EQT_5";..
"M21xxx_EQT_6";..
"M21xxx_EQT_7";..
"M21xxx_EQT_8";..
"M21xxx_EQT_9";..
"M21xxx_EQT_10";
"M21xxx_EQT_11";..
"M21xxx_EQT_12";..
"M21xxx_EQT_13";..
"M21xxx_EQT_14";..
"M21xxx_EQT_15"],2);

param=list(param1, param2);





/////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////Main Routine////////////////////////////////////

sweepplan=[];                                   // Sweep plan
cmdlinestr=emptystr();                          // HSpice command line string.
cnvcmdlinestr=emptystr();                       // Converter command line string.
olddir=emptystr();                              // Original directory path
results=emptystr();                             // Measured results output
//fsource = emptystr();                         // Filename of HSpice source file

fsource = "C:/LeCroy/Development/Characterization/PCIEG3/General/StatEyeGenericTD/GenericTD.sp";                         

fparams = emptystr();                           // Filename of the parameters includes
ftrdata = emptystr();                           // Filename(s) of the pulse response *.tr* file(s)
ffreqdata = emptystr();                         // Filename of time-domain include file
fcnvpar=emptystr();                             // Converter instructions file
dialogstr=emptystr();                           // Temporary string for storing dialog information
fftable=[];                                     // Filename of the linear filter frequency table file 

Rj=0;                                           // Source Rj
tUIin=0;                                        // Unit Interval for all measurements
waveformstr=emptystr();                         // Waveform to be analyzed
fresults = "results";                           // Define results filename
GNUPLOT_EN=%t;                                  // Enable GNUPLOT of eye
LINFLT_EN=%t;                                   // Enable linear filter frequency tables
DFE_EN=%t;                                      // Enable DFE algorithm

coeffs_in=[0.2 -0.2 64 1;...                    // DFE coefficients specification
0.1 -0.1 64 1;...
0.05 -0.05 64 1];

Dfe_alg_type=1;                                 // Dfe algorithm type
                                                // 1=mid-UI center optimized
                                                // 2=full-UI minimal error


tpulse=[];                                      // Time vector points of PWL file
Dpulse=[];                                      // Data vector points of PWL file
t=[];                                           // Processed time vector points    
D=[];                                           // Processed Data vector points





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

//if (version(1)==5) & (version(2) >= 1) then                                                                           // StatEye Source file
//    fsource=uigetfile("*.sp", "",  "Please choose StatEye source file");                                                
//else
//   fsource=tk_getfile("*.sp", Title="Please choose StatEye source file");                                              
//end

//if fsource==emptystr() then
//  if (version(1)==5) & (version(2) >= 1) then                                                                           // StatEye Source file
//    messagebox("Invalid file selection. Script aborted", "","error","Abort");      
//  else
//    buttondialog("Invalid file selection. Script aborted", "Abort");
//  end
//  abort;
//end



if (version(1)==5) & (version(2) >= 1) then                                                                           // tr* file(s)
//    ftrdata=uigetfile("*.tr*", strsubst(fileparts(fsource, "path"),"\","/"), "Please choose pulse response *.tr* file(s)", %t);          // Use with StatEye source dialog                                     
      ftrdata=uigetfile("*.tr*", , "Please choose pulse response *.tr* file(s)", %t);
else
//   ftrdata=tk_getfile("*.tr*", strsubst(fileparts(fsource, "path"),"\","/"), Title="Please choose pulse response *.tr* file(s)", multip="1");   // Use with StatEye source dialog                                                 
     ftrdata=tk_getfile("*.tr*", , Title="Please choose pulse response *.tr* file(s)", multip="1");
end

if ftrdata==emptystr() then
  if (version(1)==5) & (version(2) >= 1) then   
    messagebox("Invalid file selection. Script aborted", "","error","Abort");      
   else
     buttondialog("Invalid file selection. Script aborted", "Abort");
   end
  abort;
end

//fparams=tk_savefile("*.inc", strsubst(fileparts(fsource, "path"),"\","/"), Title="Please choose parameters source file");        // (REMOVED) Parameters file
//if fparams==emptystr() then
//   if (version(1)==5) & (version(2) >= 1) then      
//    messagebox("Invalid file selection. Script aborted", "","error","Abort");      
//    else
//    buttondialog("Invalid file selection. Script aborted", "Abort");
//   end
//  abort;
//end

//if length(fileparts(fparams, "extension"))==0 then
//   fparams=strcat([fparams ".inc"]);
//end  

fparams=strsubst(fileparts(fsource, "path"),"\","/")+"include/automation.inc";


//ffreqdata=tk_savefile("*.inc", strsubst(fileparts(fsource, "path"),"\","/"), Title="Please choose converted pulse response file");  //(REMOVED) Touchstone file
//    if ffreqdata==emptystr() then
//     if (version(1)==5) & (version(2) >= 1) then      
//         messagebox("Invalid file selection. Script aborted", "","error","Abort");  
//     else
//        buttondialog("Invalid file selection. Script aborted", "Abort");
//     end
//    abort;
//  end

//  if length(fileparts(ffreqdata, "extension"))==0 then
//     ffreqdata=strcat([ffreqdata ".inc"]);
//  end 
ffreqdata=strsubst(fileparts(fsource, "path"),"\","/")+"include/impulse.inc";




////////////////////
// Dialogs
///////////////////
dialogstr=x_mdialog(['Enter waveform parameters:'], ['Waveform Name'; 'Source Rj (ps)'; 'Unit Interval (ps)'],['v(rxbump_p,rxbump_n)';'0';'125']);
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
Rj=evstr(dialogstr(2));
tUIin=evstr(dialogstr(3))*1e-12;

l1=list('Display Eyes',1,['Yes','No']);
l2=list('Enable Linear Filter', 1,['Yes', 'No']);
l3=list('Enable DFE',1,['Yes','No']);
dialogstr=x_choices('Enable Features',list(l1,l2,l3));
if length(dialogstr)==0 then
  
  if (version(1)==5) & (version(2) >= 1) then      
     messagebox("Invalid parameters selection. Script aborted", "","error","Abort"); 
  else
    buttondialog("Invalid parameters selection. Script aborted", "Abort");
  end
  chdir(olddir);
  abort;
end
clear l1;
clear l2;

if dialogstr(1)==2 then
  GNUPLOT_EN=%f;
end 
if dialogstr(2)==2 then
  LINFLT_EN=%f;
end 
if dialogstr(3)==2 then
  DFE_EN=%f;
end 


if DFE_EN==%t then
  dialogstr=x_choices('DFE Algorithm',list(list('Algorithm Type',1,['Minimize Center Error','Minimize RMS error ']), list('Change Default Coefficients',2,['Yes','No'])));
  if length(dialogstr)==0 then
    if (version(1)==5) & (version(2) >= 1) then      
     messagebox("Invalid parameters selection. Script aborted", "","error","Abort"); 
    else
      buttondialog("Invalid parameters selection. Script aborted", "Abort");
    end
  chdir(olddir);
  abort;
  end
  Dfe_alg_type=dialogstr(1);
  
  if dialogstr(2)==1 then
     coeffs_in=x_matrix("Specify new DFE coefficients", coeffs_in);
    if length(coeffs_in)==0 then
      if (version(1)==5) & (version(2) >= 1) then      
       messagebox("Invalid parameters selection. Script aborted", "","error","Abort"); 
      else
        buttondialog("Invalid parameters selection. Script aborted", "Abort");
      end
      chdir(olddir);
      abort;
    end
  end
end  



//Set new directory name for Hspice simulation
olddir=getcwd();
chdir(fileparts(fsource, "path"));





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
      if (param(choice)(5) == 2) & (LINFLT_EN==%t) then
        if fftable~=[] then
          if (version(1)==5) & (version(2) >= 1) then      
              messagebox("Only one Linear Filter parameter is allowed", "error", "Abort");
            else
              buttondialog("Only one Linear Filter parameter is allowed", "Abort");
          end
          chdir(olddir);
          abort;
        else
            fftable=olddir+"\"+param(choice)(2)+".ft";
            swpparamslist=cat(2, swpparamslist, choice);
            numofparams=numofparams+1;
        end
      else  
        swpparamslist=cat(2, swpparamslist, choice);
        numofparams=numofparams+1;
      end
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
// Read Linear Filter Table
///////////////////

if LINFLT_EN==%t then
   load(fftable, 'FTable');
end  
         


                                                                        //  Load linear filter frequency table if necessary


///////////////////
// Execute simulation
///////////////////

absstarttime=getdate();

numoffiles=size(ftrdata,1);

for f=1:numoffiles,                                                                                 //For each tr* pulse response file
    currenttime=getdate();
    printf("\n****Starting conversion of Pulse Response for file %d of %d at %0.2d:%0.2d:%0.2d\n", f, numoffiles, currenttime(7), currenttime(8), currenttime(9));
    
       [tpulse,Dpulse]=read_pwl(ftrdata(f), waveformstr);                                                           // Convert time-domain to PWL file
  
  for a=1:numofsweeps,
     fparamshandle=mopen(fparams, "w");                                                             // Create/overwrite parameters include file
  
     for k=1:numofparams-1,                                                                         // Write the parameters
      num=sweepplan(k*2-1, a);                                                                      // Get the number of the parameter
      val=sweepplan(k*2, a);                                                                        // Get the value of the parameter set
    
      for b=1:size(param(num)(2),2)                                                                 // For each parameter string
              mfprintf(fparamshandle, ".PARAM RJ_SRC=%fp\n", Rj);
          if param(num)(5) == 1 then  
              mfprintf(fparamshandle, ".PARAM %s=%f\n", param(num)(2)(b), param(num)(4)(val, b));   // concatenate value and parameter into the file
              t=tpulse;
              D=Dpulse;
          elseif (param(num)(5) == 2) & (LINFLT_EN==%t) then

          
               [t, D] = FT_pr(tpulse, Dpulse,  tUIin, FTable(val)(:,1), FTable(val)(:,2));          // Apply linear filter

          else
              t=tpulse;
              D=Dpulse;
          end
       
          if DFE_EN==%t then
                [t, D, dfe_opt_coeff, dfe_pr_err] = DFE_pr(t, D, coeffs_in, tUIin, Dfe_alg_type);              // DFE 
          end
      end
     end
   
     mclose(fparamshandle);                                                                         //Close parameters include file
     
 
     currenttime=getdate();
     printf("\n****Starting simulation for iteration %d of %d at %0.2d:%0.2d:%0.2d\n", (f-1)*numofsweeps+a, numoffiles*numofsweeps, currenttime(7), currenttime(8), currenttime(9));

     write_pwl(t, D, ffreqdata);                                                            // Write time-domain data to Hspice PWL file
     t=[];
     D=[];
     
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
     
     if GNUPLOT_EN==%t then
       cmdlinestr="taskkill /IM wgnuplot.exe";                                                         // Close existing gnuplot
       unix(cmdlinestr);  
     end       
  
     if GNUPLOT_EN==%t then
       cmdlinestr="start /wait /min xcopy /s /Y " + fileparts(fsource, "fname") + ".printSte0\* GnuData\";     //Move output to directory
       unix(cmdlinestr);
     end       
     
     if GNUPLOT_EN==%t then
       cmdlinestr="start wgnuplot display";                                                                    //Plot eye
       unix(cmdlinestr);
     end    
     
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
    if DFE_EN==%t then
      for i=1:length(dfe_opt_coeff)
        printf("\n*Optimized value for DFE coefficient %d: %0.2f", i, dfe_opt_coeff(i));
    end   
        printf("\n*Pulse response residual error post DFE: %0.6f\n", dfe_pr_err);
    end
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






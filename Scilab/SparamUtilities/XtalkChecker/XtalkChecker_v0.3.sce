//==========================   Xtalk Checker ===========================
// 
// General xtalk checker
//
// (c)2015  L. Rayzman
//
//
// Created      : 
// Last Update  : 10/13/15 -- Added support for renormalization
//
//        
// TODO:  Currently a simple test case for point-to-point. Some ideas for future
//        - Extend with some sort of simulation descriptor tool
//        - 
//   
// ====================================================================
// ====================================================================


clear;	

stacksize(200*1024*1024);

exec("XtalkChecker_Utilities_v0.7.sci");          // Supporting functions/includes


////////////////////////////////// SPECIFY   /////////////////////////////////

max_freq_for_FOM=10e9;                          // Maximum frequency boundary for computing the FOM      


xtalk_max_len=1;                                // Maximum number of xtalk elements to be saved

trf_edge=100e-12;                               // Filter edge rate

spZ0_renorm=50;                                 // Set environment impedance

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
                                                //
                                                // THINGS FOR TOUCHSTONE FILES
                                                //                                                
frefsparam = emptystr();                        // Filename of inputfile


                                                //
                                                // THINGS FOR SPARAM DATA
                                                //                      
spreffreqs=[];                                  // Inputfile frequency points vector
sprefdata=[];                                   // Inputfile S-param matrix data
spcomments=[];                                  // Inputfile comments
spZ0=50;                                        // S-param impedance

numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

                                                //
                                                // THINGS FOR NET-PORT MAPPING
                                                //
                                                // Net-to-port map
netmap=struct('net_name',emptystr(), ...       //   - Name of net
                'port_num', 0,...               //   - number of ports on the net
                'pin_array',emptystr(),...      //   - pin number(s) (Ux_PinY)
                'port_array',[]);               //   - Port number(s) 
netmap_cnt=0;                                   //  Count of netmap

                                                //
                                                // THINGS FOR PROGRESS COUNTER
                                                //
progcntr_arr=[];                                // Array used to compute the index of the marks                                                
progcntr_iter_cnt=0;                            // Iteration count
progcntr_iter_total=0;                          // Iteration total (computed from all the stats)

                                                //
                                                // THINGS FOR RESULTS LOG
                                                //                                                

 
xtalk_struct=struct('xtalk_net',emptystr(1,xtalk_max_len),...    // Xtalk information
                    'xtalk_pin',emptystr(1,xtalk_max_len),...
                    'xtalk_port',zeros(1,xtalk_max_len),...
                    'xtalk_fom',zeros(1,xtalk_max_len));

results_log=struct('net_name', emptystr(),...                   // results log
                   'port_num',0,...
                   'pin_array',emptystr(),...
                   'port_array',[],...
                   'xtalk_array', xtalk_struct);
                   
                   
                                                //
                                                // THINGS FOR OUTPUT FILE
                                                //                        
foutfile_handle=0;                              // Output file handle
foutfile_err=0;                                 // Output file error on open
foutfilename=emptystr();                        // Output file name

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


////////////////////////////// READ TOUCHSTONE   //////////////////////////////
///////////////////
// Get Scilab Version
///////////////////
version_str=getversion();
version_str=tokens(version_str,'-');
version_str=tokens(version_str(2),'.');
version(1)=msscanf(version_str(1), '%d');
version(2)=msscanf(version_str(2), '%d');


if (version(1)<5) then
  error("Invalid Scilab version. Version 5.5 or greater is required");
  if getscilabmode()=="NW" then sleep(2000); quit; end;
elseif (version(2) < 5) then
  error("Invalid Scilab version. Version 5.5 or greater is required");
  if getscilabmode()=="NW" then sleep(2000); quit; end;
end    


///////////////////
// Post basic instructions
///////////////////

messagebox(["Basic instructions for using this utility" " 1. Import s-parameter" " 2. Select the number of crosstalk terms to collect" ...
            " 3. Select the edge-rate for the frequency domain filter" " 4.  Select port impedance"], "modal");

///////////////////
// Get number of xtalk terms 
// to be reported
///////////////////

temp = x_mdialog("Please enter parameters", "Maximum number of xtalk terms >0:", string(xtalk_max_len));

if (temp==[]) | (temp=="0") then
    messagebox("Script aborted", "","error","Abort");      
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end; 
end

xtalk_max_len = evstr(temp(1));

disp(strcat(["Info: Selected reporting of " string(xtalk_max_len) " xtalk elements "]));

///////////////////
// Get the edge rate
///////////////////

temp = x_mdialog("Please enter parameter", "Apply gaussian edge-rate filter 10-90% ps:", string(trf_edge/1e-12));
trf_edge = evstr(temp(1))*1e-12;

if (temp==[]) | (trf_edge<0) | (trf_edge > 1000e-12) then
    messagebox("Edge rate outside of range. Script aborted", "","error","Abort");      
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end; 
end

disp(strcat(["Info: Applying " string(trf_edge/1e-12) "ps edge rate filter"]));


///////////////////
// Get nominal environment impedances
///////////////////

temp = x_mdialog("Please enter parameter", "Environment (port) resistance :", string(spZ0));
spZ0_renorm = evstr(temp(1));

if (temp==[]) | (spZ0_renorm<0) then
    messagebox("Environment resistance outside of range. Script aborted", "","error","Abort");      
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end; 
end

disp(strcat(["Info: Using environment resistance of " string(spZ0_renorm) " ohms"]));

///////////////////
// Setup files/directories
// Read touchstone files
// Get user input
///////////////////

//
// Read input file
//
//
frefsparam=uigetfile("*.s*p", "",  "Please choose S-parameters file");                                                

if frefsparam==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;      
end

disp(strcat(["Info: Begin loading touchstone file " frefsparam]));

[spreffreqs,sprefdata,spZ0,spcomments] = sptlbx_readtchstn(frefsparam);

disp("Info: Finished loading touchstone file");


numofports=size(sprefdata,1);                                               //Find number of ports

if numofports < 4 then
    messagebox("Only 4-port or larger S-parameters are allowed. Script aborted", "","error","Abort");      
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;  
end

if modulo(numofports,2) <> 0 then
    messagebox("Only even port-count S-parameters are allowed. Script aborted", "","error","Abort");      
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;  
end

numofreqs=size(sprefdata,3);                                                //Find number of frequency points


///////////////////
// Display some basic stats
///////////////////

freqstatsstr="Info: Freq points: ";
freqscalar=1;

select find([spreffreqs(1)/1e12 spreffreqs(1)/1e9 spreffreqs(1)/1e6 spreffreqs(1)/1e3 spreffreqs(1)] >= 1, 1)
case 1 then      //THz :)
    sHzPrefix= "T";

    freqscalar=1e12;
case 2 then     //GHz
    sHzPrefix= "G";
    freqscalar=1e9;
case 3 then     //MHz
     sHzPrefix= "M";
     freqscalar=1e6;                
case 4 then    // KHz
     sHzPrefix= "K";
     freqscalar=1e3;     
case 5 then   // Hz                                             
     sHzPrefix="";
     freqscalar=1;          
else
     sHzPrefix="";
     freqscalar=1;        
end

freqstatsstr=strcat([freqstatsstr  msprintf("%0.2f", spreffreqs(1)/freqscalar) sHzPrefix "Hz to "]);

select find([spreffreqs($)/1e12 spreffreqs($)/1e9 spreffreqs($)/1e6 spreffreqs($)/1e3 spreffreqs($)] >= 1, 1)
case 1 then      //THz :)
    sHzPrefix= "T";
    freqscalar=1e12;
case 2 then     //GHz
    sHzPrefix= "G";
    freqscalar=1e9;
case 3 then     //MHz
     sHzPrefix= "M";
     freqscalar=1e6;                
case 4 then    // KHz
     sHzPrefix= "K";
     freqscalar=1e3;       
case 5 then   // Hz                                             
     sHzPrefix="";
     freqscalar=1;        
else
     sHzPrefix="";
     freqscalar=1;        
end

freqstatsstr=strcat([freqstatsstr msprintf("%0.2f", spreffreqs($)/freqscalar) sHzPrefix "Hz; min freq delta: "]);

select find([min(diff(spreffreqs))/1e12 min(diff(spreffreqs))/1e9 min(diff(spreffreqs))/1e6 min(diff(spreffreqs))/1e3 min(diff(spreffreqs))] >= 1, 1)
case 1 then      //THz :)
    sHzPrefix= "T";
    freqscalar=1e12;
case 2 then     //GHz
    sHzPrefix= "G";
    freqscalar=1e9;
case 3 then     //MHz
     sHzPrefix= "M";
     freqscalar=1e6;                
case 4 then    // KHz
     sHzPrefix= "K";
     freqscalar=1e3;       
case 5 then   // Hz                                             
     sHzPrefix="";
     freqscalar=1;        
else
     sHzPrefix="";
     freqscalar=1;        
end


freqstatsstr=strcat([freqstatsstr msprintf("%0.2f", min(diff(spreffreqs))/freqscalar) sHzPrefix "Hz"]);

disp(freqstatsstr);

clear freqstatsstr;
clear freqscalar;





///////////////////////////////////////////////////////////////////////////////
//////////////////////////// READ PORT MAPPING   //////////////////////////////

disp("Info: Begin mapping ports to nets");

netmap_empty=netmap;

netmap = PORT_ALIAS_EXTRCT_FORSIW(spcomments,numofports);

netmap_cnt=size(netmap,1);

// Check if unable to find any information from list and abort 
if and(netmap_empty==netmap)==%T then
    messagebox("Unable to read in port mapping information. Script aborted", "","error","Abort");
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;  
end

disp(strcat(["Info: Mapped " string(numofports) " ports to " string(netmap_cnt) " nets"]));

////////////////////////////////////////////////////////////////////////////////
////////////////////// RENORMALIZE PORT IMPEDANCE   ////////////////////////////


if spZ0_renorm <> spZ0  then
    disp(strcat(["Info: Begin renormalizing port resistance"]));
    sprefdata=SE_ZRENORM(sprefdata,spZ0_renorm, spZ0);
end


////////////////////////////////////////////////////////////////////////////////
//////////////////////////// COMPUTE XTALK   ///////////////////////////////////

//i-main(victim) net index
//j-index of main(victim) net port
//k-index of agressor net
//l-index of agressor port

//Apply transmitter edge filter compensation curve
IL_comp_curve=exp(-(spreffreqs.^2)*1/0.31*(trf_edge)^2);

//Compute the max frequency index for the FOM
max_freq_idx=sum(spreffreqs<=max_freq_for_FOM);

outstringtemp=emptystr();
outstringtemp_idx=0;


// Xtalk FOM temporary variables
Xtalk_FOM=0;                                             // Xtracted FOM number
Xtalk_FOM_Array=zeros(xtalk_max_len,1);                  // Temp FOM values array
Xtalk_agg_net_idx_Array=zeros(xtalk_max_len,1);          // Temp net index array associated with FOM array
Xtalk_agg_pin_idx_Array=zeros(xtalk_max_len,1);          // Temp port index associated with FOM array

// Other temp variables
results_log_xtalk_idx=0;                                 // Index of xtalk aggressors in each results log 


//Compute progress indicator
// Simply number of nets * number aggressors per net * number of ports per aggr
progcntr_iter_total=netmap_cnt*(netmap_cnt-1)*2;



// Compute the marks for progress bar
for i=1:19 
    progcntr_arr(i)=round(progcntr_iter_total*i*0.05);
end



disp("Info: Begin computing Xtalk FOM");

if progcntr_iter_total>=1000 then
    mprintf("        0");
end



// Compute total iteration count for progress display
// This is based on the 

for i=1:netmap_cnt
    // Go in each direction
    for j=1:netmap(i).port_num
       // Reset the FOM array 
       Xtalk_FOM_Array=zeros(xtalk_max_len,1);
        
      // Extract IL data for victim net pair
          // TODO THIS:
    
      // For each aggressor ports
      for k=1:netmap_cnt
          if i<>k then
              //For each port
              for l=1:netmap(k).port_num
                
                // Plot the progress bar
                if progcntr_iter_total>=1000 then
                    progcntr_iter_cnt=progcntr_iter_cnt+1;
                    if vectorfind(progcntr_arr,progcntr_iter_cnt)<>[] then
                         if vectorfind(progcntr_arr,progcntr_iter_cnt)==5 then   //25%
                            mprintf("25");              
                         elseif vectorfind(progcntr_arr,progcntr_iter_cnt)==10 then  //50%
                            mprintf("50");              
                         elseif vectorfind(progcntr_arr,progcntr_iter_cnt)==15 then  //75%
                            mprintf("75");
                         else
                            mprintf(".");
                         end
                     end 
                 end
             
    
                // Apply IL compensation
                // Compute the integrated crosstalk FOM up to max freq
                    Xtalk_FOM=sum(IL_comp_curve'.*abs(squeeze(sprefdata(netmap(i).port_array(j),netmap(k).port_array(l),:))));
             
                // If FOM in top three, then push out the minimum value
                  if Xtalk_FOM > min(Xtalk_FOM_Array) then
                    // If greater than minimum, find the (first) minimum value and swap with FOM
                           // Log the aggressor port indices
                      Xtalk_agg_net_idx_Array(find(Xtalk_FOM_Array<=min(Xtalk_FOM_Array),1))=k;
                      Xtalk_agg_pin_idx_Array(find(Xtalk_FOM_Array<=min(Xtalk_FOM_Array),1))=l;                   
                      Xtalk_FOM_Array(find(Xtalk_FOM_Array<=min(Xtalk_FOM_Array),1))=Xtalk_FOM;
                  end
               end
          end
       end
       
       
       // After done save results for each type
       // Note the net and pin_names for the aggressor
       results_log_xtalk_idx=0;       
       
       results_log(i).net_name=netmap(i).net_name;
       results_log(i).port_num=results_log(i).port_num+1;
       results_log(i).pin_array(results_log(i).port_num)=netmap(i).pin_array(j);
       results_log(i).port_array(results_log(i).port_num)=netmap(i).port_array(j);
       results_log(i).xtalk_array(j)=xtalk_struct;    // Initialization workaround
    

       for m=1:xtalk_max_len
           if Xtalk_FOM_Array(m)>0 then
               results_log_xtalk_idx=results_log_xtalk_idx+1;   
               results_log(i).xtalk_array(j).xtalk_net(results_log_xtalk_idx)= netmap(Xtalk_agg_net_idx_Array(m)).net_name;
               results_log(i).xtalk_array(j).xtalk_pin(results_log_xtalk_idx)= netmap(Xtalk_agg_net_idx_Array(m)).pin_array(Xtalk_agg_pin_idx_Array(m));
               results_log(i).xtalk_array(j).xtalk_port(results_log_xtalk_idx)=netmap(Xtalk_agg_net_idx_Array(m)).port_array(Xtalk_agg_pin_idx_Array(m));
               results_log(i).xtalk_array(j).xtalk_fom(results_log_xtalk_idx)= Xtalk_FOM_Array(m);
            end
       end
      

   end
end

if progcntr_iter_total>=1000 then
    mprintf("100");
end


////////////////////////////////////////////////////////////////////////////////
///////////////////////////// PRINT RESULT   ///////////////////////////////////


///////////////////
// Setup files/directories
// for output
///////////////////

foutfilename=uiputfile(["*.csv", "csv files"], ".csv",  "Please choose output .csv file");                                                

if foutfilename==emptystr() then
    messagebox("Invalid output file selection. Script aborted", "","error","Abort");
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;      
end

// Strip out and append the extension, as necessary
[fpath, ffname, fext]=fileparts(foutfilename);

if fext==emptystr() then
    foutfilename=strcat([foutfilename ".csv"]);
end

disp(strcat(["Info: Begin writing output file " foutfilename]));


///////////////////
// Write out the results log
///////////////////


// Open file
[foutfile_handle,foutfile_err]=mopen(foutfilename, 'wt');

if foutfile_err<>0 then
   error("Unable to open output file for write!");
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;      
end


// Temporary variables
outwriteline=emptystr();


// Write header
outwriteline="VICT_NET_NAME,VICT_PIN_NAME,VICT_PORT,AGGR_NET_NAME,AGGR_PIN_NAME,AGGR_PORT,AGGR_XTALK_FOM";
mfprintf(foutfile_handle, "%s\n",outwriteline);

// Write everything out
for i=1:size(results_log,1)   // for each net

      // if pin does not exist, do blank fields for pins and xtalks
      if results_log(i).port_num == 0  then
           outwriteline=strcat([results_log(i).net_name ",,,,"]);
           //Print line to file 
           mfprintf(foutfile_handle,"%s\n",outwriteline);
      else  //pin exists
           for j=1:results_log(i).port_num
                 //if no xtalk exists for pin, do blanks for xtalk field
                 if and(results_log(i).xtalk_array(j).xtalk_fom==zeros(1,xtalk_max_len)) then
                     outwriteline=strcat([results_log(i).net_name "," results_log(i).pin_array(j) "," string(results_log(i).port_array(j))  ",,,,,"]);
                   //Print line to file 
                   mfprintf(foutfile_handle,"%s\n",outwriteline);                     
                 else //xtalk exists
                     //for all non-zero xtalks write xtalk aggressor pin and FOM
                     for k=1:xtalk_max_len
                         if results_log(i).xtalk_array(j).xtalk_fom(k) > 0 then
                             outwriteline=strcat([results_log(i).net_name "," results_log(i).pin_array(j) "," string(results_log(i).port_array(j)) ","  ...
                                                  results_log(i).xtalk_array(j).xtalk_net(k) "," ... 
                                                  results_log(i).xtalk_array(j).xtalk_pin(k) "," ...
                                                  string(results_log(i).xtalk_array(j).xtalk_port(k)) "," ...                                                  
                                                  msprintf("%0.6e",results_log(i).xtalk_array(j).xtalk_fom(k))]);
                            //Print line to file 
                            mfprintf(foutfile_handle,"%s\n",outwriteline);                     
                         end
                     end
                 end
           end
      end
end


mclose(foutfile_handle);

disp(strcat(["Info: Successfully wrote the output file"]));

quit;




// ===================   Ideal Network S-param Generator ====================
// 
// Creates an s2p or s4p file with user-defined gain and linear group delay
// with ideal return los
//   
// (c)2016  L. Rayzman
//
// Created      : 01/14/2016
// Last Modified:  01/14/2016 - Initial versions
//  
//
//
//
// ====================================================================
// ====================================================================

//clear;	

stacksize(128*1024*1024);	

///////////////////////////////////////////////////////////////////////////////


foutsparam = emptystr();                        // Filename of S2p/s4p Output file
spoutfreqs=[];                                  // Output frequency points vector
spoutdata=[];                                   // Output S-param matrix data

numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

entries_choice=emptystr();                      // Text matrix that describes available entries to view
entry_idx=0;                                    //  

freqMax=20.0e9;                                // Minimum and maximum frequencies
freqMin=0;                                                   
freqNum=400;                                   // Number of frequency points

gain=1;                                        // Amplitude gain (magnitude)
delay=0;                                       // Time shift (seconds)
defaultdelay=0;                            // Small padding factor in case user doesn't want any delay!



sHzPrefix=emptystr();                       // Frequency scaling text prefix
freqscalar=1;                               // Frequency scalar                                       
                                                




///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


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
elseif (version(2) < 5) then
  error("Invalid Scilab version. Version 5.5 or greater is required");
end    



///////////////////
// Get number of ports
///////////////////

sportcnt=x_choices('',list(list('Select number of ports for output:',2,['2-port','4-port'])));

if sportcnt==1 then //2-port
    numofports=2;
elseif sportcnt==2 then //4-port
   numofports=4;    
else
    messagebox("Invalid number of ports selected. Script aborted", "","error","Abort");      
    abort;
    
end


///////////////////
// Get gain and delay
///////////////////


labels=["Gain(dB)";"Delay(ns)";];
   [ok,gain,delay]=getvalue("Gain and Delay",labels,...
   list("vec",1,"vec",1),[string(20*log10(gain));string(delay)]) 

if ok == 0 then
  messagebox("Why did you press cancel? Don''t you like my script?")
  abort;
end     



gain=10^(evstr(gain)/20);
delay=evstr(delay)*1e-9;


///////////////////
// Get frequeny range
///////////////////

   labels=["Fmin";"Fmax";"Num of pts"];
     [ok,freqMin,freqMax,freqNum]=getvalue("Output data frequency range (GHz)",labels,...
     list("vec",1,"vec",1,"vec",1),[string(freqMin/1e9);string(freqMax/1e9);string(freqNum)]) 

if ok == 0 then
  messagebox("Why did you press cancel. Don''t you like my script?")
  abort;
end     




freqMin=evstr(freqMin)*1e9;
freqMax=evstr(freqMax)*1e9;
freqNum=evstr(freqNum);


//Generate frequency vector
spoutfreqs=freqMin:(freqMax-freqMin)/(freqNum-1):freqMax;                   //Generate frequency points


///////////////////
// Setup files/directories for output
///////////////////


        if numofports==2 then
            foutsparam=uigetfile("*.s2p", "",  "Please choose destination S-parameters file");      
            if fileext(foutsparam)==emptystr() then
                foutsparam=strcat([foutsparam ".s2p"]);
            end                             
        else
            foutsparam=uigetfile("*.s4p", "",  "Please choose destination S-parameters file");
            if fileext(foutsparam)==emptystr() then
                foutsparam=strcat([foutsparam ".s4p"]);
            end                 
        end
          
        
        if foutsparam==emptystr() then
            messagebox("Invalid destination file selection. Script aborted", "","error","Abort");      
            abort;
        end  



/////////////////
// Create S-param
///////////////////

if numofports>0 then

        disp(strcat(["Info: Begin writing output data file " foutsparam]));
        
        
        numofreqs=length(spoutfreqs);
        
        // Initialize 
        spoutdata=ones(numofports,numofports,numofreqs)*(10^(-100/20)+1e-9*%i);
        
        //IL
        if numofports==2 then  //2-ports version
  //          for i=1:numofreqs,
              spoutdata(2,1,:)=gain*exp(-2*%pi*%i*(delay+defaultdelay)*spoutfreqs); 
              spoutdata(1,2,:)=gain*exp(-2*%pi*%i*(delay+defaultdelay)*spoutfreqs); 
   //         end
        else  // 4-port version
//            for i=1:numofreqs,
              spoutdata(2,1,:)=gain*exp(-2*%pi*%i*(delay+defaultdelay)*spoutfreqs); 
              spoutdata(1,2,:)=gain*exp(-2*%pi*%i*(delay+defaultdelay)*spoutfreqs); 
              spoutdata(4,3,:)=gain*exp(-2*%pi*%i*(delay+defaultdelay)*spoutfreqs); 
              spoutdata(3,4,:)=gain*exp(-2*%pi*%i*(delay+defaultdelay)*spoutfreqs); 
  //          end
                
        end
        
        // Compute data for each freq
        sptlbx_writetchstn(foutsparam, spoutfreqs,  spoutdata, 50);
        
        disp("Info: Finished writing file");

end



messagebox("Done!");

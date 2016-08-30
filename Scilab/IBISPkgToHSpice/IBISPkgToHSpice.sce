// Converts IBIS Package/Pin information to HSpice subckt conversion
//
// 
//
// (c)2013  L. Rayzman


//stacksize(64*1024*1024);
clear;		


/////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////

// Converts IBIS formatted numerical values to float
//
// inputs:
//       invalue    - text representation of value
//
// outputs:
//      outvalue    - Converted float value
//       

function outvalue=ivalueconv(invalue)
    
scalef=0;    
    
    // If scientific format
    if isnum(invalue)  then
          outvalue=msscanf(invalue,'%g')      
    else //otherwise it is in "scalar" format
      select part(invalue, sum(~isletter(invalue))+1)
    case "T" then
        scalef=1e12;
    case "G" then
        scalef=1e9;
    case "M" then
        scalef=1e6;
    case "k" then
        scalef=1e3;
    case "m" then
        scalef=1e-3;
    case "u" then
        scalef=1e-6;
    case "n" then
        scalef=1e-9;
    case "p" then
        scalef=1e-12;
    case "f" then
        scalef=1e-15;
    else
        mclose('all');
        error(strcat(["ivalueconv: invalid scaling factor for" invalue]));
      end
      
      outvalue=strtod(invalue)*scalef;
    end
    


    
endfunction



//////////////////////////////////////SPECIFY//////////////////////////////////////



inputIBISfile = emptystr();                        // Filename of IBIS input file
outSubfile = emptystr();                           // Filename of the output file

defaultPkgMode=2;                                  // Default Pkg mode determined from 
                                                   // [Package] section
                                                   // 1=Min
                                                   // 2=Typ
                                                   // 3=max
                                                   
defaultPkg=-1*ones(3,3);                                                   
                                                   
componentsListStr=emptystr();                      // List of components in IBIS model                    
componentsListIdx=0;


PinsArrStr=["0" "0" "0"];                         // Array of pin_name, signal_name, model_name
PinsArrPkg=[];                                    // Array of package parasitics
NumOfPins=0;                                      // Number of package pins

overridePinRLCMode=%F;                            // Force RLC rather than w-element modes for
                                                  // signal pins
                                                  
overridePwrPins=%T;                               // Use ideal power and GND pin connections                                                  
                                                  
rshunt=1e6;                                       // Value of force shunt resistance values

                 




/////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////READ PIN INFO FROM IBIS////////////////////////////////////

//Open File
inputIBISfile=uigetfile("*.ibs" ,boxTitle="Please choose input IBIS file"); 
if inputIBISfile==emptystr() then
  messagebox("Invalid file selection. Script aborted");
  abort;
end
             

[fhandle,err]=mopen(inputIBISfile, "r");  

if err<0 then
   error("Unable to open input file");  
end   

// List all components and allow user to select
txtline=emptystr();

stopflag=%F;  // Reset stop flag

while stopflag==%F
    txtline=mgetl(fhandle,1)
    if meof(fhandle) then                                                //If end of file, stop
        stopflag = %T;
    else

        txtline=stripblanks(tokens(txtline), %t)

        //if component, add to list
        if ~isempty(txtline) then
            if  ~strcmpi(txtline(1),"[component]") then
             componentsListIdx=componentsListIdx+1; 
             componentsListStr(componentsListIdx)=txtline(2);
            end
       end
    end
end

// Present list to user as selection
componentsListIdx = x_choose_modeless(componentsListStr,"Select component");

if componentsListIdx==0 then
    mclose('all');
    messagebox("Script aborted");
    abort;
end  


// Select mode

defaultPkgMode= x_choose_modeless(['Min', 'Typ', 'Max'],"Select process corner");



// Got to component
mseek(0, fhandle);

stopflag=%F;  // Reset stop flag

while stopflag==%F
    txtline=mgetl(fhandle,1)
    if meof(fhandle) then                                                //If end of file, stop
        stopflag = %T;
    else
        
        txtline=stripblanks(tokens(txtline), %t)        
        //if component, add to list
        if size(txtline,1)>1 then
            
            if ~strcmpi(txtline(1),"[component]") then
               if  ~strcmpi(txtline(2),componentsListStr(componentsListIdx)) then
                stopflag = %T;
                end
            end
        end
    end
end

fh_offsetIdx=mtell(fhandle);                                             // Save location of component

// Search for package info

stopflag=%F;  // Reset stop flag

while stopflag==%F
    txtline=mgetl(fhandle,1)
    if meof(fhandle) then                                                //If end of file, stop
        stopflag = %T;
    else
        txtline=stripblanks(tokens(txtline), %t);
        //if package, add to list
        if ~isempty(txtline) then
            if  ~strcmpi(txtline(1),"[package]") then
                stopflag = %T;
            elseif (~strcmpi(txtline(1),"[component]")) | (~strcmpi(txtline(1),"[model]")) then
                pause;
                mclose('all');
                error("Unable to find [Package] section");  
            end
        end
    end
end


// Get package info
stopflag=%F;  // Reset stop flag

while stopflag==%F
    txtline=mgetl(fhandle,1);
    if meof(fhandle) then                                                //If end of file, stop
        stopflag = %T;
    else
        txtline=stripblanks(tokens(txtline), %t) 
               
        //Get the pins value
        if ~isempty(txtline) then
            if  ~strcmpi(txtline(1),"R_pkg") then
                defaultPkg(1,2)=ivalueconv(txtline(2));
                if ~strcmpi(txtline(3),"na") then
                    defaultPkg(1,1)=ivalueconv(txtline(2));
                else
                    defaultPkg(1,1)=ivalueconv(txtline(3));
                end
                
                if ~strcmpi(txtline(4),"na") then
                    defaultPkg(1,3)=ivalueconv(txtline(2));
                else
                    defaultPkg(1,3)=ivalueconv(txtline(4));
                end
                
            elseif ~strcmpi(txtline(1),"L_pkg") then
                defaultPkg(2,2)=ivalueconv(txtline(2));
                if ~strcmpi(txtline(3),"na") then
                    defaultPkg(2,1)=ivalueconv(txtline(2));
                else
                    defaultPkg(2,1)=ivalueconv(txtline(3));                    
                end
                
                if ~strcmpi(txtline(4),"na") then
                    defaultPkg(2,3)=ivalueconv(txtline(2));
                else
                    defaultPkg(2,3)=ivalueconv(txtline(4));                    
                end
                
            elseif ~strcmpi(txtline(1),"C_pkg") then
            defaultPkg(3,2)=ivalueconv(txtline(2));
                if ~strcmpi(txtline(3),"na") then
                    defaultPkg(3,1)=ivalueconv(txtline(2));
                else
                    defaultPkg(3,1)=ivalueconv(txtline(3));                    
                end
                
                if ~strcmpi(txtline(4),"na") then
                    defaultPkg(3,3)=ivalueconv(txtline(2));
                else
                    defaultPkg(3,3)=ivalueconv(txtline(4));                    
                end

              elseif part(txtline(1),1)=="[" then
                mclose('all');
                error("Parse error in [Package] section");  
            end
         end
     end
     
        
        // Check that got all 3 parameters
        if (defaultPkg(1,2)> -1) & (defaultPkg(2,2)> -1) & (defaultPkg(3,2)> -1) then
            stopflag = %T;
        end
        
end

 // Get pin info

mseek(fh_offsetIdx, fhandle);                                          // Reset to offset of the component

stopflag=%F;  // Reset stop flag

while stopflag==%F
    txtline=mgetl(fhandle,1)
    if meof(fhandle) then                                                //If end of file, stop
        stopflag = %T;
    else
        txtline=stripblanks(tokens(txtline), %t)        
        //if package, add to list
        if ~isempty(txtline) then
            if  ~strcmpi(txtline(1),"[pin]") then
                stopflag = %T;
            elseif (~strcmpi(txtline(1),"[component]")) | (~strcmpi(txtline(1),"[model]")) then
                mclose('all');
                error("Unable to find [Pin] section");  
            end
        end
    end
end


// Get the order of the R, L, C from header
R_pinCol=0;
C_pinCol=0;
L_pinCol=0;

if size(txtline,1)<>6 then
    
      mclose('all');
      error("Invalid [pin] section header");     
else
    if ~strcmpi(txtline(4),"r_pin") then
        R_pinCol=4;
    elseif ~strcmpi(txtline(5),"r_pin") then
        R_pinCol=5;    
    elseif ~strcmpi(txtline(6),"r_pin") then
        R_pinCol=6;   
    else
      mclose('all');
      error("Invalid [pin] section header for R_pin");     
    end
    
    if ~strcmpi(txtline(4),"l_pin") then
        L_pinCol=4;
    elseif ~strcmpi(txtline(5),"l_pin") then
        L_pinCol=5;    
    elseif ~strcmpi(txtline(6),"l_pin") then
        L_pinCol=6;   
    else
      mclose('all');
      error("Invalid [pin] section header for L_pin");     
    end
    
    if ~strcmpi(txtline(4),"c_pin") then
        C_pinCol=4;
    elseif ~strcmpi(txtline(5),"c_pin") then
        C_pinCol=5;    
    elseif ~strcmpi(txtline(6),"c_pin") then
        C_pinCol=6;   
    else
      mclose('all');
      error("Invalid [pin] section header for C_pin");     
    end

end

// Get info for each pin
stopflag=%F;  // Reset stop flag
       
while stopflag==%F
    txtline=mgetl(fhandle,1)
    if meof(fhandle) then                                                //If end of file, stop
        stopflag = %T;
    else
        txtline=stripblanks(tokens(txtline), %t)    
        
        if ~isempty(txtline) then
            
            if part(txtline(1),1)=="[" then                               // We're done
                stopflag = %T;
            elseif part(txtline,1)<>"|" then
                
                NumOfPins=NumOfPins+1;
                
                PinsArrStr(NumOfPins,:)=[txtline(1) txtline(2) txtline(3)];  //Save pin information
                
                // If 3 columns 
                if size(txtline,1)==3 then
                  // Use R, L, C from package for corner   
                  PinsArrPkg(NumOfPins,1)=defaultPkg(1,defaultPkgMode);       //R
                  PinsArrPkg(NumOfPins,2)=defaultPkg(2,defaultPkgMode);       //L                  
                  PinsArrPkg(NumOfPins,3)=defaultPkg(3,defaultPkgMode);       //C                  
                    
               
               // If 6 columns
                elseif size(txtline,1)==6 then
                   // Get R
                   // if NA use R from package for corner
                   if strcmpi(txtline(R_pinCol),"na") then
                    PinsArrPkg(NumOfPins,1)=ivalueconv(txtline(R_pinCol));
                   else
                    PinsArrPkg(NumOfPins,1)=defaultPkg(1,defaultPkgMode);                    
                   end
                   
                   // Get L
                   // if NA use L from package for corner   
                   if strcmpi(txtline(L_pinCol),"na") then
                    PinsArrPkg(NumOfPins,2)=ivalueconv(txtline(L_pinCol));
                   else
                    PinsArrPkg(NumOfPins,2)=defaultPkg(2,defaultPkgMode);                    
                   end
                   
                   // Get C
                   // if NA use C from package for corner   
                   if strcmpi(txtline(C_pinCol),"na") then
                    PinsArrPkg(NumOfPins,3)=ivalueconv(txtline(C_pinCol));
                   else
                    PinsArrPkg(NumOfPins,3)=defaultPkg(3,defaultPkgMode);                    
                   end
    
                else
                    mclose('all');
                    error("Invalid format in [Pin] section");  
                end
                
            end
                     
       // 
        end
   
       
   end
       
end

// Check that at least one pin was captured
if NumOfPins < 1 then
    mclose('all');
    error("Unable to find pin information");  
end

mclose(fhandle)
//messagebox("Done");


/////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////WRITE SUBCKT////////////////////////////////////////


//Open File for writing
outSubfile=uiputfile("*.inc" ,boxTitle="Please choose output file"); 
if outSubfile==emptystr() then
  messagebox("Invalid file selection. Script aborted");
  abort;
end


// Add extension if necessary
if isempty(fileparts(outSubfile, 'extension'))   then
    
    outSubfile=strcat([outSubfile, '.inc']);
end


[fhandle,err]=mopen(outSubfile, "wt");  

if err<0 then
   error("Unable to open input file");  
end   




//Write header
curdate=getdate();
mfprintf(fhandle, "*Spice package model for %s extracted from %s%s\n", componentsListStr(componentsListIdx), fileparts(inputIBISfile, 'fname'), fileparts(inputIBISfile, 'extension'));
mfprintf(fhandle, "*Created using IBISPkgToHSpice script on %d/%d/%d at %d:%d:%d\n", curdate(2), curdate(6), curdate(1), curdate(7), curdate(8), curdate(9));
mfprintf(fhandle, "*\n");
mfprintf(fhandle, "*Ensure to set ''package=0'' in the .IBIS declaration\n");
mfprintf(fhandle, "*Example:\n");
mfprintf(fhandle, "*.IBIS DDR3_Cntrl\n");
mfprintf(fhandle, "*+ file = ''Z:\\IBIS\\ibm\\h2_ddr343p2_1p35.ibs''\n");
mfprintf(fhandle, "*+ component = ''hawk2_ddr32p1''\n");
mfprintf(fhandle, "*+ mod_sel = ''DQ = dq_60_1p35_150ps, ADR=adr_40_1p35_150ps''\n");
mfprintf(fhandle, "*+ package=0                                                <==  \n");
mfprintf(fhandle, "\n");
mfprintf(fhandle, "\n");

//Write subckt declaration
if defaultPkgMode==1 then   //min
    mfprintf(fhandle, ".subckt %s_pkg_min\n", componentsListStr(componentsListIdx));
elseif defaultPkgMode==2    //Typ
    mfprintf(fhandle, ".subckt %s_pkg_typ\n", componentsListStr(componentsListIdx));    
else                       //Max
    mfprintf(fhandle, ".subckt %s_pkg_max\n", componentsListStr(componentsListIdx));    
end



for i=1:NumOfPins
    mfprintf(fhandle, "+ %s_%s_die %s_%s_ball    $%s\n", componentsListStr(componentsListIdx), PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), PinsArrStr(i,2));
end
mfprintf(fhandle, "+ gnd_0\n");
mfprintf(fhandle, "\n");
mfprintf(fhandle, "\n");


// Create pin models here
for i=1:NumOfPins
   
    mfprintf(fhandle, "\n*Pin %s  %s\n", PinsArrStr(i,1), PinsArrStr(i,2));
    
    // If power and gnd pins use RLC model
    if ~strcmpi(PinsArrStr(i,3), 'power') | ~strcmpi(PinsArrStr(i,3), 'gnd')      then
        
        if overridePwrPins then
            mfprintf(fhandle, "r%s  %s_%s_die  rl%s_%s %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), 0);   //R
            mfprintf(fhandle, "l%s  rl%s_%s  %s_%s_ball %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), 0);   //L
            mfprintf(fhandle, "c%s  %s_%s_ball  gnd_0 %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), 1e-15);   //C
            mfprintf(fhandle, "rs%s  %s_%s_ball  gnd_0 %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), rshunt);   //Rshunt
        else
            mfprintf(fhandle, "r%s  %s_%s_die  rl%s_%s %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), PinsArrPkg(i,1));   //R
            mfprintf(fhandle, "l%s  rl%s_%s  %s_%s_ball %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), PinsArrPkg(i,2));   //L
            mfprintf(fhandle, "c%s  %s_%s_ball  gnd_0 %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), PinsArrPkg(i,3));   //C
            mfprintf(fhandle, "rs%s  %s_%s_ball  gnd_0 %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), rshunt);   //Rshunt
        end
        

    
    // signal pin
   else  

       // If force RLC mode or if any of R,L,C equal to 0 then create RLC circuit
        if (overridePinRLCMode==%T) | (PinsArrPkg(i,1)==0) | (PinsArrPkg(i,2)==0) | (PinsArrPkg(i,3)==0)  then
            mfprintf(fhandle, "r%s  %s_%s_die  rl%s_%s %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), PinsArrPkg(i,1));   //R
            mfprintf(fhandle, "l%s  rl%s_%s  %s_%s_ball %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), PinsArrPkg(i,2));   //L
            mfprintf(fhandle, "c%s  %s_%s_ball  gnd_0 %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), PinsArrPkg(i,3));   //C
            mfprintf(fhandle, "rs%s  %s_%s_ball  gnd_0 %0.6e\n", PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), rshunt);   //Rshunt
        // Otherwise create w-element
        else
            mfprintf(fhandle, "*TD=%0.3e Z0=%0.3e\n", sqrt(PinsArrPkg(i,2)*PinsArrPkg(i,3)), sqrt(PinsArrPkg(i,2)/PinsArrPkg(i,3)) );                                
            mfprintf(fhandle, "w_%s_pkgTline N=1 %s_%s_die gnd_0 %s_%s_ball gnd_0\n",PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1), componentsListStr(componentsListIdx), PinsArrStr(i,1));        
            mfprintf(fhandle, "+ RLGCmodel=%s_pkgTline_model L=1.0000000e-0\n",PinsArrStr(i,1));        
            mfprintf(fhandle, ".MODEL %s_pkgTline_model W MODELTYPE=RLGC N=1\n",PinsArrStr(i,1));                    
            mfprintf(fhandle, "+ Lo = \n");                                
            mfprintf(fhandle, "+  %0.6e\n", PinsArrPkg(i,2));                                            
            mfprintf(fhandle, "+ Co = \n");                                
            mfprintf(fhandle, "+  %0.6e\n", PinsArrPkg(i,3));                                                        
            mfprintf(fhandle, "+ Ro = \n");                                
            mfprintf(fhandle, "+  %0.6e\n", PinsArrPkg(i,1));                                                        
            mfprintf(fhandle, "+ Go = \n");                                
            mfprintf(fhandle, "+  %0.6e\n", 0);                                                                    
        end
    end
end







// Write tail
mfprintf(fhandle, "\n.ends\n");

mclose('all');

// 
// Print some statistics
//

disp("\n*******************************\n");
disp("Finished for %d pins", NumOfPins);
disp("\n*******************************\n");














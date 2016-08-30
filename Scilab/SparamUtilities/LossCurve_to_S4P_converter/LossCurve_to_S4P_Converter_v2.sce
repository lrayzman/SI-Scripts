// ======================   Loss Curve to S-param  ====================
// 
// Creates an s2p or s4p file based on canonnical loss equation fit
// of loss data
//   
//                                      
//     loss(dB)=length in inch (DC loss + alpha*f^0.5 + beta*f + gamma * f^2)
//
//       where 
//            alpha, beta, gamma -  loss coefficients per inch
//
// (c)2014  L. Rayzman
//
// Created      : 03/26/2014
// Last Modified:  03/26/2014 - Initial
//                 07/15/2014 - Added parameter extraction from data
//                              Added DC loss calculation
//
//
//  
//
//
//  INPUT DATA INSTRUCTIONS: 
//                 1. Prepare a CSV file containing loss data in the format
//                       freq pt 1(GHz), loss pt 1(dB/PER INCH)
//                       freq pt 2(GHz), loss pt 2(dB/PER INCH)
//                       freq pt 3(GHz), loss pt 3(dB/PER INCH)
//                                     .
//                                     .
//                                     .
//                  FOR EXCEL:
//                    Usually this data will come from PCB Material IL Data spreadsheet
//
//                    Notes:  -  In Excel you can use Transpose Paste to convert horizontal to vertical data
//                            -  Save Excel data to .CSV file not .xls/.xlsx 
//                            -  Frequency data does not have to be in sequential order
//
//                  FOR S-PARAM FILES:
//                     It is possible to use SPEX to generate the CSV file
//                     To do this 
//                             - view the curve you want to output
//                             - in the plot, set the File->Delimiter to Comma(,)
//                             - File->Export XY Data to .csv
//                             - Open in Excel
//                               Remove header line
//                               Rescale to loss per inch, as necessary
//                     
//                     
// 
//                 2. Run this script and follow all commands
//   
//
//
//
// ====================================================================
// ====================================================================

//clear;	

stacksize(128*1024*1024);	

///////////////////////////////////////////////////////////////////////////////

fin_csv=emptystr();                             // Filename of input CSV data

spin_raw=[];                                    // Raw input CSV data
spinfreqs=[];                                   // Input frequency data
spinlossdata=[];                                // Input loss data


foutsparam = emptystr();                        // Filename of S2p Output file
spoutfreqs=[];                                  // Output frequency points vector
spoutdata=[];                                   // Output S-param matrix data

numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

entries_choice=emptystr();                      // Text matrix that describes available entries to view
entry_idx=0;                                    //  

freqMax=20.0e9;                                   // Minimum and maximum frequencies
freqMin=0;                                                   
freqNum=400;                                   // Number of frequency points


alphaf=0;                                        // Line loss parameters
betaf=0;
gammaf=0;

DCloss=0;                                        // DC loss in dB
trc_wd=6;                                        // Trace width for DC calculations
trc_hght=0.65;                                   // Trace height for DC calculations

len_scalar=1;                                    // Length normalization scaling factor


splossdata_fit=[];                               // Loss data fit
c_coeff=[];                                      // Coefficients of fit curve
c_coeff0=[alphaf;betaf;gammaf];                  // Initial coefficient values         


                                            // PLOTTING STUFF
plot_fig_idx=0;                             // Plot index

gui_plot_w  = 600;                         // Plot width
gui_plot_h  = 400;                          // Plot height

sHzPrefix=emptystr();                       // Frequency scaling text prefix
freqscalar=1;                               // Frequency scalar                                       
                                                


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

//
//  Curve fitting function for leastsq
//
//  
//
// Inputs:
//        f: frequency point
//        x: coefficients
//  Outputs:
//        y: ditto
//

function y=xfit(f, x)
   y=x(1)*f.^(0.5)+x(2)*f+x(3)*f.^2
endfunction  



//
//  Error function for leastsq
//
//  
//
// Inputs:
//
//        f: frequency points vector
//    x_hat: esimated data value 
//        x: actual data value
//  Outputs:
//        e: ditto
//
function e=errfunc(x_hat, f, x)
   e= x - xfit(f, x_hat)
endfunction  



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
// Informational
///////////////////
messagebox("See notes in sce file for instructions on input data format", "modal", "info", "OK");


///////////////////
// Select input data file
///////////////////
fin_csv=uigetfile("*.csv", "",  "Please choose phase noise data file");                                                

if fin_csv==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
    abort;
end

disp(strcat(["Info: Begin loading input data file " fin_csv]));

spin_raw=csvRead(fin_csv);                                  // Read raw data

if size(spin_raw,2)<>2  then
        messagebox("Invalid dimensions of input data. Expecting data in (freq, data) format.   Script aborted", "","error","Abort");      
    abort;
end

                               //... and sort in the process
spinfreqs=spin_raw(:,1)*1e9;       // In Hz
[spinfreqs,spinorder]=gsort(spinfreqs,'g','i');
spinlossdata=spin_raw(spinorder,2);        // In dB

                                   // check loss data, if attenuation make it loss
spinlossdata=spinlossdata.*((spinlossdata<=0)*2-1);

clear spin_raw;

disp("Info: Finished loading data file");

///////////////////
// Get and compute DC loss
///////////////////
   labels=["Trace Width(mil)";"Trace Height(mil)"];
     [ok,trc_wd,trc_hght]=getvalue("Trace geometry for DC loss",labels,...
     list("vec",1,"vec",1),[string(trc_wd);string(trc_hght)]) 
     
if ok == 0 then
  messagebox("Why did you press cancel. Don''t you like my script?")
  abort;
end     


//calculate loss
DCloss=20*log10(2/(2+ (0.0254)/(5.8e7*trc_wd*2.54e-5*trc_hght*2.54e-5)/50));


///////////////////
// Get number of ports
///////////////////

sportcnt=x_choices('',list(list('Select number of ports for output:',3,['No output', '2-port','4-port'])));

if sportcnt==1 then //No output
    numofports=0;
elseif sportcnt==2 then //2-port
   numofports=2;    
elseif sportcnt==3 then //4-port
   numofports=4;
else
    messagebox("Invalid number of ports selected. Script aborted", "","error","Abort");      
    abort;
    
end

///////////////////
// Get frequeny range
///////////////////

if numofports>0 then
   labels=["Fmin";"Fmax";"Num of pts"];
     [ok,freqMin,freqMax,freqNum]=getvalue("Output data frequency range (GHz)",labels,...
     list("vec",1,"vec",1,"vec",1),[string(freqMin/1e9);string(freqMax/1e9);string(freqNum)]) 
else
  labels=["Fmin";"Fmax"];
[ok,freqMin,freqMax]=getvalue("Output data frequency range (GHz)",labels,...
     list("vec",1,"vec",1),[string(freqMin/1e9);string(freqMax/1e9)])  
        
end


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
// Get scaling factor
///////////////////


if numofports>0 then
    [ok,len_scalar]=getvalue(["Length scaling factor"; ""; "Example: 1 meter : 1 inch = 39.37"],"", list("vec",1),"39.37");
    
    if ok == 0 then
      messagebox("Why did you press cancel. Don''t you like my script?")
      abort;
    end
end




///////////////////
// Setup files/directories for output
///////////////////

if numofports>0 then
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
end


///////////////////
// Curve fit equation coefficients
///////////////////

[splossdata_fit, c_coeff]=leastsq(list(errfunc, spinfreqs/1e9, spinlossdata-DCloss), c_coeff0);    

alphaf=c_coeff(1)*(1e-9)^0.5;            // This is workaround(?) for leastsq 
betaf=c_coeff(2)*(1e-9);                 // because it doesn't seem to find small 
gammaf=c_coeff(3)*(1e-9)^2;              // coefficient values when using the native
                                         // frequency range
clear c_coeff;
clear c_coeff0;



///////////////////
// Create S-param
///////////////////

if numofports>0 then

        disp(strcat(["Info: Begin writing output data file " foutsparam]));
        
        
        numofreqs=length(spoutfreqs);
        
        // Initialize
        spoutdata=ones(numofports,numofports,numofreqs)*(10^(-100/20)+1e-9*%i);
        
        
        if numofports==2 then  //2-ports version
            for i=1:numofreqs,
              spoutdata(2,1,i)=10^((DCloss+alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))*len_scalar/20)+1e-9*%i;
              spoutdata(1,2,i)=10^((DCloss+alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))*len_scalar/20)+1e-9*%i;
            end
        else  // 4-port version
            for i=1:numofreqs,
              spoutdata(2,1,i)=10^((DCloss+alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))*len_scalar/20)+1e-9*%i;   // IL
              spoutdata(1,2,i)=10^((DCloss+alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))*len_scalar/20)+1e-9*%i;
              spoutdata(4,3,i)=10^((DCloss+alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))*len_scalar/20)+1e-9*%i;
              spoutdata(3,4,i)=10^((DCloss+alphaf*(spoutfreqs(i)^0.5)+betaf*(spoutfreqs(i))+gammaf*(spoutfreqs(i)^2))*len_scalar/20)+1e-9*%i;      
            end
                
        end
        
        // Compute data for each freq
        sptlbx_writetchstn(foutsparam, spoutfreqs,  spoutdata);
        
        disp("Info: Finished writing file");

end


///////////////////
// Plot the fit
///////////////////


// Determaxe frequency scalar for the plot
select find([spoutfreqs($)/1e12 spoutfreqs($)/1e9 spoutfreqs($)/1e6 spoutfreqs($)/1e3 spoutfreqs($)] >= 1, 1)
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
   freqscalar=1;
else
   freqscalar=1;
end


// Create Plot window  
global plot_fig_idx;
plot_fig = scf(plot_fig_idx);
plot_fig.figure_name = gettext(strcat("Insertion Loss Fit Plot"));
plot_fig.axes_size = [gui_plot_w gui_plot_h];

drawlater();

//Plot the fit over the frequency range
plot(spinfreqs/freqscalar, spinlossdata, "kx", spoutfreqs/freqscalar, DCloss+xfit(spoutfreqs, [alphaf;betaf;gammaf]), "b-");

// Lables and things
xtitle("Insertion Loss Fit");
xlabel(strcat(["Freq (" sHzPrefix "Hz)"]));
ylabel("IL (dB/in)");

format('v',6);                      // All this funkiness to get correct float format in text :)
infotext=strcat(["DC Loss:" string(DCloss) "dB | "]);
format('e',9);
infotext=strcat([infotext "alpha:" string(alphaf) " | beta:" string(betaf) " | gamma:" string(gammaf)])
xinfo(infotext);
format('v',10);
clear infotext;


xgrid(12);

// Set plot axis
x_min=plot_fig.children.data_bounds(1,1);
y_min=floor(DCloss+xfit(spoutfreqs($), [alphaf;betaf;gammaf]));
x_max=plot_fig.children.data_bounds(2,1);
y_max=0;

plot_fig.children.data_bounds=[x_min, y_min; x_max,y_max];

// Pretty-fi
labels=plot_fig.children.x_ticks.labels;     // Funky labels workaround
plot_fig.children.x_ticks.labels=labels;
clear labels;

plot_fig.children.x_label.font_size=2;
plot_fig.children.y_label.font_size=2;         
plot_fig.children.title.font_size=3;

drawnow();

disp("Done!");

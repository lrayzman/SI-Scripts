// ==================   Phase-Noise Plotter Utility ===================
// 
//  Can be used with csv export from Agilent SSA
//
// (c)2014  L. Rayzman
//
//
// Created      : 06/18/2014
// Last Update  : 
//                               
//
//
// TODO:  
//        
// ====================================================================
// ====================================================================

clear;	

stacksize(200*1024*1024);

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

finput = emptystr();                        // Filename of inputfile

Pn_Data=[];                                 // Raw PN data
Pn_f=[];                                    // Frequency points 
Pn_L=[];                                    // Phase noise data from file

f0=1e6;                                     // Carrier frequency
                                            
                                            // Integrated phase jitter band
f_irj_min=12e3;                             // max freq
f_irj_min_scalar=1;
f_irj_minPrefix=emptystr();
f_irj_max=20e6;                             // max freq
f_irj_max_scalar=1;
f_irj_maxPrefix=emptystr();

tjrms=0;                                    //  RMS jitter
tjPrefix=emptystr();                       // jitter scaling text prefix
tscalar=1;                                  //  jitter scalar

                                            // PLOTTING STUFF
plot_fig_idx=0;                             // Plot index

gui_plot_w  = 1300;                         // Plot width
gui_plot_h  = 700;                          // Plot height

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
  error("Invalid Scilab version. Version 5.2 or greater is required");
elseif (version(2) < 2) then
  error("Invalid Scilab version. Version 5.2 or greater is required");
end    

///////////////////
// Setup files/directories
// Read data
// Get user input
///////////////////

//
// Read input file
//
//
finput=uigetfile("*.csv", "",  "Please choose phase noise data file");                                                

if finput==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
    abort;
end

disp(strcat(["Info: Begin loading data file " finput]));

Pn_Data=csvRead(finput);                                  // Read raw data
                                                          

if size(Pn_Data,2)==2 then                               // Copy parsed data
    k = find(~isnan(Pn_Data(:,1)));
    
    Pn_f=Pn_Data(k,1);
    Pn_L=10^(Pn_Data(k,2)/10);
    
    clear Pn_Data;
    clear k;
end                                                   

disp("Info: Finished loading data file");


///////////////////
// Get f0 freq from user
///////////////////


temp = x_mdialog('Phase Noise Params',["Measured Clock Frequency (MHz)"; "Integration BW max Freq (KHz)"; "Integration BW Max Freq (MHz)"],[string(f0/1e6);string(f_irj_min/1e3);string(f_irj_max/1e6)]);
f0 = evstr(temp(1))*1e6;
f_irj_min = evstr(temp(2))*1e3;
f_irj_max  = evstr(temp(3))*1e6;

if temp==[] then
    messagebox("Script aborted", "","error","Abort");      
    abort;
end

if (f0<=0) then
    messagebox("Invalid clock frequency value. Script aborted", "","error","Abort");      
    abort;
end

if  (f_irj_min <=0) Then
    messagebox("Invalid BW min frequency value. Script aborted", "","error","Abort");      
    abort;
end

if  (f_irj_max <=0) Then
    messagebox("Invalid BW max frequency value. Script aborted", "","error","Abort");      
    abort;
end

if (f_irj_min >= f_irj_max) then
    messagebox("Invalid BW max frequency value. Script aborted", "","error","Abort");      
    abort; 
end


// maxor adjustement
if f_irj_min < Pn_f(1) then
    f_irj_min = Pn_f(1);
end

if f_irj_max > Pn_f($) then
    f_irj_max = Pn_f($);
end


///////////////////
// Compute integrated
// RMS jitter
///////////////////

k=find((Pn_f >= f_irj_min) & (Pn_f <= f_irj_max));
tjrms=sqrt(sum(diff(Pn_L(k))/2+Pn_L(k(1:$-1)).*diff(Pn_f(k)))/((sqrt(2)*%pi*f0)^2));   
clear k;


///////////////////
// Plot Phase Noise 
///////////////////


// Determaxe frequency scalar for the plot
select find([Pn_f($)/1e12 Pn_f($)/1e9 Pn_f($)/1e6 Pn_f($)/1e3 Pn_f($)] >= 1, 1)
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

// Determine int BW min scalar for plot
select find([f_irj_min/1e12 f_irj_min/1e9 f_irj_min/1e6 f_irj_min/1e3 f_irj_min] >= 1, 1)
case 1 then      //THz :)
    f_irj_minPrefix= "T";
    f_irj_min_scalar=1e12;
case 2 then     //GHz
    f_irj_minPrefix= "G";
    f_irj_min_scalar=1e9;
case 3 then     //MHz
    f_irj_minPrefix= "M";
    f_irj_min_scalar=1e6;
case 4 then    // KHz
    f_irj_minPrefix= "K";
    f_irj_min_scalar=1e3;
case 5 then   // Hz             
   f_irj_min_scalar=1;
else
   f_irj_min_scalar=1;
end

// Determaxe int BW max scalar for plot
select find([f_irj_max/1e12 f_irj_max/1e9 f_irj_max/1e6 f_irj_max/1e3 f_irj_max] >= 1, 1)
case 1 then      //THz :)
    f_irj_maxPrefix= "f";
    f_irj_max_scalar=1e12;
case 2 then     //GHz
    f_irj_maxPrefix= "G";
    f_irj_max_scalar=1e9;
case 3 then     //MHz
    f_irj_maxPrefix= "M";
    f_irj_max_scalar=1e6;
case 4 then    // KHz
    f_irj_maxPrefix= "K";
    f_irj_max_scalar=1e3;
case 5 then   // Hz             
   f_irj_max_scalar=1;
else
   f_irj_max_scalar=1;
end




// Determaxe jitter scalar for the phase noise plot
select find([tjrms*1e15 tjrms*1e12 tjrms*1e9 tjrms*1e6 tjrms*1e3 tjrms]<1000 ,1)
case 1 then      //femto 
    tjPrefix= "f";
    tscalar=1e15;
case 2 then     //pico
    tjPrefix= "p";
    tscalar=1e12;
case 3 then     //nano
    tjPrefix= "n";
    tscalar=1e9;
case 4 then    // micro
    tjPrefix= "u";
    tscalar=1e6;
case 5 then   // milli        
    tjPrefix= "m";     
    tscalar=1e3;
case 6 then   // nothing
    tscalar=1;   
else
    tscalar=1;    
end



// Create Phase Noise plot window  
global plot_fig_idx;
plot_fig = scf(plot_fig_idx);
plot_fig.figure_name = gettext(strcat("Phase Noise Plot"));
plot_fig_idx = plot_fig_idx + 1;
plot_fig.axes_size = [gui_plot_w gui_plot_h];


drawlater();
             
// Phase Noise Plot               
plot2d(Pn_f/freqscalar, 10*log10(Pn_L), logflag="ln", style=2);                

// Lables and things
xtitle(strcat(["Phase Noise: " basename(finput) fileparts(finput, "extension")]));
xlabel(strcat(["Freq (" sHzPrefix "Hz)"]));
ylabel("Phase Noise (dBc/Hz)");
format('v',7);
xinfo(strcat(["Carrier: " string(f0/1e6) " MHz |  " ...
              "Calculated RMS jitter(" string(f_irj_min/f_irj_min_scalar) f_irj_minPrefix "Hz to " string(f_irj_max/f_irj_max_scalar) f_irj_maxPrefix "Hz): " ...
               string(tjrms*tscalar) " " tjPrefix "s" ]));
format('v',10);
xgrid(12);

// Set plot axis
x_min=plot_fig.children.data_bounds(1,1);
y_min=-160;
x_max=plot_fig.children.data_bounds(2,1);
y_max=-20;

plot_fig.children.data_bounds=[x_min, y_min; x_max,y_max];

// Add integration band markers
lines_x=[f_irj_min/freqscalar f_irj_max/freqscalar; f_irj_min/freqscalar f_irj_max/freqscalar];
lines_y=[y_max y_max; y_min y_min];
xset("line style", 2);
xpolys(lines_x, lines_y);


// Pretty-fi
labels=plot_fig.children.x_ticks.labels;     // Funky labels workaround
plot_fig.children.x_ticks.labels=labels;
clear labels;

plot_fig.children.x_label.font_size=2;
plot_fig.children.y_label.font_size=2;         
plot_fig.children.title.font_size=3;


drawnow();


///////////////////
// Plot Jitter
///////////////////

trmax=max(sqrt(Pn_L)/(sqrt(2)*%pi*f0));
trmax=10^round(log10(trmax));

// Determaxe jitter scalar for the jitter plot
select find([trmax*1e15 trmax*1e12 trmax*1e9 trmax*1e6 trmax*1e3 trmax]<1000 ,1)
case 1 then      //femto 
    trPrefix= "f";
    trscalar=1e15;
case 2 then     //pico
    trPrefix= "p";
    trscalar=1e12;
case 3 then     //nano
    trPrefix= "n";
    trscalar=1e9;
case 4 then    // micro
    trPrefix= "u";
    trscalar=1e6;
case 5 then   // milli        
    trPrefix= "m";     
    trscalar=1e3;
case 6 then   // nothing
    trscalar=1;   
else
    trscalar=1;    
end

// Create RMS jitter plot window  
plot_fig = scf(plot_fig_idx);
plot_fig.figure_name = gettext(strcat("Phase Noise Plot"));
plot_fig_idx = plot_fig_idx + 1;
plot_fig.axes_size = [gui_plot_w gui_plot_h];



drawlater();
             
// RMS jitter Plot               
plot2d(Pn_f/freqscalar, sqrt(Pn_L)/(sqrt(2)*%pi*f0)*trscalar, logflag="ln", style=2);                

// Lables and things
xtitle(strcat(["Jitter: "basename(finput) fileparts(finput, "extension")]));
xlabel(strcat(["Freq (" sHzPrefix "Hz)"]));
ylabel(strcat(["Jitter (" trPrefix "s)"]));
format('v',7);
xinfo(strcat(["Carrier: " string(f0/1e6) " MHz |  " ...
              "Calculated RMS jitter(" string(f_irj_min/f_irj_min_scalar) f_irj_minPrefix "Hz to " string(f_irj_max/f_irj_max_scalar) f_irj_maxPrefix "Hz): " ...
               string(tjrms*tscalar) " " tjPrefix "s" ]));
format('v',10);
xgrid(12);

// Set plot axis
x_min=plot_fig.children.data_bounds(1,1);
y_min=0;
x_max=plot_fig.children.data_bounds(2,1);
y_max=trmax*trscalar;


plot_fig.children.data_bounds=[x_min, y_min; x_max,y_max];

// Add integration band markers
lines_x=[f_irj_min/freqscalar f_irj_max/freqscalar; f_irj_min/freqscalar f_irj_max/freqscalar];
lines_y=[y_max y_max; y_min y_min];
xset("line style", 2);
xpolys(lines_x, lines_y);


// Pretty-fi
labels=plot_fig.children.x_ticks.labels;     // Funky labels workaround
plot_fig.children.x_ticks.labels=labels;
clear labels;

plot_fig.children.x_label.font_size=2;
plot_fig.children.y_label.font_size=2;         
plot_fig.children.title.font_size=3;


drawnow();










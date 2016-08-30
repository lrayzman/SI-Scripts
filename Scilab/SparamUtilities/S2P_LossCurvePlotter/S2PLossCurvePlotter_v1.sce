
// ======================   S-param Loss Plotter ====================
// 
// Creates an s2p file with loss profile of the cannonical loss
// form
//
// (c)2013  L. Rayzman
//
//
// Created      :  01/18/2013
// Last Modified:  01/18/2013
//
//
// ====================================================================
// ====================================================================

//clear;	

stacksize(128*1024*1024);	

///////////////////////////////////////////////////////////////////////////////


frefsparam = emptystr();                        // Filename of S2p reference file
foutsparam = emptystr();                        // Filename of S2p output file

spreffreqs=[];                                   // Reference S-param frequencies
sprefdata=[];                                   // Reference S-param matrix data

spoutdata=[];                                   // Output s-param data
                          
spfitdata=[];                                   // Data points for the fit curve

numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

                                             
srow=1;                                         // Set the Sxy to plot
scol=1;

sprefdata_row_col=[];                            // Data points from Sxy where x=row y=col
refdata_scalar=1;                                // Reference data scaling factor (for length normalization)

alphaf=0;                                        // Line loss parameters
betaf=0;
gammaf=0;

alphaf_scalar=1e-5;
betaf_scalar=1e-10;
gammaf_scalar=1e-20;

val_alpha_slider=0;                               // Slider values
val_beta_slider=0;
val_gamma_slider=0;

slider_steps=250;                                // Resolution of sliders

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
// Get reference file
///////////////////

frefsparam=uigetfile("*.s2p", "",  "Please choose reference S-parameters file");                                                

if frefsparam==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
    abort;
end

[spreffreqs,sprefdata] =sptlbx_readtchstn(frefsparam);

numofports=size(sprefdata,1);                                               //Find number of ports

if numofports <> 2 then
    messagebox("Only 2-port S-parameters are supported. Script aborted", "","error","Abort");      
    abort;
end

numofreqs=size(sprefdata,3);                                                //Find number of frequency points


///////////////////
// Get S-param scaling factor
///////////////////

labels="N";
[ok,refdata_scalar]=getvalue("Length scaling factor",labels,...
     list("vec",1),"1.00");

if ok == 0 then
  messagebox("Why did you press cancel. Don''t you like my script?")
  abort;
end


///////////////////
// Compute the initial fitdata
///////////////////

spoutdata=zeros(2,2,numofreqs);
spfitdata=-(alphaf*sqrt(spreffreqs)+betaf*spreffreqs+gammaf*spreffreqs^2);

// Compute data for each freq
for i=1:numofreqs,
      spoutdata(1,1,i)=10^(-10/20)+1e-9*%i;
      spoutdata(2,2,i)=10^(-10/20)+1e-9*%i;
      spoutdata(2,1,i)=10^((spfitdata(i))/20)+1e-9*%i;
      spoutdata(1,2,i)=10^((spfitdata(i))/20)+1e-9*%i;
end


///////////////////
// Create a plot 
///////////////////

    plot_w               = 1000;     // Plot width in pixels
    plot_h               = 800;     // Plot height in pixels
                   
    frame_w              = 0;       // Frame width in pixels
    frame_h              = 100;     // Frame height in pixels

    margin_x             = 0.125;   // Horizontal margin between each elements
    margin_y             = 0.125;   // Vertical margin between each elements
   
    figure_w       = frame_w + plot_w;    // axes width
    figure_h       = frame_h + plot_h; // axes height
    
    // Figure creation
    // =========================================================================
    ploth=scf(0);     
    drawlater();                                                                              
    srow=2;                                         // Sxy row and column 
    scol=1;                                         
    sprefdata_row_col=matrix(sprefdata(srow,scol,:), 1, numofreqs);
    
           
    ploth.color_map(33,:)=[0.85 0.85 0.85];                                                 // Set-up graphics window properties
    ploth.figure_size=[figure_w figure_h];
                                                                         
    plot_1_region_margin_lf  = margin_x;                                                  // Compute plot dimensions
    plot_1_region_margin_rt = margin_x; 
    plot_1_region_margin_top   = margin_y;
    plot_1_region_margin_bot   = margin_y + 1- plot_h/(plot_h+frame_h);
         
   
    plot_1_axes  = newaxes();                                                               // Set-up plot size
    plot_1_axes.margins=[plot_1_region_margin_lf plot_1_region_margin_rt plot_1_region_margin_top  plot_1_region_margin_bot]
    
    ploth=gca();
    ploth.grid=[33,33];                                                                     // Turn on grid
    
 
    plot2d(spreffreqs/1e9, 20*log10(abs(sprefdata_row_col))/refdata_scalar);                    // Reference magnitude plot

    plot2d(spreffreqs/1e9, spfitdata);                                                          // Reference magnitude plot
    
    ploth.children(1).children.foreground=1;                                                  // Polyline settings for fit data
    ploth.children(1).children.thickness=2;                                                   // 
    ploth.children(2).children.foreground=2;                                                  // Polyline settings for reference data
    ploth.children(2).children.thickness=1;                                                   // 

   
    xtitle(strcat(["S" string([srow scol])]), "Frequency(GHz)", "Magnitude(dB)");       
                                                                                                                                                // Legend                                          
    uicontrol("style", "text", "string", "α","FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 20, "Position", [300  100 50 30]); 
    uicontrol("style", "text", "string", "ß","FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 20, "Position", [300 70 50 30]); 
    uicontrol("style", "text", "string", "Γ","FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 20, "Position", [300 40 50 30]);
                                                                                                                                                // Sliders
    h_alpha_slider=uicontrol("style", "slider", "min", 0, "max", slider_steps, "Value", val_alpha_slider, "SliderStep", [1 5],...
                            "Position", [350 100 300 25], "tag", "tag_alpha_slider", "Callback", "sleep(10);spfitdata=refresh_display(spreffreqs)"); 
    h_beta_slider=uicontrol("style", "slider", "min", 0, "max", slider_steps, "Value", val_beta_slider, "SliderStep", [1 5],...
                            "Position", [350 70 300 25], "tag", "tag_beta_slider", "Callback", "sleep(10);spfitdata=refresh_display(spreffreqs)"); 
    h_gamma_slider=uicontrol("style", "slider", "min", 0, "max", slider_steps, "Value", val_gamma_slider, "SliderStep", [1 5],...
                            "Position", [350 40 300 25],"tag", "tag_gamma_slider", "Callback", "sleep(10);spfitdata=refresh_display(spreffreqs)"); 
    
    h_alpha_str=uicontrol("style", "text", "string", msprintf("%0.3e", alphaf), "BackgroundColor", [1 1 1], "FontSize", 12,  "Position", [700 100 100 25], "tag", "tag_alpha_str"); 
    h_beta_str=uicontrol("style", "text", "string", msprintf("%0.3e", betaf),  "BackgroundColor", [1 1 1], "FontSize", 12, "Position", [700 70 100 25], "tag", "tag_beta_str"); 
    h_gamma_str=uicontrol("style", "text", "string", msprintf("%0.3e", gammaf), "BackgroundColor", [1 1 1], "FontSize", 12, "Position", [700 40 100 25], "tag", "tag_gamma_str");
    
    uicontrol("String", "Done", "Position", [(figure_w/2-50) 10 100, 25], "Callback", "write_touchstone(spreffreqs, spfitdata, spoutdata); delete(gcf())");    

    drawnow();

///////////////////
// Refresh display
///////////////////
function [fitdata]=refresh_display(reffreqs)
    
    current_figure=gcf();
    
    current_figure.immediate_drawing="off";
    
     alphaf=get(findobj("tag", "tag_alpha_slider"), "value")/slider_steps*alphaf_scalar;            // Get new values
     betaf=get(findobj("tag", "tag_beta_slider"), "value")/slider_steps*betaf_scalar;
     gammaf=get(findobj("tag", "tag_gamma_slider"), "value")/slider_steps*gammaf_scalar;


    set(findobj("tag", "tag_alpha_str"), "string", msprintf("%0.3e", alphaf));                     // Update slider values
    set(findobj("tag", "tag_beta_str"), "string", msprintf("%0.3e", betaf)); 
    set(findobj("tag", "tag_gamma_str"), "string", msprintf("%0.3e", gammaf));
    
 
    current_axis=gca();
    
    fitdata=-(alphaf*sqrt(reffreqs)+betaf*reffreqs+gammaf*reffreqs^2);
       
    current_axis.children(1).children.data(:,2)=fitdata';       // Compute and plot new curve fit data
    
    current_figure.immediate_drawing="on";
                  
    
endfunction


function write_touchstone(reffreqs, fitdata, initdata)
    
    // Get output filename
    foutsparam=uiputfile("*.s2p", "",  "Please choose output S-parameters file");                                                
    if foutsparam==emptystr() then
        messagebox("Invalid output  file selection. Script aborted", "","error","Abort");      
        abort;
    end
    
    
    // Compute data for each freq
    for i=1:numofreqs,
      initdata(2,1,i)=10^((fitdata(i))/20)+1e-9*%i;
      initdata(1,2,i)=10^((fitdata(i))/20)+1e-9*%i;
   end
             
    pause;
                   
    sptlbx_writetchstn(foutsparam,reffreqs, initdata);
    
    messagebox("Done!");    
    
endfunction






// ======================   S-param Loss Plotter ====================
// 
// Creates an s2p file with loss profile of the cannonical loss
// form
//
// (c)2013  L. Rayzman
//
//
// Created      : 01/18/2013
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

ILD_loss=1;                                       // ILD parameters
ILD_fscale=0;

alphaf_scalar=1e-4;
betaf_scalar=1e-9;
gammaf_scalar=1e-19;

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

//frefsparam=uigetfile("*.s2p", "",  "Please choose reference S-parameters file");                                                

//if frefsparam==emptystr() then
//    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
//    abort;
//end

//[spreffreqs,sprefdata] =sptlbx_readtchstn(frefsparam);

spreffreqs=[1e7:1e7:20e9];

numofreqs=size(spreffreqs,2);                                                //Find number of frequency points
sprefdata=zeros(2,2,numofreqs);


///////////////////
// Get S-param scaling factor
///////////////////


///////////////////
// Compute the initial fitdata
///////////////////

spfitdata=-(alphaf*sqrt(spreffreqs)+betaf*spreffreqs+gammaf*spreffreqs^2);

// Compute data for each freq


///////////////////
// Create a plot 
///////////////////

    plot_w               = 1100;     // Plot width in pixels
    plot_h               = 600;     // Plot height in pixels
                   
    frame_w              = 0;       // Frame width in pixels
    frame_h              = 250;     // Frame height in pixels

    margin_x             = 0.125;   // Horizontal margin between each elements
    margin_y             = 0.05;   // Vertical margin between each elements
   
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
    
    
    plot2d(spreffreqs/1e9, spfitdata, style=5);     //upper  children(4)                       // Plot ILD and turn it off
    plot2d(spreffreqs/1e9, spfitdata, style=7);     //lower  children(3)
 
    plot2d(spreffreqs/1e9, sprefdata_row_col);     // children(2)                                     // Reference magnitude plot

    plot2d(spreffreqs/1e9, spfitdata);            // children(1)                                 // Reference magnitude plot
    
    ploth.children(1).children.foreground=1;                                                  // Polyline settings for fit data
    ploth.children(1).children.thickness=3;                                                   // 
    ploth.children(2).children.foreground=2;                                                  // Polyline settings for reference data
    ploth.children(2).children.thickness=1;                       
        
    ploth.children(3).children.foreground=12;                                                  // Polyline settings for upper ILD data
    ploth.children(3).children.thickness=1;                                                   // 
    ploth.children(3).children.line_style=2;
    ploth.children(3).visible="off";
    ploth.children(4).children.foreground=12;                                                  // Polyline settings for lower ILD data
    ploth.children(4).children.thickness=1;                                                   // 
    ploth.children(4).children.line_style=2;
    ploth.children(4).visible="off";
    
   
    xtitle(strcat(["S" string([srow scol])]), "Frequency(GHz)", "Magnitude(dB)");       
    
    
    uicontrol("style", "text", "string", "$IL(f)_d_b=\alpha\sqrt f+\beta f+\gamma f^2$","FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 11, "Position", [10 130 250 30]);
    uicontrol("style", "text", "string", "$ILD(f)_d_b\le \left|ILD\;range \left(1 + \frac{ILD\; factor\; \; }{GHz}f\right)\right|$","FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 11, "Position", [10 50 500 75]);
    
    uicontrol("style", "text", "string", "α","FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 14, "Position", [320 160 25 30]); 
    uicontrol("style", "text", "string", "ß","FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 14, "Position", [320 120 25 30]); 
    uicontrol("style", "text", "string", "Γ","FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 14, "Position", [320 80 25 30]);
    
    h_alpha_slider=uicontrol("style", "slider", "min", 0, "max", slider_steps, "Value", val_alpha_slider, "SliderStep", [1 5],...                           // Loss Sliders
                            "Position", [375 160 300 25], "tag", "tag_alpha_slider", "Callback", "sleep(10);spfitdata=refresh_display(spreffreqs)"); 
    h_beta_slider=uicontrol("style", "slider", "min", 0, "max", slider_steps, "Value", val_beta_slider, "SliderStep", [1 5],...
                            "Position", [375 120 300 25], "tag", "tag_beta_slider", "Callback", "sleep(10);spfitdata=refresh_display(spreffreqs)"); 
    h_gamma_slider=uicontrol("style", "slider", "min", 0, "max", slider_steps, "Value", val_gamma_slider, "SliderStep", [1 5],...
                            "Position", [375 80 300 25],"tag", "tag_gamma_slider", "Callback", "sleep(10);spfitdata=refresh_display(spreffreqs)"); 
                                                                                                                                                    

    h_alpha_str=uicontrol("style", "text", "string", msprintf("%0.3e", alphaf), "BackgroundColor", [1 1 1], "FontSize", 12,  "Position", [750 160 100 25], "tag", "tag_alpha_str");     
    h_beta_str=uicontrol("style", "text", "string", msprintf("%0.3e", betaf),  "BackgroundColor", [1 1 1], "FontSize", 12, "Position", [750 120 100 25], "tag", "tag_beta_str"); 
    h_gamma_str=uicontrol("style", "text", "string", msprintf("%0.3e", gammaf), "BackgroundColor", [1 1 1], "FontSize", 12, "Position", [750 80 100 25], "tag", "tag_gamma_str");
    
                                                                                                                                                            //  ILD edit boxes
    h_ILD_loss_edit=uicontrol("style", "edit", "string", msprintf("%0.1f", ILD_loss), "BackgroundColor", [1 1 1], "FontSize", 12, ...     
                            "Position", [350 40 25 25], "tag", "tag_ILD_loss_edit", "Callback", ""); 
    h_ILD_fscale_edit=uicontrol("style", "edit", "string", msprintf("%2.2f", ILD_fscale), "BackgroundColor", [1 1 1], "FontSize", 12, ...
                            "Position", [550 35 40 25], "tag", "tag_ILD_fscale_edit", "Callback", ""); 
                           
                                                                                                                                                            // ILD legend
    uicontrol("style", "text", "string", "ILD Range", "FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 12, "Position", [275 40 75 25]); 
    uicontrol("style", "text", "string", "dB", "FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 12, "Position", [375 40 25 25]); 
    
    uicontrol("style", "text", "string", "ILD factor", "FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 12, "Position", [475 40 75 25]); 
    uicontrol("style", "text", "string", "%", "FontWeight", "bold", "BackgroundColor", [1 1 1], "FontSize", 12, "Position", [595 40 25 25]);                                                                                                                                                                        
  
    uicontrol("String", "Plot ILD", "Position", [700 40 100 25], "Callback", "[ILD_Loss, ILD_fscale]=plot_ILD(spreffreqs, spfitdata)");                      

    uicontrol("String", "Write s2p", "Position", [(figure_w/2+50) 10 100, 25], "Callback", "write_touchstone(spreffreqs, spfitdata, spoutdata);");  
    
    uicontrol("String", "Done", "Position", [(figure_w/2-150) 10 100, 25], "Callback", "delete(gcf())");    

    drawnow();

///////////////////
// Refresh display
///////////////////
function [fitdata]=refresh_display(reffreqs)
    
    current_figure=gcf();
    
    current_figure.immediate_drawing="off";
    
     alphaf=-1*get(findobj("tag", "tag_alpha_slider"), "value")/slider_steps*alphaf_scalar;            // Get new values
     betaf=-1*get(findobj("tag", "tag_beta_slider"), "value")/slider_steps*betaf_scalar;
     gammaf=-1*get(findobj("tag", "tag_gamma_slider"), "value")/slider_steps*gammaf_scalar;


    set(findobj("tag", "tag_alpha_str"), "string", msprintf("%0.3e", alphaf));                     // Update slider values
    set(findobj("tag", "tag_beta_str"), "string", msprintf("%0.3e", betaf)); 
    set(findobj("tag", "tag_gamma_str"), "string", msprintf("%0.3e", gammaf));
    
 
    current_axis=gca();
    
    fitdata=(alphaf*sqrt(reffreqs)+betaf*reffreqs+gammaf*reffreqs^2);
       
    current_axis.children(1).children.data(:,2)=fitdata';       // Compute and plot new curve fit data
    
    current_figure.immediate_drawing="on";
                  
    
endfunction


///////////////////
// Plot ILD
///////////////////

function [ILD_loss, ILD_fscale]=plot_ILD(reffreqs, fitdata)
   

       ILD_loss=evstr(get(findobj("tag", "tag_ILD_loss_edit"), "string"));
       ILD_fscale=evstr(get(findobj("tag", "tag_ILD_fscale_edit"), "string"))/100;
       
       if(ILD_loss <= 0) then
           messagebox("ILD loss must be a positive value. Script aborted", "","error","Abort");
           delete(gcf())      
           abort;
       end     
       
      if(ILD_fscale > 1) | (ILD_fscale < 0) then
           messagebox("ILD scale factor must be at least 0 and at most 100%. Script aborted", "","error","Abort");      
           delete(gcf());
           abort;
       end         
       
        
       current_figure=gcf();
    
       current_figure.immediate_drawing="off";
            
       
       current_axis=gca();                                     // Turn on ILD lines
       
       current_axis.children(3).visible="on";
       current_axis.children(4).visible="on";
                                                              // Compute ILD region
       upper_fitdata=fitdata+ILD_loss*(1+ILD_fscale*reffreqs/1e9);
                       
       upper_fitdata(upper_fitdata>(0))=0;      // Clip upper ILD region
                
       lower_fitdata=fitdata-ILD_loss*(1+ILD_fscale*reffreqs/1e9);;
              
       
       current_axis.children(3).children.data(:,2)=lower_fitdata';
       current_axis.children(4).children.data(:,2)=upper_fitdata'; 
       
                                                              // Rescale plot if necessary
       x_min=current_axis.data_bounds(1,1);                                                                                                               
       y_min=current_axis.data_bounds(1,2);                                                                                                               
       x_range=current_axis.data_bounds(2,1);                                                                                                               
       y_range=current_axis.data_bounds(2,2);                                                                                                                      
       // Get current ranges
       
       
       // Recheck the the range and rescale as necessary
       y_range=min(y_range, floor(min(lower_fitdata)));
       
      // Refresh plot       
       replot([x_min, y_range ,x_range, 0]);             
       
       current_figure.immediate_drawing="on";
endfunction


///////////////////
// Output touchstone
///////////////////

function write_touchstone(reffreqs, fitdata, initdata)

    messagebox("Write s2p!");    
    
endfunction






// ======================   S-params Converter ====================
// 
// (Semi)Intelligent Differential S-param Viewer
// 
//  Diff port mode selection GUI
//
// (c)2014  L. Rayzman
//
//  GUI interface based on UICONTROL2 GUI demo
//
// Created      : 06/23/2014
// Last Update  : 

//
// ====================================================================
// ====================================================================

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////
// Button Handlers
///////////////////           


// Sequential Buttons handler
function on_df_button_seq_click(fig, handles)
    
    global smapmode;

    
    smapmode = 2;
    
    delete(fig);  // delete figure

endfunction

// Odd/Even Buttons handler
function on_df_button_OE_click(fig, handles)
    
    global smapmode;
    
    smapmode = 1;
    
    delete(fig);  // delete figure
 
endfunction



///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

///////////////////
// Diff Mode Sel GUI
///////////////////



diff_mode_fig = figure("figure_id", diff_mode_fig_idx, ...
                        "dockable", "off" ,... 
                        "infobar_visible", "off", ...
                        "toolbar_visible", "off", ...
                        "menubar_visible", "off", ... 
                        "resize", "off", ... 
                        "position", [200 200 450 300], ...
                        "figure_name", "Select diff pair mapping mode");
                        
drawlater();                        

diff_mode_fig_handles.df_lbl_main=uicontrol(diff_mode_fig, ... 
                                       "style", "text", ...
                                       "string", "Unable to guess port mapping. Please select the port mapping mode", ...
                                       "position", [15 275 420 30], ...
                                       "BackgroundColor", [0.8 0.8 0.8], ...
                                       "FontSize", 14);

diff_mode_fig_handles.df_button_seq=uicontrol(diff_mode_fig,...
                                              "style", "pushbutton", ...
                                              "icon", ".\Pics\PortMapping_Seq.gif", ...
                                              "position", [5 40 220 224], ...
                                              "callback", "on_df_button_seq_click(diff_mode_fig, diff_mode_fig_handles)");

diff_mode_fig_handles.df_button_OE=uicontrol(diff_mode_fig,...
                                              "style", "pushbutton", ...
                                              "icon", ".\Pics\PortMapping_OE.gif", ...
                                              "position", [230 40 220 224], ...
                                              "callback", "on_df_button_OE_click(diff_mode_fig, diff_mode_fig_handles)");
                                              
diff_mode_fig_handles_df_lbl_seqbut=uicontrol(diff_mode_fig,...
                                              "style", "text", ...
                                              "string", "Sequential",...
                                              "position", [90 10 100 30], ...
                                              "BackgroundColor", [0.8 0.8 0.8], ...
                                              "FontSize", 12);                                                                                          


diff_mode_fig_handles_df_lbl_oebut=uicontrol(diff_mode_fig,...
                                              "style", "text", ...
                                              "string", "Odd/Even",...
                                              "position", [315 10 100 30], ...
                                              "BackgroundColor", [0.8 0.8 0.8], ...
                                              "FontSize", 12);    
                                              

drawnow();



                   
















// ======================   S-params Converter ====================
// 
// (Semi)Intelligent Viewer
//
// (c)2014  L. Rayzman
//
//  See "Generalized Mixed-Mode S-parameters" 
//       A. Ferroro, M. Pirola, IEEE 2006
//  
//
//
//  GUI interface based on UICONTROL2 GUI demo
//
// Created      : 02/25/2014
// Last Update  : 03/18/2014   - Added user interaction in case can't guess
//                               port mapping
//
//
// TODO:  Debug group-delay calculation to deal with phase discontinuities
//        resulting in large GD steps
// ====================================================================
// ====================================================================

clear;	

stacksize(200*1024*1024);

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////Unwrap Matlab Emulation function///////////////////////////////
function unwrp = unwrap(wrapped)

//
//  Emulation of Matlab unwrap function which adjust largest deviation
//  between adjacent phase entries to maximum of +pi or -pi
//
// Inputs:
//        wrapped - wrapped phase vector. Must be 1-D vector with at least 2 entries
//
//  Outputs:
//        unrwp -  unwrapped phase vector
//
//
// TODO: Implement a multi-dimensional vector unwrapping
//

vect_size = size(wrapped);


if vect_size(2) == 1 then           //Transpose row  vector into column vector, if necessary              
  wrapped = wrapped';
else
  wrapped = wrapped;
end


lngth = size(wrapped,2);

//Set the phase at first entry
unwrp(1) = wrapped(1);

//Main loop
for i = 2:lngth,
    k = 0;                                                  //Reset multiplier
    ph_delta = wrapped(i) - unwrp(i-1);                      
    if abs(ph_delta) > %pi then                             //If phase jump is greater than Pi
        if ph_delta < 0 then                                //If negative phase jump
            k = round(abs(ph_delta)/(2*%pi));
        else                                                //If positive phase jump                        
            k = -round(abs(ph_delta)/(2*%pi));
        end
    end
     unwrp(i) = wrapped(i) + 2*k*%pi;                       //Adjust phase by factor of k*2pi 
end


unwrp=unwrp';

endfunction


///////////////////////////////////////////////////////////////////////////////
frefsparam = emptystr();                        // Filename of inputfile

global spreffreqs;
spreffreqs=[];                                  // Inputfile frequency points vector
sprefdata=[];                                   // Inputfile S-param matrix data

global spdata;
spdata=[];                                      // Converted s-param matrix data

global numofports;
global numofreqs;
numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

entries_choice=emptystr();                      // Text matrix that describes available entries to view
entry_idx=0;                                    //  

M=[];                                           // Transformation matrix


global smapmode
smapmode=0;                                     // SxP mapping mode
                                                //  1 ==> 1-------- 2   (Odd Mapping)
                                                //        3-------- 4
                                                // 
                                                //  
                                                //  2 ==> 1 ------- n/2+1 (Even Mapping)
                                                //        2 ------- n/2+2
                                                
           
smixmode=0;                                     // Output matrix mode
                                                // 1  => SDD
                                                // 2  => SDC
                                                // 3  => SCD
                                                // 4  => SCC                                                
                                                
srow=1;                                         // Set the Sxy to plot
scol=1;
spdata_row_col=[];                              // Data points from Sxy where x=row y=col

bDetIl=%t;                                      // Insertion loss detection flag

///////////////////////////////////////////////////////////////////////////////

gui_frame_w = 300;                              // Frame width
gui_frame_h = 500;                              // Frame height


gui_margin_x = 15;                              // Horizontal margin between each element
gui_margin_y = 15;                              // Vertical margin between each element

gui_padding_x = 10;                             // Horizontal padding between each element
gui_padding_y = 10;                             // Vertical padding between each element

gui_button_w = 100;                             // Button width
gui_button_h = 30;                              // Button height

gui_defaultfont = "arial";                      // Default font
gui_subframe_font_size = 12;                    // Title font size (rotation angle, colormap,...)
gui_text_font_size = 11;                        // Text font size




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
    abort;
end

disp(strcat(["Info: Begin loading touchstone file " frefsparam]));

[spreffreqs,sprefdata] =sptlbx_readtchstn(frefsparam);

disp("Info: Finished loading touchstone file");

numofports=size(sprefdata,1);                                               //Find number of ports

if numofports < 4 then
    messagebox("Only 4-port or larger S-parameters are allowed. Script aborted", "","error","Abort");      
    abort;
end

if modulo(numofports,2) <> 0 then
    messagebox("Only even port-count S-parameters are allowed. Script aborted", "","error","Abort");      
    abort;
end

numofreqs=size(sprefdata,3);                                                //Find number of frequency points

///////////////////
// Estimate the port mapping
///////////////////

//
// Check Odd mapping
//
//
TempM=[];
   for i = 1:numofports/2
       // Copy to a temp
       for k=1:numofreqs
           TempM(k)=sprefdata(2*i-1, 2*i,k);
       end
       // Check the criteria
           // Take derivative and Check that average slope value is positive 
           if (abs(TempM(1)) < 0.9)  then
               bDetIl = %f;
               break;
           end
   end
TempM=[];

//
//  If not odd mapping, check even mapping
//
//

   if ~bDetIl  then
        bDetIl=%t;
         for i = 1:numofports/2
         // Copy to a temp
          for k=1:numofreqs
             TempM(k)=sprefdata(i,i+numofports/2,k);
          end
           // Check the criteria
           // Take derivative and Check that average slope value is positive 
           if (abs(TempM(1)) < 0.9) then
               bDetIl = %f;
               break;
           end
        end
         if bDetIl then
             smapmode=2;       // If got to here, then it is even mapping

         end
   else
         smapmode=1;       // If found all alreday, then it was odd mapping
   end
 
clear TempM;
//
//  Report Mapping
//
//

if smapmode==0 then
     // Ask user to select mode
    smapmode=x_choices('',list(list('Port map mode:',1,['Odd','Even'])));
end   
    
if smapmode==1 then
    disp("Info: Odd differential port mapping")
    disp("Info: Applying port remapping")
elseif smapmode==2 then
   disp("Info: Even differential port mapping")
else
    messagebox("Unable to determine differential port mapping. Script aborted", "","error","Abort");      
    abort;
end

    

/////////////////////////////
//
// Perform Mixed-mode conversion
//
/////////////////////////////

//
//  Compute mixed-mode permutation/reorder matrix
//
l=[1:1:numofports/2];

Pda=zeros(numofports/2,2*numofports);
Pca=zeros(numofports/2,2*numofports);
Pdb=zeros(numofports/2,2*numofports);
Pcb=zeros(numofports/2,2*numofports);

for i=l
    Pda(i, 4*i-3)=1;
    Pca(i, 4*i-1)=1;
    Pdb(i, 4*i-2)=1;
    Pcb(i, 4*i)=1;        
end

P=[Pda;Pca;Pdb;Pcb];                                                          

//
//  Compute mixed-mode wave state conversion matrix
//
//
M=sqrt(2)*[1 0 -1 0; 0 1 0 -1; 1 0 1 0; 0 1 0 1];                                   

Ksi=zeros(numofports,numofports);

for i=1:numofports/2
    Ksi((i-1)*4+1:(i-1)*4+4,(i-1)*4+1:(i-1)*4+4)=M;
end

//
//  Compute single-ended permutation/reorder matrix
//
//

Qa=zeros(numofports,2*numofports);
Qb=zeros(numofports,2*numofports);

for i=1:numofports
    Qa(i, 2*i-1)=1;
    Qb(i, 2*i)=1;
end

Qt=[Qa;Qb]';

KsiTilde=P*Ksi*Qt;                                                         
clear P;
clear Ksi;
clear Qt;


//
// Extract S-param mixed-mode conversion matrix and it's inverse
//

M=KsiTilde(1:numofports,1:numofports);                          
clear EpsTilde;
Minv=inv(M);                                                    

//
//  Compute mixed-mode s-params
//
//

spdata=sprefdata;

R=zeros(numofports,numofports);
k=zeros(1,numofports);

if smapmode==1 then
    // Create row permuation matrix and index vector


    R(1,1)=1;
    R(numofports,numofports)=1;
    
    k(1)=1;
    k(numofports)=numofports;
    
    for i=2:numofports-1
        if i<= numofports/2 then   //lower ports -> odd
          R(i,2*i-1)=1;
        else                       //upper ports -> even
          R(i,(i-numofports/2)*2)=1;
        end
        k(i)=modulo(i-1,2)*(numofports/2)+ceil(i/2);
    end

end


for i=1:numofreqs
    // Set port order to even mapping (canonincal) form
    if smapmode==1 then    // Odd mapping
        
        // First port
        spdata(:,1,i)=R*sprefdata(:,1,i);
                   
        // Second through second to last port
        for j=2:numofports-1
            
            // Apply row permutation matrix on original column
            // and put into new column
             spdata(:,k(j),i)=R*sprefdata(:,j,i);
            
        end
        // Last port
        spdata(:,numofports,i)=R*sprefdata(:,numofports,i);

    end
     // Apply the mixed-mode conversion    
     spdata(:,:,i)=M*spdata(:,:,i)*Minv; 
end

clear sprefdata;
clear M;
clear Minv;


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


///////////////////
// Viewer GUI
///////////////////

//
// Figure creation
//
//

gui_axes_w          = 3*gui_margin_x + gui_frame_w;                    // Axes width
gui_axes_h          = 2*gui_margin_y + gui_frame_h;                    // Axes height

viewer_fig = scf(0);

global plot_fig;
global plot_fig_idx;

plot_fig_idx = 1;

drawlater();

// Remove default Scilab graphics menus and toolbar

delmenu(viewer_fig.figure_id, gettext("&File"));
delmenu(viewer_fig.figure_id, gettext("&Tools"));
delmenu(viewer_fig.figure_id, gettext("&Edit"));
delmenu(viewer_fig.figure_id, gettext("&?"));
toolbar(viewer_fig.figure_id, "off");

viewer_fig.background =  -2;
viewer_fig.color_map = jetcolormap(128);
viewer_fig.figure_position = [0 0];
viewer_fig.figure_name = gettext("SxP Main GUI");

// Create File menu

gui_menu = uimenu("parent", viewer_fig, "label", gettext("File"));

uimenu ("parent", gui_menu, "label",                                           ..
        "Close", "tag", "close_menu",                                          ..
        "callback", "viewer_fig=get_figure_handle(0);delete(viewer_fig);");

sleep(500);

viewer_fig.axes_size   = [gui_axes_w gui_axes_h];

viewer_handles.dummy = 0;

//
// Plot Control Frame
//
//

viewer_handles.viewer_frame = uicontrol( ...
                          "parent", viewer_fig, ...
                          "relief", "groove", ...
                          "style", "frame", ...
                          "units", "pixels", ...
                          "position", [gui_margin_x gui_margin_y gui_frame_w gui_frame_h], ...
                          "horizontalalignment", "center", ...
                          "background", [1 1 1],...
                          "tag", "frame_control");
                          
                          
viewer_handles.viewer_frame_title = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "text", ...
                                "string", "Plot Controls", ...
                                "units", "pixels", ...
                                "position", [ 30+gui_margin_x gui_margin_y+gui_frame_h-10 gui_frame_w-60 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 14, ...
                                "horizontalalignment", "center", ...
                                "background", [1 1 1], ...
                                "tag", "title_plot_control");
                                
                                
                                

//
// Victim Port Frame
//
//

viewer_handles.viewer_frame_victim = uicontrol( ...
                          "parent", viewer_fig, ...
                          "relief", "groove", ...
                          "style", "frame", ...
                          "units", "pixels", ...
                          "position", [30+gui_margin_x gui_margin_y+gui_frame_h-100 gui_frame_w-60 80], ...
                          "horizontalalignment", "center", ...
                          "background", [1 1 1],...
                          "tag", "frame_victim");
                          
                          
viewer_handles.viewer_frame_vict_title = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "text", ...
                                "string", "Victim Ports", ...
                                "units", "pixels", ...
                                "position", [40+gui_margin_x gui_margin_y+gui_frame_h-30 gui_frame_w-80 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "horizontalalignment", "center", ...
                                "background", [1 1 1], ...
                                "tag", "title_victim_ports");
                                
// Generate ports list
portslist=emptystr();

if smapmode==1 then    // Odd mapping
    for i=1:(numofports/4)
        portslist(i)=strcat([string((i-1)*4+1) "," string((i-1)*4+3)]);
    end
    for i=1:(numofports/4)
        portslist(i+numofports/4)=strcat([string((i-1)*4+2) "," string((i-1)*4+4)]);
    end    
    
elseif smapmode==2 then         // Even mapping
    for i=1:(numofports/2)
        portslist(i)=strcat([string((i-1)*2+1) "," string((i-1)*2+2)]);
    end
    
   
end

           
                                
viewer_handles.viewer_list_inports =  uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "listbox", ...
                                "units", "pixels", ...
                                "position", [70+gui_margin_x gui_margin_y+gui_frame_h-88 50 40], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "horizontalalignment", "right", ...
                                "background", [1 1 1], ...
                                "string", portslist,...
                                "value", 1, ..
                                "ListboxTop", 1, ...
                                "Max", [0], ...
                                "Min", [0], ...                                
                                "tag", "listbox_inports", ...
                                "callback", "on_inportslist_click(viewer_handles)");
                                
viewer_handles.viewer_text_inports =  uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "text", ...
                                "units", "pixels", ...
                                "string", "Input Ports", ...                                
                                "position", [65+gui_margin_x gui_margin_y+gui_frame_h-48 50 19], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 11, ...
                                "horizontalalignment", "center", ...
                                "background", [1 1 1], ...
                                "tag", "text_inports");   
                                

                                
viewer_handles.viewer_list_outports =  uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "listbox", ...
                                "units", "pixels", ...
                                "position", [180+gui_margin_x gui_margin_y+gui_frame_h-88 50 40], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "horizontalalignment", "right", ...
                                "background", [1 1 1], ...
                                "string", portslist,...
                                "ListboxTop", numofports/4+1, ...                                
                                "value", numofports/4+1, ..
                                "Max", [0], ...
                                "Min", [0], ...                                                                
                                "tag", "listbox_outports", ...
                                "callback_type", 0, ...
                                "callback", "on_outportslist_click(viewer_handles)");
                                
viewer_handles.viewer_text_outports =  uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "text", ...
                                "units", "pixels", ...
                                "string", "Output Ports", ...                                
                                "position", [170+gui_margin_x gui_margin_y+gui_frame_h-48 60 19], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 11, ...
                                "horizontalalignment", "center", ...
                                "background", [1 1 1], ...
                                "tag", "text_outports");          


// Input and Output Ports selection handlers
function on_inportslist_click(handles)
    
    
    global numofports;
    // Get current value
    idx=handles.viewer_list_inports.Value;
    
        
    // Figure out idx of the output port
    
    if idx <= numofports/4 then
        idx = idx + numofports/4;
    else
        idx = idx - numofports/4;
    end
    
    // Update inports list    
    handles.viewer_list_outports.Value = idx;    
    handles.viewer_list_outports.ListboxTop = idx;
endfunction

function on_outportslist_click(handles)
    
    global numofports;
    
    // Get current value
    idx=handles.viewer_list_outports.Value;
        
    // Figure out idx of the input port
    
    if idx <= numofports/4 then
        idx = idx + numofports/4;
    else
        idx = idx - numofports/4;
    end
    
    // Update inports list
    handles.viewer_list_inports.ListboxTop = idx;
    handles.viewer_list_inports.Value = idx;

endfunction



//
// Plot Mode Frame
//
//

function on_radioIL_click(handles)
    handles.viewer_frame_RadioIL.Value = 1;
    handles.viewer_frame_RadioRLIN.Value = 0;
    handles.viewer_frame_RadioRLOUT.Value = 0;
    handles.viewer_frame_RadioNEXT.Value = 0;
    handles.viewer_frame_RadioFEXT.Value = 0;
  //  handles.viewer_frame_checkGD.Enable = "on";
  //  handles.viewer_frame_checkGD.ForegroundColor = [0 0 0];
endfunction



function on_radioRLIN_click(handles)
    handles.viewer_frame_RadioIL.Value = 0;
    handles.viewer_frame_RadioRLIN.Value = 1;
    handles.viewer_frame_RadioRLOUT.Value = 0;
    handles.viewer_frame_RadioNEXT.Value = 0;
    handles.viewer_frame_RadioFEXT.Value = 0;
 //   handles.viewer_frame_checkGD.Enable = "off";
 //   handles.viewer_frame_checkGD.ForegroundColor = [0.6 0.6 0.6];
endfunction


function on_radioRLOUT_click(handles)
    handles.viewer_frame_RadioIL.Value = 0;
    handles.viewer_frame_RadioRLIN.Value = 0;
    handles.viewer_frame_RadioRLOUT.Value = 1;
    handles.viewer_frame_RadioNEXT.Value = 0;
    handles.viewer_frame_RadioFEXT.Value = 0;
  //  handles.viewer_frame_checkGD.Enable = "off";
  //  handles.viewer_frame_checkGD.ForegroundColor = [0.6 0.6 0.6];    
endfunction


function on_radioNEXT_click(handles)
    handles.viewer_frame_RadioIL.Value = 0;
    handles.viewer_frame_RadioRLIN.Value = 0;
    handles.viewer_frame_RadioRLOUT.Value = 0;
    handles.viewer_frame_RadioNEXT.Value = 1;
    handles.viewer_frame_RadioFEXT.Value = 0;
  //  handles.viewer_frame_checkGD.Enable = "off";
  //  handles.viewer_frame_checkGD.ForegroundColor = [0.6 0.6 0.6];    
    
endfunction

function on_radioFEXT_click(handles)
    handles.viewer_frame_RadioIL.Value = 0;
    handles.viewer_frame_RadioRLIN.Value = 0;
    handles.viewer_frame_RadioRLOUT.Value = 0;
    handles.viewer_frame_RadioNEXT.Value = 0;
    handles.viewer_frame_RadioFEXT.Value = 1;
  //  handles.viewer_frame_checkGD.Enable = "off";
  //  handles.viewer_frame_checkGD.ForegroundColor = [0.6 0.6 0.6];    
    
endfunction

viewer_handles.viewer_frame_plotmode = uicontrol( ...
                          "parent", viewer_fig, ...
                          "relief", "groove", ...
                          "style", "frame", ...
                          "units", "pixels", ...
                          "position", [30+gui_margin_x gui_margin_y+gui_frame_h-220 gui_frame_w-60 100], ...
                          "horizontalalignment", "center", ...
                          "background", [1 1 1],...
                          "tag", "frame_");
                          
                          
viewer_handles.viewer_frame_pmde_title = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "text", ...
                                "string", "Plot Mode", ...
                                "units", "pixels", ...
                                "position", [40+gui_margin_x gui_margin_y+gui_frame_h-135 gui_frame_w-80 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "horizontalalignment", "center", ...
                                "background", [1 1 1], ...
                                "tag", "title_plot_mode");
                                
viewer_handles.viewer_frame_RadioIL = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "radiobutton", ...
                                "string", "IL", ...
                                "units", "pixels", ...
                                "position", [60+gui_margin_x gui_margin_y+gui_frame_h-155 gui_frame_w-120 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "VerticalAlignment", "middle", ...
                                "HorizontalAlignment","left", ...                                
                                "background", [1 1 1], ...
                                "Value", 1, ...                                
                                "tag", "radio_IL", ...
                                "Callback", "on_radioIL_click(viewer_handles)");             

viewer_handles.viewer_frame_RadioRLIN = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "radiobutton", ...
                                "string", "RL IN", ...
                                "units", "pixels", ...
                                "position", [60+gui_margin_x gui_margin_y+gui_frame_h-155-gui_margin_y-gui_padding_y gui_frame_w-220 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "VerticalAlignment", "middle", ...
                                "HorizontalAlignment","left", ...                                
                                "background", [1 1 1], ...
                                "Value", 0, ...                                
                                "tag", "radio_RLIN", ...
                                "Callback", "on_radioRLIN_click(viewer_handles)");        
                                
viewer_handles.viewer_frame_RadioRLOUT = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "radiobutton", ...
                                "string", "RL OUT", ...
                                "units", "pixels", ...
                                "position", [60+gui_margin_x gui_margin_y+gui_frame_h-155-2*(gui_margin_y+gui_padding_y) gui_frame_w-220 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "VerticalAlignment", "middle", ...
                                "HorizontalAlignment","left", ...
                                "background", [1 1 1], ...
                                "Value", 0, ...                                
                                "tag", "radio_RLOUT", ...
                                "Callback", "on_radioRLOUT_click(viewer_handles)");        
                                
viewer_handles.viewer_frame_RadioNEXT = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "radiobutton", ...
                                "string", "NEXT", ...
                                "units", "pixels", ...
                                "position", [160+gui_margin_x  gui_margin_y+gui_frame_h-155 gui_frame_w-220 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "VerticalAlignment", "middle", ...
                                "HorizontalAlignment","left", ...                                
                                "background", [1 1 1], ...
                                "Value", 0, ...                                
                                "tag", "radio_NEXT", ...
                                "Callback", "on_radioNEXT_click(viewer_handles)");    

viewer_handles.viewer_frame_RadioFEXT = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "radiobutton", ...
                                "string", "FEXT", ...
                                "units", "pixels", ...
                                "position", [160+gui_margin_x  gui_margin_y+gui_frame_h-155-gui_margin_y-gui_padding_y gui_frame_w-220 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "VerticalAlignment", "middle", ...
                                "HorizontalAlignment","left", ...                                
                                "background", [1 1 1], ...
                                "Value", 0, ...                                
                                "tag", "radio_FEXT", ...
                                "Callback", "on_radioFEXT_click(viewer_handles)");  
                                
viewer_handles.viewer_frame_checkGD = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "checkbox", ...
                                "string", "Group Delay", ...
                                "units", "pixels", ...
                                "position", [160+gui_margin_x  gui_margin_y+gui_frame_h-155-2*(gui_margin_y+gui_padding_y) gui_frame_w-200 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "VerticalAlignment", "middle", ...
                                "HorizontalAlignment","left", ...                                
                                "background", [1 1 1], ...
                                "ForegroundColor", [0.6 0.6 0.6], ...
                                "Value", 0, ... 
                                "Enable", "off", ...                               
                                "tag", "check_GD");                                  
                                

if numofports==4 then
    viewer_handles.viewer_frame_RadioNEXT.Enable=0;
    viewer_handles.viewer_frame_RadioNEXT.ForegroundColor=[0.6 0.6 0.6];
    viewer_handles.viewer_frame_RadioFEXT.Enable=0;    
    viewer_handles.viewer_frame_RadioFEXT.ForegroundColor=[0.6 0.6 0.6];    
end



//
// SxP MixMode Frame
//
//

function on_radioSDD_click(handles)
    handles.viewer_frame_RadioSDD.Value = 1;
    handles.viewer_frame_RadioSDC.Value = 0;
    handles.viewer_frame_RadioSCD.Value = 0;    
    handles.viewer_frame_RadioSCC.Value = 0;        
endfunction

function on_radioSDC_click(handles)
    handles.viewer_frame_RadioSDD.Value = 0;
    handles.viewer_frame_RadioSDC.Value = 1;
    handles.viewer_frame_RadioSCD.Value = 0;    
    handles.viewer_frame_RadioSCC.Value = 0;        
endfunction

function on_radioSCD_click(handles)
    handles.viewer_frame_RadioSDD.Value = 0;
    handles.viewer_frame_RadioSDC.Value = 0;
    handles.viewer_frame_RadioSCD.Value = 1;    
    handles.viewer_frame_RadioSCC.Value = 0;        
endfunction

function on_radioSCC_click(handles)
    handles.viewer_frame_RadioSDD.Value = 0;
    handles.viewer_frame_RadioSDC.Value = 0;
    handles.viewer_frame_RadioSCD.Value = 0;    
    handles.viewer_frame_RadioSCC.Value = 1;        
endfunction



viewer_handles.viewer_frame_mxmode = uicontrol( ...
                          "parent", viewer_fig, ...
                          "relief", "groove", ...
                          "style", "frame", ...
                          "units", "pixels", ...
                          "position", [30+gui_margin_x gui_margin_y+gui_frame_h-310 gui_frame_w-60 70], ...
                          "horizontalalignment", "center", ...
                          "background", [1 1 1],...
                          "tag", "frame_mixemode");
                          
                          
viewer_handles.viewer_frame_mxmode_ttl = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "text", ...
                                "string", "Mixed Mode", ...
                                "units", "pixels", ...
                                "position", [40+gui_margin_x gui_margin_y+gui_frame_h-250 gui_frame_w-80 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "horizontalalignment", "center", ...
                                "background", [1 1 1], ...
                                "tag", "title_mixmode");


viewer_handles.viewer_frame_RadioSDD = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "radiobutton", ...
                                "string", "SDD", ...
                                "units", "pixels", ...
                                "position", [60+gui_margin_x gui_margin_y+gui_frame_h-275 gui_frame_w-120 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "VerticalAlignment", "middle", ...
                                "HorizontalAlignment","left", ...                                
                                "background", [1 1 1], ...
                                "Value", 1, ...                                
                                "tag", "radio_SDD", ...
                                "Callback", "on_radioSDD_click(viewer_handles)"); 
                                
viewer_handles.viewer_frame_RadioSCD = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "radiobutton", ...
                                "string", "SCD", ...
                                "units", "pixels", ...
                                "position", [60+gui_margin_x gui_margin_y+gui_frame_h-275-gui_margin_y-gui_padding_y gui_frame_w-120 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "VerticalAlignment", "middle", ...
                                "HorizontalAlignment","left", ...                                
                                "background", [1 1 1], ...
                                "Value", 0, ...                                
                                "tag", "radio_SCD", ...
                                "Callback", "on_radioSCD_click(viewer_handles)");                   
                                
viewer_handles.viewer_frame_RadioSDC = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "radiobutton", ...
                                "string", "SDC", ...
                                "units", "pixels", ...
                                "position", [160+gui_margin_x gui_margin_y+gui_frame_h-275 gui_frame_w-220 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "VerticalAlignment", "middle", ...
                                "HorizontalAlignment","left", ...                                
                                "background", [1 1 1], ...
                                "Value", 0, ...                                
                                "tag", "radio_SDC", ...
                                "Callback", "on_radioSDC_click(viewer_handles)");     
                                
viewer_handles.viewer_frame_RadioSCC = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "radiobutton", ...
                                "string", "SCC", ...
                                "units", "pixels", ...
                                "position", [160+gui_margin_x gui_margin_y+gui_frame_h-275-gui_margin_y-gui_padding_y gui_frame_w-220 20], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 12, ...
                                "VerticalAlignment", "middle", ...
                                "HorizontalAlignment","left", ...                                
                                "background", [1 1 1], ...
                                "Value", 0, ...                                
                                "tag", "radio_SCC", ...
                                "Callback", "on_radioSCC_click(viewer_handles)");                                                                              


//
// Plot Button
//
//                                

viewer_handles.viewer_button_Plot = uicontrol (...
                                "parent", viewer_fig, ...
                                "style", "pushbutton", ...
                                "string", "Plot", ...
                                "units", "pixels", ...
                                "position", [80+gui_margin_x gui_margin_y+gui_padding_y gui_frame_w-160 40], ...
                                "fontname", gui_defaultfont, ...
                                "fontunits", "points", ...
                                "fontsize", 14, ...
                                "HorizontalAlignment","center", ...                                
                                "background", [0.8 0.8 0.8], ...
                                "ForegroundColor", [0 0 0], ...
                                "tag", "button_plot", ..
                                "Callback", "on_buttonPlot_click(viewer_handles)");          
                                
drawnow();

///////////////////
// Main Plotting Function
///////////////////

function on_buttonPlot_click(handles)
    
    global numofports;
    global numofreqs;

    global smapmode;
    global spreffreqs;
    global spdata;
    
    
    bdBPlotEn = %t;                                        // Flag to allow things to plot
    
    sHzPrefix=emptystr();                                  // Frequency scaling text prefix
    freqscalar=1;                                          // Frequency scalar
    
    sGDPrefix=emptystr();                                  // Group delay scaling text prefix
    gdtimescalar=1;                                        // Group delay
    
    colormapidx=[2 3 5 6 14 20 27];                        // Index of available plot colors
    
    titletext_plotmode=emptystr();                        // Title plot mode string
    titletext_mxmode=emptystr();                          // Title mixed mode string
    
    plot_data=zeros(numofports/4,numofreqs);             // Storage for data to be plotted
    
    smm_row_offset=0;                                    // Mixed mode matrix quadrant offsets
    smm_col_offset=0;                                    
    
    smm_idx=zeros(numofports/4,2);                      // Indices of mixed mode parameters to group plot
        
    victim_in_idx=handles.viewer_list_inports.Value;       // Victim pair input port index
    victim_out_idx=handles.viewer_list_outports.Value      // Victim pair input port index
    
  
    gui_plot_w  = 1000;                              // Plot width
    gui_plot_h  = 600;                             // Plot height

  

    
    // Get mixed mode matrix offsets associated with display mode
    if handles.viewer_frame_RadioSDD.Value == 1 then
            smm_row_offset=0;
            smm_col_offset=0;
            titletext_mxmode="SDD";            
    elseif handles.viewer_frame_RadioSDC.Value == 1 then
            smm_row_offset=0;
            smm_col_offset=numofports/2;
            titletext_mxmode="SDC";            
    elseif handles.viewer_frame_RadioSCD.Value == 1 then
            smm_row_offset=numofports/2;
            smm_col_offset=0;
            titletext_mxmode="SCD";            
    elseif handles.viewer_frame_RadioSCC.Value == 1 then            
            smm_row_offset=numofports/2;
            smm_col_offset=numofports/2;        
            titletext_mxmode="SCC";            
    end
    
    
    // Compile list of mixed-mode port indices
    for i=1:numofports/4
   
        // Insertion Loss
        if handles.viewer_frame_RadioIL.Value == 1  then
            titletext_plotmode="IL";
            // "left" ports
            if victim_in_idx  <= numofports/4 then
               // numofports/4+1,1  , numofports/4+2,2, etc.
               smm_idx(i,1)=i+numofports/4+smm_row_offset;
               smm_idx(i,2)=i+smm_col_offset;               
            
            // "right" ports
            else            
              // 1, numofports/4+1  , 2, numofports/4+2, etc.
               smm_idx(i,1)=i+smm_row_offset;
               smm_idx(i,2)=i+numofports/4+smm_col_offset;               
            end
                   
        // RL IN
        elseif handles.viewer_frame_RadioRLIN.Value == 1 then
             titletext_plotmode="RL IN"
            // "left" ports
            if victim_in_idx <= numofports/4 then
                 // 11, 22,  33, ,,, numofports/4-1
               smm_idx(i,1)=i+smm_row_offset;
               smm_idx(i,2)=i+smm_col_offset;        
            
            // "right" ports
            else
               // numofports/4, numofports/4+1, etc.
               smm_idx(i,1)=i+numofports/4+smm_row_offset;
               smm_idx(i,2)=i+numofports/4+smm_col_offset;                       
            end

        
        // RL OUT
        elseif handles.viewer_frame_RadioRLOUT.Value == 1 then        
             titletext_plotmode="RL OUT"
            // "left" ports
            if victim_in_idx <= numofports/4 then
               // numofports/4, numofports/4+1, etc.
               smm_idx(i,1)=i+numofports/4+smm_row_offset;
               smm_idx(i,2)=i+numofports/4+smm_col_offset;                  
            
            // "right" ports
            else
               // 11, 22,  33,   numofports/4-1
               smm_idx(i,1)=i+smm_row_offset;
               smm_idx(i,2)=i+smm_col_offset;                      
            end
                    
        // NEXT
        elseif handles.viewer_frame_RadioNEXT.Value == 1 then        
             titletext_plotmode="NEXT"                
            // "left" ports
            if victim_in_idx <= numofports/4 then
                     // Include the insertion loss for victim port
                     if i==(modulo(victim_in_idx-1, numofports/4)+1) then
                           smm_idx(i,1)=numofports/4+i+smm_row_offset;
                           smm_idx(i,2)=i+smm_col_offset;                             
                     else
                           smm_idx(i,1)=victim_out_idx+smm_row_offset;
                           smm_idx(i,2)=numofports/4+i+smm_col_offset;
                     end
           
            // "right" ports
        else
                     // Include the insertion loss for victim port     
                     if i==(modulo(victim_in_idx-1, numofports/4)+1) then
                           smm_idx(i,1)=i+smm_row_offset;
                           smm_idx(i,2)=numofports/4+i+smm_col_offset;                                 
                     else
                           smm_idx(i,1)=victim_out_idx+smm_row_offset;
                           smm_idx(i,2)=i+smm_col_offset;                         
                     end        
            end                      

        // FEXT
        elseif handles.viewer_frame_RadioFEXT.Value == 1 then                
             titletext_plotmode="FEXT"                           
            // "left" ports
            if victim_in_idx <= numofports/4 then
                        // Include the insertion loss for victim port            
                     if i==(modulo(victim_in_idx-1, numofports/4)+1) then
                           smm_idx(i,1)=i+numofports/4+smm_row_offset;
                           smm_idx(i,2)=i+smm_col_offset;                             
                     else
                           smm_idx(i,1)=victim_out_idx+smm_row_offset;
                           smm_idx(i,2)=i+smm_col_offset;
                     end           

            // "right" ports
            else
                      // Include the insertion loss for victim port           
                     if i==(modulo(victim_in_idx-1, numofports/4)+1) then
                           smm_idx(i,1)=i+smm_row_offset;
                           smm_idx(i,2)=i+numofports/4+smm_col_offset;                              
                     else
                           smm_idx(i,1)=victim_out_idx+smm_row_offset;
                           smm_idx(i,2)=numofports/4+i+smm_col_offset;
                     end              
            end             
         end //if
    
      end //for
 
       // Grab the data from source
       for i=1:numofreqs
                for j=1:numofports/4
                    plot_data(j,i)=spdata(smm_idx(j,1), smm_idx(j,2),i);
                end
        end
        

            
                
        // If IL and GD plot group delay of data
        if (handles.viewer_frame_RadioIL.Value == 1) & handles.viewer_frame_checkGD.Value ==1 then 
              titletext_plotmode="IL GD"                 
              for i=1:numofports/4
                  plot_data(i,1:$-1)=-diff(unwrap(atan(imag(plot_data(i,:))./real(plot_data(i,:)))))./diff(spreffreqs);
              end
        else
              for i=1:numofports/4
                   // Check that we are not plotting 20log10(0) anywhere in the data
                  if ((find(plot_data(i,:)==0))==[]) then
                        plot_data(i,:)=20*log10(plot_data(i,:));                     
                  else
                        bdBPlotEn = %f;
                  end
               end
        end
            
        //
        // Plot things
        //
        //
        if  bdBPlotEn then
            drawlater();
                // Determine frequency scalar for the plot
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
                   freqscalar=1;
                else
                   freqscalar=1;
                end
                
                // Determine time scalar for GD plot
                    
                // Create data plot window  
                global plot_fig_idx;
                plot_fig = scf(plot_fig_idx);
                plot_fig.figure_name = gettext(strcat(["SxP Plot " string(plot_fig_idx) ]));
                plot_fig_idx = plot_fig_idx + 1;
                plot_fig.axes_size = [gui_plot_w gui_plot_h];
                
                        
                        
                        
                        
                        portslist=emptystr();
                        in_idx=0;
                        out_idx=0;                
                        
                        if smapmode==1 then    // Odd mapping
                            for i=1:(numofports/4)
                                portslist(i)=strcat([string((i-1)*4+1) "," string((i-1)*4+3)]);
                            end
                            for i=1:(numofports/4)
                                portslist(i+numofports/4)=strcat([string((i-1)*4+2) "," string((i-1)*4+4)]);
                            end    
                            
                         elseif smapmode==2 then         // Even mapping
                            for i=1:(numofports/2)
                                portslist(i)=strcat([string((i-1)*2+1) "," string((i-1)*2+2)]);
                            end
                        end                
                
                // Plot
                for i=1:numofports/4
                     // If IL and GD plot group delay of data
                    if (handles.viewer_frame_RadioIL.Value == 1) & handles.viewer_frame_checkGD.Value ==1 then
                        plot2d(spreffreqs(1:$-1)/freqscalar,plot_data(i,1:$-1));
                    else // All other cases
                        plot2d(spreffreqs/freqscalar, plot_data(i,:));
                    end
                end
                
                
                // Apply pretty colors
                for i=1:numofports/4
                    
                    //Apply victim curve
                    if i==(modulo(victim_in_idx-1, numofports/4)+1) then
                      plot_fig.children.children(numofports/4-i+1,1).children.foreground=1;
                      plot_fig.children.children(numofports/4-i+1,1).children.thickness=3;                      
                    else
                      plot_fig.children.children(numofports/4-i+1,1).children.foreground=colormapidx(modulo(i-1,length(colormapidx))+1);
                    end
                end
                
//                    
                // Set axis ranges    
                    
            
                // Apply grid    
                xgrid(12);
                
                // Add X-axis label
                xlabel(strcat(["Freq (" sHzPrefix "Hz)"]));

                
                // Add Y-axis label
                
                   if (handles.viewer_frame_RadioIL.Value == 1) & handles.viewer_frame_checkGD.Value ==1 then
                      ylabel("pS");
                  
                   else
                      ylabel("(dB)");
                 
                   end
                   
                // Create title
                xtitle(strcat([titletext_plotmode " (" titletext_mxmode ")"]));
                
                xinfo(strcat(["V: " string(victim_in_idx) "[" portslist(victim_in_idx) "]-->" string(victim_out_idx) "["  portslist(victim_out_idx) "] (" string(numofports) "p)"]));          
                  
                  
                // Prettify labels
                 plot_fig.children.x_label.font_size=2;  
             //    plot_fig.children.x_label.position=[0.45 -1.25];                             
                 plot_fig.children.y_label.font_size=2;         
                 
                 plot_fig.children.title.font_size=3;
  
                
                drawnow();
                

            
        else
            messagebox("Plot data contains singularities. Unable to plot!");
        end

        
endfunction





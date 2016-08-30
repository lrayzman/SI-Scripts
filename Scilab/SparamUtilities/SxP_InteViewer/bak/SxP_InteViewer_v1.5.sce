// ======================   S-params Converter ====================
// 
// (Semi)Intelligent Differential S-param Viewer
//
// (c)2014  L. Rayzman
//
//  
//
//
//  GUI interface based on UICONTROL2 GUI demo
//
// Created      : 02/25/2014
// Last Update  : 03/18/2014   - Added user interaction in case can't guess
//                               port mapping
//                06/23/2014   - Updates against 5.5.0
//                             - Broke the code structure into multiple files
//                               for ease of management
//                             - Removed unwrapping since it has been 
//                               natively introduced into 5.5.0
//                             - Renamed port mapping modes
//                               odd -> odd/even
//                               even -> sequential
//
//
// TODO:  Debug group-delay calculation to deal with phase discontinuities
//        resulting in large GD steps
// ====================================================================
// ====================================================================

clear;	

stacksize(200*1024*1024);

exec("SxP_InteViewer_Utilities_v1.sci");          // Supporting functions/includes

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
global SxPversion;
SxPversion=1.5;                                    //Main code verision
SxPExecName="SxP_InteViewer_v1.5.sce";             // Top level script file name

                                                //
                                                // THINGS FOR FILES
                                                //                                                
global frefsparam;                                                 
frefsparam = emptystr();                        // Filename of inputfile

global spreffreqs;
spreffreqs=[];                                  // Inputfile frequency points vector
sprefdata=[];                                   // Inputfile S-param matrix data

                                                //
                                                // THINGS FOR SPARAM DATA
                                                //                                                

global spdata;
spdata=[];                                      // Converted s-param matrix data

global numofports;
global numofreqs;
numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

entries_choice=emptystr();                      // Text matrix that describes available entries to view
entry_idx=0;                                    //  


                                                //
                                                // THINGS FOR PROCESSING/DISP OF SPARAM DATA
                                                //                                                


global smapmode;
smapmode=0;                                     // SxP mapping mode
                                                //  0 ==> Unable to guess/unknown
                                                //
                                                //  1 ==> 1-------- 2   (Odd/Even Mapping)
                                                //        3-------- 4
                                                // 
                                                //  
                                                //  2 ==> 1 ------- n/2+1 (Sequential Mapping)
                                                //        2 ------- n/2+2 (Canonical form for mode conversion)
                                                
           
smixmode=0;                                     // Output matrix mode
                                                // 1  => SDD
                                                // 2  => SDC
                                                // 3  => SCD
                                                // 4  => SCC                                                
                                                

bDetIl=%t;                                      // Insertion loss detection flag

///////////////////////////////////////////////////////////////////////////////
                                                
                                                
                                                // THINGS FOR GUI/PLOTS
 
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


global diff_mode_fig;                           // Diff mode selector GUI ID
global diff_mode_fig_idx;
global diff_mode_fig_handles;
diff_mode_fig_handles.dummy = 0;
diff_mode_fig_idx=0;


global main_GUI_fig;                               // Main GUI ID
global main_GUI_fig_idx;
global main_GUI_handles;
main_GUI_handles.dummy = 0;
main_GUI_fig_idx=1;


global plot_fig;                                // Plot Figure ID
global plot_fig_idx;
plot_fig_idx = 2;


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
  if getscilabmode()=="NW" then sleep(2000); quit; end;
elseif (version(2) < 5) then
  error("Invalid Scilab version. Version 5.5 or greater is required");
  if getscilabmode()=="NW" then sleep(2000); quit; end;
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
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;      
end

disp(strcat(["Info: Begin loading touchstone file " frefsparam]));

[spreffreqs,sprefdata] =sptlbx_readtchstn(frefsparam);

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

if modulo(numofports,4) <> 0 then
    messagebox("Only even number of mixed-mode ports are currently allowed. Script aborted", "","error","Abort");      
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;  
end


numofreqs=size(sprefdata,3);                                                //Find number of frequency points

///////////////////
// Estimate the port mapping
///////////////////

//
// Check Odd/Even mapping
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
//  If not odd/even mapping, check seq
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
             smapmode=2;       // If got to here, then it is sequential mapping

         end
   else
         smapmode=1;       // If found all alreday, then it was odd/even mapping
   end
 
clear TempM;
//
//  Report Mapping
//
//

if smapmode==0 then
     // Ask user to select mode
    // exec("SxP_InteViewer_DiffModeSelGUI_v1.sci", 2);    // <==== FANCY VERSION DIDN'T  WORK
    smapmode=x_choices('',list(list('Port map mode:',1,['Odd/Even','Sequential'])));
end   
    
if smapmode==1 then
    disp("Info: Odd/Even differential port mapping found")
    disp("Info: Applying port remapping")
elseif smapmode==2 then
   disp("Info: Sequential differential port mapping found")
else
    messagebox("Unable to determine differential port mapping. Script aborted", "","error","Abort");      
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;  
end

 

/////////////////////////////
//
// Perform port remapping
// as necessary
//
/////////////////////////////

spdata=zeros(numofports,numofports, numofreqs);

if smapmode==1 then
    
R=zeros(numofports,numofports);
k=zeros(1,numofports);
    
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


        for i=1:numofreqs
            // Set port order to sequential mapping (canonincal) form
               
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
        
        sprefdata = spdata;

clear R;
clear k;
        

end



/////////////////////////////
//
// Perform Mode conversion
//
/////////////////////////////

disp("Info: Performing mode conversion")
spdata=SE2MM_CONV(sprefdata);
clear sprefdata;




///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

/////////////////////////////
//
// Evoke GUI controls
//
/////////////////////////////

exec("SxP_InteViewer_MainGUI_v1.1.sci");
sleep(100);
show_window(main_GUI_fig_idx);


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////








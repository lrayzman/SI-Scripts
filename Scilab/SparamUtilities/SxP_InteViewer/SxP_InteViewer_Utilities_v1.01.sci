//====================   S-params Viewer Functions ====================
// 
// (Semi)Intelligent Differential S-param Viewer
// 
//  Supporting Functions
//
// (c)2014  L. Rayzman
//
//  
// Created      : 06/24/2014
// Last Update  : 

//
// ====================================================================
// ====================================================================


////////////////////////////////////////////////////////////////////////////////
/////////////////////////Single-Ended To Mixed Mode Conversion//////////////////
function spmmdata = SE2MM_CONV(spsedata)

//  Performs Mixed-Mode conversion for a single-ended S-param matrix
//
//  IMPORTANT NOTE: Assumes port indexing is sequentially numbered according to
//
////  See "Generalized Mixed-Mode S-parameters" 
//       A. Ferroro, M. Pirola, IEEE 2006
//
//
//         --------------------
//    1  --| 1          n/2+1 |--  n/4+1
//       --| 2          n/2+2 |--
//         |                  |
//    2  --| 3          n/2+3 |--  n/4+2     
//       --| 4          n/2+4 |--
//         |                  |
//         |       . . .      |
//   n/4 --| n/2-1        n-1 |--  n/2
//       --| n/2            n |--
//         --------------------

// Inputs:
//        spsedata    -   Single-ended s-parameter data
//
//  Outputs:
//
//        spmmdata    -   Converted mixed-mode s-parameter data


//
//  Init
//

M=[];



//
//  Some discoveries and other things
//

numofports=size(spsedata,1);                                               //Find number of ports
numofreqs=size(spsedata,3);                                                //Find number of frequency points

spmmdata=zeros(numofports,numofports,numofreqs);
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
clear KsiTildes;
clear numofports;
clear numofreqs;
Minv=inv(M);                                                    


//
// Apply the mixed-mode conversion    
//
for i=1:numofreqs
     spmmdata(:,:,i)=M*spsedata(:,:,i)*Minv;    
end


clear M;
clear Minv;

endfunction


////////////////////////////////////////////////////////////////////////////////
/////////////////////////Mixed-Mode //////////////////
function spmmdataout = MM_ZRENORM(spmmdatain, zref_renorm, zref_orig)

//  Performs impedance renormalization on mixed-mode s-param data
//
//  Note: Function can be overloaded 
// 
//  
// See "Power Waves And Scattering Matrix"
//       K. KUROKAWA, IEEE 1965
//
//  See "User’s Guide to S-Parameters Explorer 2.0"
//       EE CIRCLE, 2010
// 
//
// Inputs:
//        spmmdatain    -   Input mixed-mode s-param data
//      zref_renorm     -   Port impedance (single-ended) to renormalize to
//        zref_orig     -   Port impedance (single-ended) associated with input s-param
//
//
//  Outputs:
//
//       spmdataout     -   Renormalized s-param data    



// Can overload
[lhs,rhs]=argn(0);
if (rhs == 2) then zref_orig=50; end;

spmmdataout=[];

// Basic error checking
if ~(isreal(zref_renorm)) | (abs(zref_renorm) <= 0)  then
    disp("MM_ZRENORM error: invalid normalizing port impedance value!");
    return;
end

// Basic error checking
if ~(isreal(zref_orig)) | (abs(zref_orig) <= 0)  then
    disp("MM_ZRENORM error: invalid original port impedance value!");
    return;
end


//
//  Some discoveries, Init and other things
//

M=[];



numofports=size(spmmdatain,1);                                               //Find number of ports
numofreqs=size(spmmdatain,3);                                                //Find number of frequency points

spmmdataout=zeros(numofports,numofports,numofreqs);


z_scalar=(zref_renorm-zref_orig)/(zref_renorm+zref_orig);                  // Resistance ratio constant



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
clear KsiTildes;
clear numofports;
clear numofreqs;

                                               




// 
// Apply renormalization
//
for i=1:numofreqs
     spmmdataout(:,:,i)=(spmmdatain(:,:,i)*M-z_scalar*M)*inv((M-z_scalar*spmmdatain(:,:,i)*M));
end


clear M;



   
endfunction
////////////////////////////////////////////////////////////////////////////////
///////////////////////////// Main Plotting Function //////////////////////////

function on_buttonPlot_click(handles)
    
    
    global frefsparam;
        
    global numofports;
    global numofreqs;

    global smapmode;
    global spreffreqs;
    global spdata;

    global plot_fig_idx;    
    
    
    //bdBPlotEn = %t;                                        // Flag to allow things to plot
    
    spdata_renorm=[];                                        // Renormalized s-param data
    
    sHzPrefix=emptystr();                                  // Frequency scaling text prefix
    freqscalar=1;                                          // Frequency scalar
    
    sGDPrefix=emptystr();                                  // Group delay scaling text prefix
    gdtimescalar=1;                                        // Group delay
    
    portz=50;                                              // Port impedance
    
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
  
  
       // Renormalize port impedances if necessary
       portz=evstr(handles.viewer_frame_pz_edit.string)
       if portz <> 50 then
           disp(strcat(["info: Renormalizing port impedances to " handles.viewer_frame_pz_edit.string " ohms"]));
           spdata_renorm=MM_ZRENORM(spdata, portz); 
       else
           spdata_renorm=spdata;           
       end
       
 
       // Grab the data from source
       for i=1:numofreqs
                for j=1:numofports/4
                    plot_data(j,i)=spdata_renorm(smm_idx(j,1), smm_idx(j,2),i);
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
                   // and set to tiny value if it's a 0
                  plot_data(i,find(plot_data(i,:)==0))=1e-300;
                  plot_data(i,:)=20*log10(plot_data(i,:));                     
               end
        end
            
        //
        // Plot things
        //
        //
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
                plot_fig = figure("figure_id", plot_fig_idx, ...
                                  "dockable", "off" ,...
                                  "toolbar_visible", "off",...
                                  "BackgroundColor", [1 1 1]);
          
                plot_fig.figure_name = gettext(strcat(["SxP InteViewer Plot " string(plot_fig_idx) ]));
                plot_fig_idx = plot_fig_idx + 1;
                plot_fig.axes_size = [gui_plot_w gui_plot_h];
                plot_fig.resize="off";
                
                        
                        
                        
                        
                        portslist=emptystr();
                        in_idx=0;
                        out_idx=0;                
                        
                        if smapmode==1 then    // Odd/Even mapping
                            for i=1:(numofports/4)
                                portslist(i)=strcat([string((i-1)*4+1) "," string((i-1)*4+3)]);
                            end
                            for i=1:(numofports/4)
                                portslist(i+numofports/4)=strcat([string((i-1)*4+2) "," string((i-1)*4+4)]);
                            end    
                            
                         elseif smapmode==2 then         // Sequential mapping

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
                
                xinfo(strcat([strcat([basename(frefsparam) fileext(frefsparam)]) " | V: " string(victim_in_idx) "[" portslist(victim_in_idx) "]-->" string(victim_out_idx) "["  portslist(victim_out_idx) "] | Z0: " string(portz) "ohms"]));          
                  
                  
                // Prettify labels
                 plot_fig.children.x_label.font_size=2;  
             //    plot_fig.children.x_label.position=[0.45 -1.25];                             
                 plot_fig.children.y_label.font_size=2;         
                 
                 plot_fig.children.title.font_size=3;
  
                
                drawnow();
                
                clear spdata_renorm;
                
        
endfunction

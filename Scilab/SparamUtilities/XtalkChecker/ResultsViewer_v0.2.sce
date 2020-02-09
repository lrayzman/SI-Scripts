//===================   Xtalk Checker Results Viewer ==================
// 
// Xtalk checker results viewer (for plotting results of Xtalk Checker
//
// (c)2015  L. Rayzman
//
// Created      : 10/14/15
// Last Update  : 10/15/15 - Added FOM threshold-based detection
//
//   
// ====================================================================
// ====================================================================


clear;	

stacksize(200*1024*1024);


////////////////////////////////// SPECIFY   /////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
                                                //
                                                // THINGS FOR CSV FILES
                                                //                                                
fcsvfiles = emptystr();                        // Filenames of results files

                                                //
                                                // THINGS FOR CSV DATA
                                                //        
csv_data=[];
fom_data_vec=[];       

                                                //
                                                // THINGS FOR RESULTS
                                                //        

results_max_fom_idx=[];


                                                //
                                                // THINGS FOR LISTINGS
                                                //        

xtalk_max_rep=3;                                // Maximum number of xtalk elements to be listed
xtalk_fom_thsld=0;                              // Minimum FOM threshold above which to list results

                    

//results_data=struct('net_name', emptystr(),...                   // results log
//                   'port_num',0,...
//                   'pin_array',emptystr(),...
//                   'port_array',[],...
//                   'xtalk_array', xtalk_struct);
                   
                   
                                                //
                                                // THINGS FOR PLOTS
                                                //        

legends_text=emptystr();                        // Label text

dot_color_vect=[2 13 5 6 12 9 19];              // Color vector

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


////////////////////////////// READ TOUCHSTONE   //////////////////////////////
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



report_mode = x_choose(['Report largest n xtalk terms';'Report all greater than a value'],['Please choose results report mode']);

if report_mode==0 then
    messagebox("Invalid selection. Script aborted", "","error","Abort");
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;      
end



///////////////////
// Get number of terms 
// to be reported
///////////////////

if report_mode==1 then    // Largest n xterms
    
    temp = x_mdialog("Please enter parameter", "Maximum number of xtalk terms >0:", string(xtalk_max_rep));

    if (temp==[]) | (temp=="0") then
        messagebox("Script aborted", "","error","Abort");      
        if getscilabmode()=="NW" then sleep(2000); quit; else abort end; 
    end

    xtalk_max_rep = evstr(temp(1));

    disp(strcat(["Info: Selected reporting of " string(xtalk_max_rep) " xtalk elements "]));
    
elseif report_mode==2 then
    
    temp = x_mdialog("Please enter parameter", "Minium FOM threshold for reporting > 0 :", string(xtalk_fom_thsld));

    if (temp==[]) | (temp=="0") then
        messagebox("Script aborted", "","error","Abort");      
        if getscilabmode()=="NW" then sleep(2000); quit; else abort end; 
    end

    xtalk_fom_thsld = evstr(temp(1));

    disp(strcat(["Info: Selected reporting of FOM threshold >= " string(xtalk_fom_thsld)]));
    
    
else
    messagebox("Something is wrong. Script aborted", "","error","Abort");
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;      
end



///////////////////
// Read csv files
///////////////////

//
// Read input file(s)
//
//
fcsvfiles=uigetfile("*.csv", "",  "Please choose csv file", %t);                                                

if fcsvfiles==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");
    if getscilabmode()=="NW" then sleep(2000); quit; else abort end;      
end


////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// LIST RESULTS   ///////////////////////////////


temp=[];

vict_net_str=emptystr();
vict_pin_str=emptystr();
aggr_net_str=emptystr();
aggr_pin_str=emptystr();
fom_str=emptystr();


mprintf("\n****************\n");


// For each file
        for i=1:size(fcsvfiles,2)
            
            // Read the contents
            csv_data=csvRead(fcsvfiles(i), ",", [], "string", [], [], [], 1);
            
            // Convert the FOM data to double
            fom_data_vec=eval(csv_data(:,7));
            
            //Find largest FOM values
            [temp, results_max_fom_idx]=gsort(fom_data_vec);

            mprintf("*\n*  Printing largest FOM values for: %s\n", fileparts(fcsvfiles(i),"fname"));            
            mprintf("*\n*     FOM values   MAX:  %0.6e\n", max(fom_data_vec));            
            mprintf("*\n*                  AVG:  %0.6e\n", mean(fom_data_vec));                        
            mprintf("*\n*                  MED:  %0.6e\n", median(fom_data_vec));            
            mprintf("*\n*                  MIN:  %0.6e\n", min(fom_data_vec));                        
            
            // If threshold-based limits
            if report_mode==2 then
                xtalk_max_rep=sum(temp>=xtalk_fom_thsld);
                xtalk_max_rep
            end
//            clear temp;        
            
            // Print largest FOM values to console
            mprintf("*\n*  Printing largest %d xtalk FOM values: \n*\n", xtalk_max_rep);
            mprintf("*  |         VICTIM NET         | VICTIM PIN |          AGGR NET          |  AGGR PIN  |    FOM     | \n");
            mprintf("*  |----------------------------|------------|----------------------------|------------|------------| \n");
         
            for j=1:xtalk_max_rep
                
                // Victim net name
                vict_net_str=csv_data(results_max_fom_idx(j),1);
        
                if length(vict_net_str)>28 then        // Some padding if necessary
                    vict_net_str = strcat([part(vict_net_str, 1:25), "..."]);
                else
                    vict_net_str=part(vict_net_str, 1:28);
                end
                
                // Vict pin name
                vict_pin_str=csv_data(results_max_fom_idx(j),2);
                if length(vict_pin_str)>12 then        // Some padding if necessary
                    vict_pin_str = strcat([part(vict_pin_str, 1:9), "..."]);
                else
                    vict_pin_str=part(vict_pin_str, 1:12);
                end  
                
                // Aggr net name      
                aggr_net_str=csv_data(results_max_fom_idx(j),4);
                if length(aggr_net_str)>28 then        // Some padding, if necessary
                    aggr_net_str = strcat([part(aggr_net_str, 1:25), "..."]);
                else
                    aggr_net_str=part(aggr_net_str, 1:28);
                end          
                
                
                // Aggr pin name
                aggr_pin_str=csv_data(results_max_fom_idx(j),5);
                if length(aggr_pin_str)>12 then        // Some padding if necessary
                    aggr_pin_str = strcat([part(aggr_pin_str, 1:9), "..."]);
                else
                    aggr_pin_str=part(aggr_pin_str, 1:12);
                end  
                
                //FOM value
                fom_str=csv_data(results_max_fom_idx(j),7);
                if length(fom_str)>12 then        // Some padding if necessary
                    fom_str = strcat([part(fom_str, 1:9), "..."]);
                else
                    fom_str=part(fom_str, 1:12);
                end          
                        
                        
               mprintf("*  |%s|%s|%s|%s|%s|\n",vict_net_str,vict_pin_str,aggr_net_str,aggr_pin_str,fom_str);
             end
            
    end
mprintf("*\n****************\n");

clear temp;


////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// PLOT RESULTS   ///////////////////////////////

//create figure
fig_main_dotplot=scf(1);
clf(fig_main_dotplot);


drawlater;

// For each file
for i=1:size(fcsvfiles,2)
            // Read the contents
            csv_data=csvRead(fcsvfiles(i), ",", [], "string", [], [], [], 1);
            
            legends_text(i)=fileparts(fcsvfiles(i),"fname");
            
            // Convert the FOM data to double
            fom_data_vec=eval(csv_data(:,7));

            //Plot raw data
            plot2d(fom_data_vec);
            
            // Prettify plots
            fig_props=gce();
            fig_props.children.line_mode="off";
            fig_props.children.mark_style = 0;
            fig_props.children.mark_size_unit = "point";
            fig_props.children.mark_size = 3;
            fig_props.children.mark_foreground = dot_color_vect(modulo(i-1,length(dot_color_vect))+1);
end

//Add labels to dot plot
xlabel("Xtalk case");
ylabel("Xtalk FOM");

//Add labels to dot plot
legend(legends_text,-1,%t);


drawnow;


//quit;




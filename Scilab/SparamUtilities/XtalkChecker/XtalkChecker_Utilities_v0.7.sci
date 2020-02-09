//=========================   Xtalk Checker ============================
// 
// Xtalk checker
// 
//  Supporting Functions
//
// (c)2015-16  L. Rayzman
//
//  
// Created      : 
// Last Update  : 10/13/15 - Added single-ended port impedance renorm
//                02/23/16 - Fixed PORT_ALIAS_EXTRCT_FORSIW to support
//                           suffixed refdes
//          
//
//
//  TODO: Currently supports one load per bank. 
//
// ====================================================================
// ====================================================================
//
//
// 
////////////////////////////////////////////////////////////////////////////////
/////////////////////////Port autodetection and reordering////////////////////
function netmapnames = PORT_ALIAS_EXTRCT_FORSIW(spcomments, numofports)

//  Extracts port mapping information from SiWave-generated touchstone files
// 
// Inputs:
//      spcomments    -   vector of comments read from the touchstone files
//
//      numofports    -   number of ports in s*p file
//
//  Outputs:
//     portmapnames   -   Extracted port names vector as a structure:
//                        struct('net_name', ____, ...       
//                            'port_num', ____,...              
//                            'pin_array',____,...     
//                            'port_array',____);              


//
//  Init
//

netmapnames_tmp=struct('net_name',emptystr(), ...       //   - Name of net
                'port_num', 0,...                   //   - number of ports on the net
                'pin_array',emptystr(),...          //   - pin number(s) (Ux_PinY)
                'port_array',[]);                   //   - Port number(s) 
netmap_idx=0;                                       // Port map counter

netmapnames=netmapnames_tmp;
                

com_length=0;                                       // Length of the comment string

portcnt=0;                                          // Port counter

    
//
// Populate the list
//

tmp1=emptystr();
tmp2=emptystr();
tmp3=emptystr();
tmp4=emptystr();
net_found_idx=1;

com_length=size(spcomments,2);

for i=1:com_length
    
     tmp1=stripblanks(convstr(spcomments(i),'u'),%T);

     // Found a port string, add port number to net
     if grep(tmp1, "PORT[")<>[] then
         
         // tmp4 contains port number (as a string)
          [tmp2,tmp3,tmp4]=regexp(tmp1, '/(\[[0-9]+\])/','o');
          tmp4=part(tmp4,2:$-1); 
            
            // Found a new port      
            portcnt = portcnt + 1;
          
           // Take string after the =
           tmp1=tokens(tmp1, "=");   
           tmp2=stripblanks(tmp1(2));              
    
           // Split the text between second and last "_" from the end
           tmp3=strindex(tmp2,'_');                 // find all "_"
           tmp2=strsplit(tmp2, tmp3($-1:$));          // split at second "_" from end

           
           //Check whether if refdes or not
           if sum(isletter(tmp2(2))) == 1 then
               // If it is then  
               // Split text into one that's before and after second "_" from the end  
               tmp2=stripblanks(tmp1(2));         // Remove blanks
               tmp3=strindex(tmp2,'_');           // find all "_"
               tmp2=strsplit(tmp2, tmp3($-1));    // split at third "_" from end
           else
               //   Split text into one that's before and after third "_" from the end           
               tmp2=stripblanks(tmp1(2));         // Remove blanks
               tmp3=strindex(tmp2,'_');           // find all "_"
               tmp2=strsplit(tmp2, tmp3($-2));    // split at third "_" from end
           end

           tmp3=tmp2(2);                             // put the refdes_pin to the end
           tmp2=part(tmp2(1),1:$-1);                 // place the netname and strip the "_"

           
           // tmp2 contains net name
           // tmp3 contains refdes/pin name

             // Search existing portmap for matching net name
             if netmap_idx>0 then
                   net_found_idx=0;
                   for j=1:netmap_idx
                      //If matched net, make note of the location in the port
//                      disp(strcat(["netmap_idx=" string(netmap_idx) ", j=" string(j) ", netname=" tmp2 ", pin=" tmp3]));

                      if strcmpi(netmapnames_tmp(j).net_name, tmp2)==0 then
                          net_found_idx=j;
                      end
                   end
                    //If not matched at end of search, then add
                      if ~net_found_idx then
                          netmap_idx=netmap_idx+1;
                          net_found_idx=netmap_idx;
                      end
              else
                 netmap_idx=1;
                 net_found_idx=1;
             end
             
              //Add net name (regardless if new or not)
              netmapnames_tmp(net_found_idx).net_name=tmp2;
              // Add new port at index
              netmapnames_tmp(net_found_idx).port_num=netmapnames_tmp(net_found_idx).port_num+1;
                  // Pin names
              netmapnames_tmp(net_found_idx).pin_array(netmapnames_tmp(net_found_idx).port_num)=tmp3;
                  // Port number
              netmapnames_tmp(net_found_idx).port_array(netmapnames_tmp(net_found_idx).port_num)=eval(tmp4);
      end
end


// Basic error checking
if portcnt <> numofports then
    disp("PORT_ALIAS_EXTRCT_FORSIW warning: number of ports extracted not matching expected!");
    return;
end

//Dump out the captured data
netmapnames=netmapnames_tmp;

    
endfunction    

////////////////////////////////////////////////////////////////////////////////
///////////////////////// Single-ended port renormalizaion /////////////////////
function spsedata = SE_ZRENORM(spsedata, zref_renorm, zref_orig)

//  Performs impedance renormalization on singl-ended s-param data
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
//        spsedatain    -   Input mixed-mode s-param data
//      zref_renorm     -   Port impedance (single-ended) to renormalize to
//        zref_orig     -   Port impedance (single-ended) associated with input s-param
//
//
//  Outputs:
//
//       spsedataout     -   Renormalized s-param data    



// Can overload
[lhs,rhs]=argn(0);
if (rhs == 2) then zref_orig=50; end;


// Basic error checking
if ~(isreal(zref_renorm)) | (abs(zref_renorm) <= 0)  then
    disp("SE_ZRENORM error: invalid normalizing port impedance value!");
    return;
end

// Basic error checking
if ~(isreal(zref_orig)) | (abs(zref_orig) <= 0)  then
    disp("SE_ZRENORM error: invalid original port impedance value!");
    return;
end


//
//  Some discoveries, Init and other things
//

numofports=size(spsedata,1);                                               //Find number of ports
numofreqs=size(spsedata,3);                                                //Find number of frequency points


z_scalar=(zref_renorm-zref_orig)/(zref_renorm+zref_orig);                  // Resistance ratio constant

Eye_=eye(numofports,numofports)
Gamma_=z_scalar*Eye_;


// 
// Apply renormalization
//
for i=1:numofreqs
     spsedata(:,:,i)=(spsedata(:,:,i)-Gamma_)*inv(Eye_-Gamma_*spsedata(:,:,i));
end

clear Eye_;
clear Gamma_;


   
endfunction

// Function to read in Xgig trace and gathers packet counts
//
// (c)2009  L. Rayzman
// Created :      01/07/2009
// Last Modified: 01/07/2009 - Added Eye Measurement Tool
//
//
// 
inputfile = emptystr();                           // Filename of trace input file
matchstr1 = 'COMWAKE';                   // First token to match
matchstr2 = 'SATA_SYNC';                          // Second token to match

/////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////Test Routine////////////////////////////////////


inputfile=tk_getfile("*.txt*" ,Title="Please choose input trace file"); 
if inputfile==emptystr() then
  x_message_modeless("Invalid file selection. Script aborted");
  abort;
end
            
//////////////////////////////////////Extraction Function////////////////////////////////////

readline=emptystr();
str1cnt=0;                             // First token count
str2cnt=0;                             // Second token count



//Open File
[fhandle,err]=mopen(inputfile, "r");  

if err<0 then
   error("Parser: Unable to open data file");  
end   


//Find strings

while (~meof(fhandle)) 
     readline=mgetl(fhandle,1); 
    if grep(readline, matchstr1)==1 then                      //If reached nodename line
    str1cnt = str1cnt + 1;
    elseif grep(readline, matchstr2)==1 then                  //If reached nodename line
    str2cnt = str2cnt + 1;    
    end
  
end

   
mclose(fhandle);

// 
// Print statistics
//

printf("\n*******************************\n");
printf("%s found %d times\n", matchstr1, str1cnt);
printf("%s found %d times\n", matchstr2, str2cnt);
printf("\n*******************************\n");




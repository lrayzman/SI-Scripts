// Test to extract CSDF output waveforms and plot the waveforms
//
// (c)2008  L. Rayzman

//stacksize(64*1024*1024);
clear;		
getf("HSPiceUtilities.sci");                       // Include extraction function

//////////////////////////////////////SPECIFY//////////////////////////////////////



inputfile = emptystr();                           // Filename of CSDF input file
hyst=0;                                           // Hysteresis
tUIin=1.25e-10;                                   // Unit Interval to compute the eye width for
Dj=0e-12;                                        // DJ to convolve with computed eye width (peak-to-peak)



/////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////Test Routine////////////////////////////////////


inputfile=tk_getfile("*.tr*" ,Title="Please choose input CSDF file"); 
if inputfile==emptystr() then
  x_message_modeless("Invalid file selection. Script aborted");
  abort;
end
             

//Extract frequency response from CSDF file
[t, D, Desc]=extract_from_CSDF(inputfile);

wvfrm=x_choose(Desc(2:$), ["Please select waveform";  "From simulation"; Desc(1)]);
if wvfrm==0 then
  x_message_modeless("Invalid waveform selection. Script aborted");
  abort;
end

//Plot the data
xinit()
plot2d(t, D(:,wvfrm), style=2);
xtitle(Desc(1), "Time", Desc(2));

//Measure eye 
[tUI, eh, ew] = eye_measure(t, D(:,wvfrm), hyst,Dj, tUIin);

// 
// Print some statistics
//

printf("\n*******************************\n");
printf("Average UI is: %0.2fps\n", tUI*1e12);
printf("Eye Height is: %0.3fV\n", eh);
printf("Eye Width is: %0.2fps\n", ew*1e12);
printf("\n*******************************\n");












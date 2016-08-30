//Conversion of an impedance vs frequency table into an equivalent Spice subcircuit
//Original purpose of this file is to export the capacitor impedance profile
//from Kemet Spice
//

//This guides on how to export the data from Kemet Spice in proper format
//
//  1. In Kemet Spice select the desired capacitor
//  2. Select File->Export ASCII
//  3. Set the following options
//    Delimeter: Tab
//    File Header: Do not select any checkboxes
//    Elements to Save to ASCII: Impedance and Phase(radians)
//    File Descriptor: .dat
//    Frequency Steps: 50, include self resonance
//  
//
//  This creates the impedance vs frequency file in this format
//
//		   Freq1 Z(Magnitude)@Freq1 Z(Phase)@Freq1 
//		   Freq2 Z(Magnitude)@Freq2 Z(Phase)@Freq2 
//		   Freq3 Z(Magnitude)@Freq3 Z(Phase)@Freq3 
//		   Freq4 Z(Magnitude)@Freq4 Z(Phase)@Freq4  	 
//			...
//	
//  4. In the SPECIFY section below select input and output file name, for 
//     .dat and output PSpice .lib, respectively.
//


//stacksize(64*1024*1024);
clear;																							//Clear user variables

//////////////////////////////////////////////////SPECIFY//////////////////////////////////////////////////////
		
InFilename="TestImp.dat";																					   //Specify file name containing impedance vs frequency
LibFilename="TestImp";																							//Specify output filename (and name) of PSpice subcircuit
Delay=0;                                         //Causality delay (in nanoseconds)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////


//
// Import impedance data
//

FullData = fscanfMat(InFilename);																//Load file data into matrix

FreqMat = FullData(:,1)';																		     //Extract the frequencies
ZMagMat =	FullData(:,2)';					                  //Extract the impedance magnitude
ZPhMat =  FullData(:,3)';                       //Extract the impedance phase

clear FullData;																						 //Free memory

//
// Convert imported data into real/imaginary format
ZMat = ZMagMat.*(cos(ZPhMat) + %i*sin(ZPhMat));

clear ZMagMat;                                  //Free memory
clear ZPhMat;


//
// Convert impedance to admittance
YMat=(ZMat)^(-1);


//
// Create .lib file
//
FileHandle=file('open', LibFilename+'.lib', 'new');

fprintf(FileHandle, ".SUBCKT %s 1 2\n\n", LibFilename);									  //Write header to file
fprintf(FileHandle, "GAdmittance 1 2 FREQ {V(1,2)}=R_I\n");       

for i=1:length(FreqMat)                                           //write admittance table to file
	fprintf(FileHandle, "+ (%6e, %6e, %6e)\n",  FreqMat(i), real(YMat(i)), imag(YMat(i)));
end

if Delay>0 then
  fprintf(FileHandle, "+DELAY=%fn\n", Delay);
end


fprintf(FileHandle, ".ENDS");                                   //Write end of subcircuit

file('close',FileHandle);




















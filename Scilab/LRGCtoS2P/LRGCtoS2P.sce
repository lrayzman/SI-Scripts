//Conversion of single transmission line LRGC parameters to two port S-parameters
//Refer to Dr. H. Johnson's High Speed Signal Propagation, Ch2, Ch 3, Appdx A &
// Advanced High Speed Propagation Ch 2

//This guides on how to import L, R, G, C input parameters from a 2D simulator(Ansoft Maxwell 2D)
//
//				Process is as follows:
//
// 1. Built geometry model in simulator
// 2. Select AC Conduction simulator
//	3. Specify materials. 
//	  Notes: 
//	        - Maxwell SV9 contains a bug prohibiting proper account of dielectric losses
//					- Use perfect conductor for copper
//		 see the workaround as described in "Ansoft Maxwell SV Loss Tangent Bug Workaround.doc"
//	3. Simulate AC Conduction for the desired range of frequencies and extract CG parameters
// 4. Copy the model to Eddy Currents simulator.
//	   Set dielectric conductance to zero
//	5. Simulated Edyy Currents for the desired range of frequencies and extract LR parameters
// 6. Place results into a text file in the following format
//		   Freq1 L@Freq1 R@Freq1 G@Freq1 C@Freq1		
//		   Freq2 L@Freq2 R@Freq2 G@Freq2 C@Freq2		
//		   Freq3 L@Freq3 R@Freq3 G@Freq3 C@Freq3	
//		   Freq4 L@Freq4 R@Freq4 G@Freq4 C@Freq4		
//			...
//	
//		Rules:
//			Frequencies are in GHz
//			L is in Henries/Meter
//			R is in Ohms/Meter
//			G is in Siemens/Meter
//			C is in Farads/Meter
//			Frequencies must increment
//			No comments or any other extraneous text allowed
//			Format allows only space or tab separators between parameters
//			
//		  !!!!Make sure to get L R G C in the correct order...!!!!!
//		  !!!!...Ansoft output is actually in R L G C order !!!!!!!
//		  !!!!Make sure to use clear previous sim in Ansoft !!!!!!!
//			!!!!...for each frequency using Initial!!!!
//
//
// 7. Specify the input filename
// 8. Specify length of trace in inches


//stacksize(64*1024*1024);
clear;																							//Clear user variables

//////////////////////////////////////////////////SPECIFY//////////////////////////////////////////////////////
		
LRGCFilename="LRGCTest.dat";																					//Specify file name containing LRGC table
S2PFilename="LRGCTest.s2p";																							//Specify output filename of S-parameters

Z0=50+0*%i;																							//Specify the environment impedance. Must be a real number.

Len = 1;																							//Specify length in inches

//////////////////////////////////////////////////////////////////////////////////////////////////////////////


//
// Import LRGC data
//

FullData = fscanfMat(LRGCFilename);																//Load file data into matrix

FreqMat = FullData(:,1)'	* 1e9;																			 //Extract the frequencies
LMat =	FullData(:,2)' * Len / 39.3701;												//Extract the L, scaling it by length
RMat =	FullData(:,3)' * Len / 39.3701;												//Extract the R, scaling it by length
GMat =	FullData(:,4)' * Len / 39.3701;												//Extract the G, scaling it by length
CMat =	FullData(:,5)' * Len / 39.3701;											 //Extract the C, scaling it by length																						

clear FullData;																								//Free memory


//
// Calculate Zc (characteristic impedance of t-line at freq)
// and H (transfer function)
//
//
//				|----------
// Zc = 	|	  jwL + R
//			\	|	 --------
//	    \|		 jwC + G 			
//																						

Zc = sqrt (((%i * 2 * %pi * FreqMat .* LMat) + RMat) .* ((%i * 2 *  %pi * FreqMat  .* CMat) + GMat)^(-1));


//         |---------------------
//				(  | (jwL + R)(jwC + G) )
//					\|
// H = e 	
//			
//	 Note that length is already enclosed in scaling of LRGC parameters and therefore gamma need not 
//		be adjusted by a length factor
//			

gam = sqrt (((%i * 2 * %pi * FreqMat .* LMat) + RMat) .* ((%i * 2 * %pi * FreqMat  .* CMat) + GMat));		//Complex prop coefficient
H=exp(-gam);																																																//Transfer function

//
// Calculate S-parameters
//					     	     -1        2    2
//						       (H   - H)(Zc - Z0)
//                    -------  -------
//						 	         	2	      Zc
// S11=S22= ---------------------------------
//               -1         -1         2      2
//					  Z0(H  + H) + (H   - H) (Zc  + Z0)
//                        ---------  ---------
//													  2          Zc
//           		
//                         2
//	S12=S21= --------------------------------- 
//						   -1          -1       2    2
//						  (H  + H) + (H  - H)(Zc + Z0)
//												 ------- --------
//													  2     Zc Z0
//			
// But since ports are perfectly terminated then
// S12=S21 is simply H!
//

S11= (((H^(-1) - H)/2) .* ((Zc^2 - Z0^2) ./ Zc)) ./ ((Z0 .* (H^(-1) + H)) + ((H^(-1) - H)/2).*((Zc^2 + Z0^2) ./ Zc));
[S11Ph, S11Mag] = phasemag(S11);																																	//compute phase and magnitude (dB) of S11

S12= 2 ./ ((H^(-1) + H) + ((H^(-1) - H)/2).*((Zc^2 + Z0^2) ./ (Z0 .* Zc)));
[S12Ph, S12Mag] = phasemag(S12);																																	//compute phase and magnitude (dB) of S12


//
// Create S2P file
//
																																//Fill in S-parameters						
Sparam = FreqMat' / 1e9;
Sparam(:,2) = S11Mag';
Sparam(:,3) = S11Ph';
Sparam(:,4) = S12Mag';
Sparam(:,5) = S12Ph';
Sparam(:,6) = S12Mag';																																//S21 = S12
Sparam(:,7) = S12Ph';
Sparam(:,8) = S11Mag';																																//S22 = S11
Sparam(:,9) = S11Ph';

fprintfMat(S2PFilename, Sparam, '%f' ,"# GHz S DB R 50");									  //Write S2P to file


//
// Print some useful data
//
printf("\n****************************************************\n");
printf("Length=%0.4f inches", Len);
printf("\n****************************************************\n");
printf("Frequency(GHz)  | Re[Zc], Im[Zc]  | Attenuation(dB)\n");  
printf("****************|*****************|*****************\n");

for i=1:length(FreqMat)
	printf("     %0.4f     |  %0.2f , %0.2f  |   %0.4f\n", FreqMat(i)/1e9, real(Zc(i)), imag(Zc(i)), S12Mag(i));
end 

//
// Plot attenuation curve
//
xtitle("Attenuation", "Frequency (Ghz)", "dB");
plot2d(FreqMat/1e9, S12Mag);


















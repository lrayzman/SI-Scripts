//Reads in the scope trace in ASCII format from LeCroy scope
// to HSpice PWL voltage source

//This guides on how to use this script
//
//				Process is as follows:
//					1. Save Waveform to Time, Amplitude ASCII format, no Header
//					2. If header exists in the source file remove it.
//         3. Script creates HSpice subcircuit name %DataName_src
//         4. Use the following HSpice line:
//      
//          Xxxx  Srcp srcn gnd DataName_src        $ Differential case
//          Xxxx  Src  gnd Dataname_src             $ Single ended case
//

stacksize(64*1024*1024);

clear;																							//Clear user variables

//////////////////////////////////////////////////SPECIFY//////////////////////////////////////////////////////
		
InFileP="C2MotherBoard_Slot1.txt";																            //Specify input characters filename (positive, or single ended)
InFileN="C4MotherBoard_Slot1.txt";											                 //Specify input characters filename (negative)
OutFile="OutStream.inc";


DataName="Seabrg";                                   //Specify the name of the HSpice dataset
isdiff=%t;                                          //Specify if input is differential. If differential,
                                                    //InFileP and InFileN specify positive and negative waveforms
                                                    //If negative
                                                    
MaxNumOfSamples=5000;                               //Maximum number of samples                                                    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

[fdIP, Err] = mopen(InFileP, "r");                             //Open in file(s)

if isdiff==%t then
    [fdIN, Err] = mopen(InFileN, "r");
end   
  
[fdO, Err] = mopen(OutFile, "w");																											  //Open out file

NumSamplesP = 0;                                               //Count of samples    
readfirstline=%f;
skiplinesave=%t;
toffset=0;                                                    // Time adjustment offset
line=[];
totaltime=0;
                                    
if isdiff==%t then                                          //File Header                         
                                                        
      mfprintf(fdO, "*%s signal generator\n", DataName);                //Diff
      mfprintf(fdO, ".SUBCKT %s_src OutP OutN GND_SRC \n", DataName);
      mfprintf(fdO, "VSRCP OutP GND_SRC PWL (\n");                      
    else
      mfprintf(fdO, "*%s signal generator\n", DataName);                //SE
      mfprintf(fdO, ".SUBCKT %s_src Out GND_SRC \n", DataName);
      mfprintf(fdO, "VSRC Out GND_SRC PWL (\n");  
end  

//Print positive

while %t do
      line=mgetl(fdIP, 1);
      
      if (meof(fdIP)<>0) | (NumSamplesP > MaxNumOfSamples)  then                                 //If reached EOF
        break;
      end 
      
      if readfirstline==%t then
          readfirstline=%f;
          l=msscanf(line, "%e,%f");                     // Read in first line to determine time offset
          toffset=l(1);
          skiplinesave=%f;
      end 
      
      if skiplinesave==%f then
          l=msscanf(line, "%e,%f");                     // Read in line
          l(1)=l(1)-toffset;
          mfprintf(fdO, "+ %e %f\n", l(1), l(2));
          NumSamplesP= NumSamplesP+1;
          totaltime=l(1);
      end
      
      if line=="Time,Ampl" then
          readfirstline=%t;
      end

end

mfprintf(fdO, ")\n\n");                                  //End of positive voltage source

// If differential repeat for negative
if isdiff==%t then 
  
    NumSamplesN=0;
    readfirstline=%f;
    skiplinesave=%t;

  mfprintf(fdO, "VSRCN OutN GND_SRC PWL (\n");   

  while %t do
      line=mgetl(fdIN, 1);
      
      if (meof(fdIN)<>0) | (NumSamplesN > MaxNumOfSamples)  then                                 //If reached EOF
        break
      end        
      if readfirstline==%t then
          readfirstline=%f;
          l=msscanf(line, "%e,%f");                     // Read in first line to determine time offset
          toffset=l(1);
          skiplinesave=%f;
      end 
      
      if skiplinesave==%f then
          l=msscanf(line, "%e,%f");                     // Read in line
          l(1)=l(1)-toffset;
          mfprintf(fdO, "+ %e %f\n", l(1), l(2));
          NumSamplesN= NumSamplesN+1;
      end
      
      if line=="Time,Ampl" then
          readfirstline=%t;
      end
  end      
    
    mfprintf(fdO, ")\n\n");            //End of voltage source
end




mfprintf(fdO, ".ENDS");               //Trailer
mclose(fdO);

mclose(fdIP);
if isdiff==%t then
    mclose(fdIN);
end  


printf("\n**********************************\n");

if (isdiff==%t & (NumSamplesP <> NumSamplesN)) then
  printf("Total positive waveform number of samples %d \n", NumSamplesP-1);
  printf("Total negative waveform number of samples %d \n", NumSamplesN-1);
  else
  printf("Total number of samples %d \n", NumSamplesP-1);
end 
printf("Total time: %0.4e nanoseconds\n", totaltime*1e9);
printf("**********************************\n");

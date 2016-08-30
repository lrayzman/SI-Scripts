//Combining PSpice extraction of S-parameters into a single Touchstone file

// File names must be in text format 
// Input data must be in a DB-Ang format


//stacksize(64*1024*1024);
clear;																							//Clear user variables

//////////////////////////////////////////////////SPECIFY//////////////////////////////////////////////////////

		
NumOfPorts=4;                                    //Specify the size of the S-params matrix		
Z0=50;																							//Specify the environment impedance. Must be a real number.

OutFileName="Sparams";  


//////////////////////////////////////////////////////////////////////////////////////////////////////////////


//
// Import SParams Data
//

Y = fscanfMat("S11.txt");
FreqData=Y(:,1);                                                   //Write frequency data

SparamData(:,1)=FreqData;                                          //Initialize SparamData

for i = 1:NumOfPorts,
  for j= 1:NumOfPorts,
  
  FileName=strcat(["S", string(i), string(j), ".txt"]); 
  Y = fscanfMat(FileName);
                                                                    //Check that frequencies are matching
      if ~(isequal(FreqData, Y(:,1))) then
        printf("Frequency data not equal between different S-files. Operation aborted!\n");
        abort;
      end
  
  SparamData(:, 2*((i-1)*NumOfPorts+j)-1:2*((i-1)*NumOfPorts+j))=Y(:, 2:3);

  end
end

//Create/open the Sparams out file

OutFileName = strcat([OutFileName, ".s", string(NumOfPorts), "p"]);
OutFileHandle=mopen(OutFileName, 'w');                        

//Print header
mfprintf(OutFileHandle, "!S-Parameters converted from PSpice model by SpiceSParamCombine\n");                                               
DateTime=getdate();
mfprintf(OutFileHandle, "!Created on %02d/%02d/%d at %02d:%02d:%02d\n\n", DateTime(2), DateTime(6), DateTime(1), DateTime(7), DateTime(8), DateTime(9)); 
mfprintf(OutFileHandle, "# GHz S DB R %d\n", Z0); 


//Print description of Sparameters
mfprintf(OutFileHandle, "! Freq");

DataPerLineCount=0;

//Print maximum 4 data pairs per line
for i = 1:NumOfPorts,
  for j= 1:NumOfPorts,
    SparamDescr=strcat(["S", string(i), string(j)]); 
    
    //print DB and Ang
    mfprintf(OutFileHandle, " db(%s) ang(%s)", SparamDescr, SparamDescr);
    
    DataPerLineCount=DataPerLineCount+1;
    
    //Print the line for >2 Port S-Params once 4 data pairs per line
    if (DataPerLineCount==4)&(NumOfPorts >2)&~(NumOfPorts == 4),
        //Print the line
      mfprintf(OutFileHandle, "\n!     ");
    end
     
  end
    //Print the line for >2 Port S-Params
    if(NumOfPorts>2),
      mfprintf(OutFileHandle, "\n!     ");
      DataPerLineCount=0;
     end
  
end 

//New line for odd number of parameters
mfprintf(OutFileHandle, "\n\n");



//****DON'T FORGET TO CONVERT FREQUENCIES TO GHz****

//Get number of frequencies
FreqNum=size(FreqData, 1);

//For each port
for k=1:FreqNum,
    mfprintf(OutFileHandle, "\n %f", FreqData(k)/1e9)
    DataPerLineCount=0;

    //Print maximum 4 data pairs per line
    for i = 1:NumOfPorts,
      for j= 1:NumOfPorts,
             
        //print DB and Ang
        mfprintf(OutFileHandle, " %f %f", SparamData(k, 2*((i-1)*NumOfPorts+j)-1:2*((i-1)*NumOfPorts+j)));
    
        DataPerLineCount=DataPerLineCount+1;
    
        //Print the line for >2 Port S-Params once 4 data pairs per line
        if (DataPerLineCount==4)&(NumOfPorts >2)&~(NumOfPorts == 4),
            //Print the line
         mfprintf(OutFileHandle, "\n         ");
        end
     
      end
       //Print the line for >2 Port S-Params
       if(NumOfPorts>2),
          mfprintf(OutFileHandle, "\n         ");
          DataPerLineCount=0;
        end
     end 
end


mclose(OutFileHandle);





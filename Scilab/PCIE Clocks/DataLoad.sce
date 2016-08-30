//Example code to load raw waveform data and extrapolate zero crossings

stacksize(64*1024*1024);

clear;																							//Clear user variables
		
Filename="WaveformASUS915P.dat";																							//Specify file name containing clock waveform data



FullData = fscanfMat(Filename);																		//Load file data into matrix

Data = FullData(:,2)';																							//Extract vertical data (values) only 
																							//Note: not required if providing amplitude data only

Interval = abs(FullData(1,1) - FullData(2,1));				//Extract sampling interval

clear FullData;																							//Free memory


Crossings =[];																							//Define empty matrix
N = 0;																							//Index within empty matrix


//Find zero crossings

meanxn = 0;																																				//Assuming vertical symmetry

for m=1:size(Data,2)-1																																		
	 if Data(m) < meanxn then																																		   //Find positive transition accross mean
	 	if Data(m+1)  > meanxn then
			slope = (Data(m+1) - Data(m)) / Interval;																															//Interpolate time at crossing
			Crossings(1,N+1) = (meanxn-Data(m)) / slope  + (m-1)*Interval;
			N = N + 1;
	 	end
	 end
	
	 if Data(m) == meanxn 	then
	   if Data(m+1) > meanxn then
	 		Crossings(1,N+1) = (m-1)*Interval;
			N = N + 1;
		 end
	 end
end


Intervals = Crossings(2:N)	- Crossings(1:N-1);						//Clock intervals difference vector

plot2d(Intervals);






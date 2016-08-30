//Plot of general transfer function

stacksize(64*1024*1024);

s=poly(0, 's');

v=10^7:10^7:10^10; 									//Generate frequency matrix
frequencies=v*2*%pi;
//frequencies=%i*v*2*%pi;


//******************** Transfer ******************************
s=poly(0, 's');

db3=1*10^9;

//F = (2*%pi * db3) / (s + 2*%pi * db3);												//Low Pass

F = s / (s + 2*%pi * db3);																								//High Pass

H_Response=abs(20*log10((freq(F.num,F.den, 2*%pi*frequencies))));

for i=1:size(H_Response, "c"),
	printf("\n %0.4f , %0.2f ", v(i)/10^6, H_Response(i));
end


//gainplot(v, [H_Response]);

clf();																								//Clear previous graphic
plot2d(v, H_Response, logflag="ll", axesflag=1);			//Plot
xgrid(2);																							  //Set axis grids



xtitle(" ", "Frequency (Hz)", "Magnitude");







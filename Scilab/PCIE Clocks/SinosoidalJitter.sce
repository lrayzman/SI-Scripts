//Generates clock ideal crossings with sinosoidal jitter component

stacksize(128*10*1024);

N=1*1024	;																											// Number of samples
n=[0:1:N];																												  //Number of clock edges
per=10^(-8);																													//100Mhz clock period
JitAmp=0.1;																												  //Amplitude of the jitter component
JitFreq=1*10^6;																											    //Jitter frequency (Hz)

Crossings = per *(n  + JitAmp*sin((2*%pi*JitFreq) * n*per));   //Generate signal with sinosoidal modulation

//plot2d(N*per, Crossings);																															//Plot phase jitter
//xtitle("", "Time", "Time");

Frequencies=n(1:N/2) / (N*per);

//Difference = Crossings(2:N)	- Crossings(1:N-1);						//Cycle-to-cycle difference vector

Difference = Crossings - n*per;

clear n;

clear Crossings;

Spectrum=  2 * per * fft(Difference(1:N) / (per * N), -1);

xbasc();

plot2d(Frequencies, abs(Spectrum(1:N/2)))



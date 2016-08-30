//Process PCI Express clock and report eye closure
//

stacksize(32*1024*1024);

clear;

xbasc();

load("PXPClocks.dat", "Intervals");


N=2*(floor(size(Intervals,2)/2));																						//To reduce calculation discrepancies, must be even number

idealper = 10*10^(-9);	

Res=round(100e6 / N);

n=1:1:N/2;

printf("\n**************************************\n");

f= n * (100e6 / N);

frequencies=%i*2*%pi*f;

s=poly(0, 's');


//******************** H1 ******************************
zeta = 0.54;

f_3db_H1 = 1.5*10^6;																																		//H1 Cutoff frequency

ohmega_n = f_3db_H1 * 2*%pi / (sqrt(1+2*zeta^2 + sqrt((1+2*zeta^2)^2 + 1)));

H1 = (2*s*zeta*ohmega_n + ohmega_n^2) / (s^2 + 2*s*zeta*ohmega_n + ohmega_n^2);

H1_Response = freq(H1.num, H1.den, frequencies);



//******************** H2 ******************************
zeta = 0.54;

f_3db_H2 = 22*10^6;																																		//H2 Cutoff frequency

ohmega_n = f_3db_H2 * 2*%pi / (sqrt(1+2*zeta^2 + sqrt((1+2*zeta^2)^2 + 1)));

H2 = (2*s*zeta*ohmega_n + ohmega_n^2) / (s^2 + 2*s*zeta*ohmega_n + ohmega_n^2);

H2_Response = freq(H2.num, H2.den, frequencies);


//******************** H3 ******************************
f_3db_H3 = 1.5*10^6;																																		//H3 Cutoff frequency

H3 = s / (s + f_3db_H3*2*%pi);

H3_Response = freq(H3.num, H3.den, frequencies);



//******************** Delay ******************************														

						
DelayTime = 10*10^(-9);																																		//Delay per CEM spec

HDelay_Response = (exp(-DelayTime * frequencies));



//******************** Ht - total response******************************

plotrangemin = ceil(1*10^5 / (100e6 / N));
plotrangemax = N/2;

Ht_Response = 2*(H1_Response .* HDelay_Response - H2_Response) .* H3_Response;

Ht_Response_rev = pertrans(Ht_Response)';																																	//Produce reverse matrix for negative frequencies, below

gainplot(f(plotrangemin:plotrangemax), [H1_Response(plotrangemin:plotrangemax); H2_Response(plotrangemin:plotrangemax); ...
H3_Response(plotrangemin:plotrangemax); Ht_Response(plotrangemin:plotrangemax)] , ["H1",  "H2", "H3", "Ht"]);

xtitle("Transfer function", "Frequency (Hz)", "Magnitude");


//******************** Extract phase jitter *****************************

pj = Intervals(1:N);
meanper = mean(Intervals(1:N));
pj = pj - meanper;
Phi = cumsum(pj);
Phi = Phi - mean(Phi);

printf("Calculation over %d clock periods\n", N);
printf("Clock frequency: %f MHz\n", (1/meanper)/1000000);
printf("Frequency drift from nominal: %.2f ppm\n", 1000000*(1/meanper - 1/idealper)*idealper) 

peak_close = max(abs(Phi));

printf("Peak eye closure before transfer func: %.2f ps\n", peak_close*10^12);


xset("window", 1)																										//Create new window

plot2d((0:idealper:(N-1)*idealper)*10^6, Phi*10^12, style=2);

xtitle("Phase Jitter vs Time", "Time(uS)", "Time(pS)");

//******************** Take FFT of phase jitter *****************************

PhiSpectr=idealper*fft(Phi, -1);

//*********************Apply transfer function  *****************************

M=[];

M(1:N/2) = PhiSpectr(1:N/2) .* Ht_Response(1:N/2);																//For positive frequencies from 0 to PI

M(N/2+1:N) = PhiSpectr(N/2+1:N) .* Ht_Response(1:N/2);												//For negative frequencies from PI to 2PI


//*********************Plot responses ***************************

xset("window", 2)																															//Create new window
								
								
plotrangemin = ceil(1*10^4 / (100e6 / N));
plotrangemax = N/2;

legends(["Raw", "After transfer func"], style=[2,5], opt="ur", with_box=%f);

plot2d(f(plotrangemin:plotrangemax), abs(M(plotrangemin:plotrangemax)), style=5, logflag="ll");																							//After transfer function

plot2d(f(plotrangemin:plotrangemax), abs(PhiSpectr(plotrangemin:plotrangemax)), style=2, logflag="ll");															//Raw spectrum

xgrid(4);

xtitle("Phase jitter spectrum", "Frequency", "Time(s)");



//*********************Plot intervals vs time and histogram ***************************

xset("window", 3);

plot2d([1:1:N]*idealper*10^6, Intervals*10^9);
xtitle("Intevals vs time", "Time(uS)", "Time(nS)");

xset("window", 4);

histplot(500, Intervals*10^9);
xtitle("Distribution of intervals", "Period time(nS)", "Count");



//*********************Get eye closure after transfer ******************

Phi_trans = (1 / idealper) * fft(M, 1);

xset("window", 1)

plot2d((0:idealper:(N-1)*idealper)*10^6,  real(Phi_trans)*10^12, style=5);

legends(["Raw", "After transfer func"], style=[2,5], opt="ur", with_box=%f);

xtitle("Phase Jitter vs Time", "Time(uS)", "Time(pS)");

//*********************Calculate max eye closure ********************

peak_close = max(abs(real(Phi_trans)));

printf("Peak eye closure after transfer func: %.2f ps\n", peak_close*10^12);
printf("**************************************\n");













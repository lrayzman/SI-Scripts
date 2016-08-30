//Plot of transfer functions defined in PCI Express jitter modeling paper

s=poly(0, 's');

v=10^5:10^4:50*10^6; 									//Generate frequency matrix
frequencies=%i*v*2*%pi;


//******************** H1 ******************************
zeta = 0.707;

f_3db = 7*10^6;																																		//H1 Cutoff frequency

ohmega_n = f_3db * 2*%pi / (sqrt(1+2*zeta^2 + sqrt((1+2*zeta^2)^2 + 1)));

H = (2*s*zeta*ohmega_n + ohmega_n^2) / (s^2 + 2*s*zeta*ohmega_n + ohmega_n^2);

H_Response = freq(H.num, H.den, frequencies);




gainplot(v, [H_Response]);

xtitle(" ", "Frequency (Hz)", "Magnitude");








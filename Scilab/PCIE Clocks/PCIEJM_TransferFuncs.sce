//Plot of transfer functions defined in PCI Express jitter modeling paper

s=poly(0, 's');

v=10^5:10^4:50*10^6; 									//Generate frequency matrix
frequencies=%i*v*2*%pi;


//******************** H1 ******************************
zeta = 0.54;

f_3db_H1 = 1.5*10^6;																																		//H1 Cutoff frequency

ohmega_n = f_3db_H1 * 2*%pi / (sqrt(1+2*zeta^2 + sqrt((1+2*zeta^2)^2 + 1)));

H1 = (2*s*zeta*ohmega_n + ohmega_n^2) / (s^2 + 2*s*zeta*ohmega_n + ohmega_n^2);

H1_Response = freq(H1.num, H1.den, frequencies);



//******************** H2 ******************************
zeta = 0.54;

f_3db_H2 = 2.2*10^7;																																		//H2 Cutoff frequency

ohmega_n = f_3db_H2 * 2*%pi / (sqrt(1+2*zeta^2 + sqrt((1+2*zeta^2)^2 + 1)));

H2 = (2*s*zeta*ohmega_n + ohmega_n^2) / (s^2 + 2*s*zeta*ohmega_n + ohmega_n^2);

H2_Response = freq(H2.num, H2.den, frequencies);


//******************** H3 ******************************
f_3db_H3 = 1.5*10^6;																																		//H3 Cutoff frequency

H3 = s / (s + f_3db_H3*2*%pi);

H3_Response = freq(H3.num, H3.den, frequencies);


//******************** Ht ******************************

Ht = (H1 - H2) * H3;

Ht_Response = freq(Ht.num, Ht.den, frequencies);

//plot2d(v, abs(Ht_Response), style=5, logflag="ll", rect=[10^4, 10^(-2), 10^8, 10^1]);

gainplot(v, [H1_Response; H2_Response; H3_Response; Ht_Response] , ["H1", "H2", "H3", "Ht"]);

xtitle(" ", "Frequency (Hz)", "Magnitude");







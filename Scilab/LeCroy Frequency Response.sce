//Plots of LeCroy Transfer functions

p=poly(0, 's');
s=p/(2*%pi);

v=0.01:0.01:100; 									//Generate frequency matrix
frequencies=%i*v*2*%pi;


//****************Fibre Channel***************************
H = (1/(1+s));

H_Response = freq(H.num, H.den, frequencies);


gainplot(v, [H_Response]);

xtitle(" ", "Frequency (Hz)", "Magnitude");

//****************Single Pole- Single Zero***************************
zero=1/10;
pole=1/1;

H = (1 + s*zero)/(1 + s*pole);

H_Response = freq(H.num, H.den, frequencies);

gainplot(v, [H_Response]);

xtitle(" ", "Frequency (Hz)", "Magnitude");

//******************** PCie 1.1 ******************************
zeta = 0.707;

f_3db = 1.5;																																		

ohmega_n = f_3db * 2*%pi / (sqrt(1+2*zeta^2 + sqrt((1+2*zeta^2)^2 + 1)));

H = (2*p*zeta*ohmega_n + ohmega_n^2) / (p^2 + 2*p*zeta*ohmega_n + ohmega_n^2);

H_Response = freq(H.num, H.den, frequencies);

gainplot(v, [H_Response]);

xtitle(" ", "Frequency (Hz)", "Magnitude");

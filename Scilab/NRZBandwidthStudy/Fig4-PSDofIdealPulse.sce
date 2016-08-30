// Plot of PSD for ideal pulse
// (c)2008 Lenny Rayzman

//////////SPECIFY/////////////////////
samplerate=1000;                // Number of points per period (must be multiple of 2)

//////////////////////////////////////

tofn=[0:1/(samplerate/2):3];

ppsdofn=sinc(%pi*tofn).*sinc(%pi*tofn);

plot2d(tofn, ppsdofn, style=2);
xgrid(4);
xtitle('', 'Normalized Frequency (Multiples of Baud Rate)')







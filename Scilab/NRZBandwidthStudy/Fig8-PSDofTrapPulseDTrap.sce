// Plot of PSD for ideal pulse
// (c)2008 Lenny Rayzman

//////////SPECIFY/////////////////////
samplerate=1000;                // Number of points per period (must be multiple of 2)
trf=0.4;                      // Rise and fall time

//////////////////////////////////////

ftofn=[0:1/(samplerate/2):3];

ppsdofn=(sinc(%pi*ftofn).*sinc(%pi*ftofn));
tpsdofn=(sinc(%pi*ftofn).*sinc(%pi*ftofn)).*(sinc(%pi*ftofn*trf).*sinc(%pi*ftofn*trf));
dtpsdofn=trf*trf*4*%pi^2*ftofn.*ftofn.*(sinc(%pi*ftofn).*sinc(%pi*ftofn)).*(sinc(%pi*ftofn*trf).*sinc(%pi*ftofn*trf));

plot2d(tofn, ppsdofn, style=2);
plot2d(tofn, tpsdofn, style=5);
plot2d(tofn, dtpsdofn, style=13);
xgrid(4);
xtitle('', 'Normalized Frequency (Multiples of Baud Rate)')







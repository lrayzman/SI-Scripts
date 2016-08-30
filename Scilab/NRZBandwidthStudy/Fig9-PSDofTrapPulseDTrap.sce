// Plot of PSD for ideal pulse
// (c)2008 Lenny Rayzman

//////////SPECIFY/////////////////////
samplerate=1000;                // Number of points per period (must be multiple of 2)
trf=0.4;                      // Rise and fall time

//////////////////////////////////////

ftofn=[0:1/(samplerate/2):3];
ftofnlong=[0:1/(samplerate/2):1000];

ppsdofn=(sinc(%pi*ftofn).*sinc(%pi*ftofn));
tpsdofn=(sinc(%pi*ftofn).*sinc(%pi*ftofn)).*(sinc(%pi*ftofn*trf).*sinc(%pi*ftofn*trf));
dtpsdofn=trf*trf*4*%pi^2*ftofn.*ftofn.*(sinc(%pi*ftofn).*sinc(%pi*ftofn)).*(sinc(%pi*ftofn*trf).*sinc(%pi*ftofn*trf));

ppsdint=sum((sinc(%pi*ftofnlong).*sinc(%pi*ftofnlong)));
tpsdint=sum((sinc(%pi*ftofnlong).*sinc(%pi*ftofnlong)).*(sinc(%pi*ftofnlong*trf).*sinc(%pi*ftofnlong*trf)));
dtpsdint=sum(trf*trf*4*%pi^2*ftofnlong.*ftofnlong.*(sinc(%pi*ftofnlong).*sinc(%pi*ftofnlong)).*(sinc(%pi*ftofnlong*trf).*sinc(%pi*ftofnlong*trf)));



ppsdofn=100*cumsum(ppsdofn)/ppsdint;
tpsdofn=100*cumsum(tpsdofn)/tpsdint;
dtpsdofn=100*cumsum(dtpsdofn)/dtpsdint;

plot2d(ftofn, ppsdofn, style=2);
plot2d(ftofn, tpsdofn, style=5);
plot2d(ftofn, dtpsdofn, style=13);
xgrid(4);
xtitle('', 'Normalized Frequency (Multiples of Baud Rate)', 'Integrated power (percent relative)')








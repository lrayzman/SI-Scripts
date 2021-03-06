// Plot of arbitrary pulse train
// (c)2008 Lenny Rayzman

//////////SPECIFY/////////////////////
samplerate=1000;                // Number of points per period (must be multiple of 2)

//////////////////////////////////////

pulseofn=zeros(1, samplerate+1);     // Generate a single pulse
pulseofn(250:749)=ones(1, samplerate/2);
tofn=[-1:1/(samplerate/2):1];

plot2d(tofn, pulseofn, style=2, rect=[-1, -0.25, 1, 1.25]);
//xgrid(4);

trapofn=zeros(1, samplerate+1);       // Generate trapezoidal pulse
trapofn(350:649)=ones(1, 649-350+1);
plot2d(tofn, trapofn, style=5, rect=[-1, -0.25, 1, 1.25]);
//xgrid(4);








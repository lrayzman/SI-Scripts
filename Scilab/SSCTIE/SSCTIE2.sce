fssc=33e3;
f0=6e9;
a=0.005;

favg=f0*(1-0.5*a);

t=[0:1e-7:1/(2*fssc)];
foft=favg-2*f0*a*fssc*(t-0.25/fssc); //Triangular
thetadelta=f0*a*t/2-f0*a*fssc*(t^2); //Triangular


//foft=favg+f0*0.5*a*cos(2*%pi*fssc*t); //Sine
//thetadelta=(f0*0.5*a/(2*%pi*fssc))*sin(2*%pi*fssc*t); //Sine




tie=thetadelta/favg;

printf("Max tie is %0.2f ns\", max(tie)*1e9);

xinit("1");
plot2d(t*1e6,foft/1e9);
xtitle("f(t)", "Time (uS)", "Frequency (GHz)");


xinit("2");
plot2d(t*1e6,tie*1e9);
xtitle("TIE", "Time (uS)", "Interval Error (nS)");



//  Waterfall plots for n-1 redundant receivers
//
// (c)2011  L. Rayzman
// Created :      10/18/2011
// Last Modified: 10/18/2011
//
// TODO: 
// 


clear;		
getd("inc");                                   // Include Q-function definition

//////////////////////////////////////SPECIFY//////////////////////////////////////
n=[1, 2, 3, 4, 5, 10];                            // Vector representing number of receivers

x=[3:0.25:15];                                 // Display SNR range


///////////////////////////////////////////////////////////////////////////////////

Pe=Qfunc(sqrt(2)*sqrt(10^(x/10)));
leg_string=emptystr();

for i=1:length(n),

    plot2d(x,Pe^n(i), style=i+1, logflag='nl', rect=[x(1), 1e-32, x($), 1]);
    a=gca();
    a.grid=[4 4 -1];                                                            // Prettify
    a.box='on'
    a.tight_limits='on'
    leg_string(i)=strcat(["n=" sci2exp(n(i))]);
        
end

legend(leg_string, 1, %t);
xtitle("Probability of Error for n-1 Redundant Receivers", "SNR, dB", "Probability of Error, Pe");
a.title.font_size=3;                                                                            // Prettify



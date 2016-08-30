//  Coding gain plot for n-1 redundant receivers
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
n=[2:1:10];                                   // Vector representing number of receivers

x=[5, 7, 10, 12, 15];                         // Vector representing SNR(dB)


///////////////////////////////////////////////////////////////////////////////////

Pe=Qfunc(sqrt(2)*sqrt(10^(x/10)));
leg_string=emptystr();


for i=1:length(x),
 

    plot2d(n-1, Pe(i).^(1-n), style=i+1, logflag='nl'); //, rect=[n(1)-1, 1e-100 , n($)-1, 1]
    a=gca();
    a.grid=[4 4 -1];                                                            // Prettify
    a.children(1).children.line_mode="on";
    a.children(1).children.mark_mode="on";
    a.children(1).children.mark_size=1;
    a.children(1).children.mark_foreground=(i+1);
    a.box='on'
    a.tight_limits='off'
    leg_string(i)=strcat(["SNR=" sci2exp(x(i)) " dB"]);
        
end

legend(leg_string, 2, %t);
xtitle("Probability of Error Gain for n-1 Redundant Receivers", "Number of redundant receivers", "Probability of Error Gain ");
a.title.font_size=4;                                                                            // Prettify



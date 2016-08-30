// "Review  Of Stochastic Model of Digital Data Transmission" 
// Figure 1
// 
//
// (c)2009 L. Rayzman


//stacksize(64*1024*1024);

clear;				

/////////////////SPECIFY///////////////
		

sigma=1;                            // Standard deviation

mu=0;                               // mean

displayrange=4                      // X-axis range
///////////////////////////////////////

//Create a horizontal axis array

N=1000;
x=[-displayrange:displayrange/N:displayrange];

//Generate the Gaussian PDF
rho_of_x=1/sqrt(2*%pi*sigma)*exp(-(x-mu)^2/(2*sigma^2));

//Plot me
plot2d(x, rho_of_x, style=2, rect=[-displayrange 0 displayrange 0.5]);






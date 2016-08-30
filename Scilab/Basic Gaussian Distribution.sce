//This script generates a basic normalized gaussian distribution curve

/////////////////////////////////////
//Enter parameters:


//standard deviation//
sigma=0.02;
/////////////////////


//mean//
mu=0.5;
////////

////////////////////////////////////


//Create a horizontal axis array

N=1000;
x=[0:1/N:1];

//Generate the Gaussian PDF
rho_of_x=1/(2*%pi*sigma)*exp(-(x-mu)^2/(2*sigma^2));

//Plot me
plot2d(x, rho_of_x/max(rho_of_x));


//Now plot the logarithmic transformation of Gaussian PDF
xset("window", 1)
plot2d(x, log10(rho_of_x/max(rho_of_x)))





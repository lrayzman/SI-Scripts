// FFE transfer function (arbitrary FFE length)
//
// 

//stacksize(80*1024*1024);

clear;											//Clear user variables

//////////////////////////////////////////////////SPECIFY////////////////////////////////////////
c=[2.082 -0.833 -0.161 0.042 -0.086 -0.043 0.043 0.036 0.011 -0.048]; 
                                                                // FFE coeffecients vector [c1 c2 ... cn]  of arbitrary length
                                                                // c0 is assumed to be 1
                                                                    

baudrate=8e9;                             // Baud-frequency                                          
tau=1/(baudrate);                         // Tap delay (s)     

N=1024;                                   // Number of frequency points
MaxFreq=16e9;                             // Maximum plot frequency
k=[0:1:N-1];  											//Index of frequency points
f=MaxFreq*k/N;										    //Vector of frequency points (Hz)
f(1)=f(2)/10^9;
////////////////////////////////////////////////////////////////////////////////////////////////

numoftaps=length(c);

//H_FFE=(1+sum(c))*ones(f);
H_FFE=zeros(f);

// Compute FFE
for i=1:numoftaps;
  H_FFE=H_FFE+c(i)*exp(-%i*2*%pi*f*(i-1)*tau);
end 


// Plot results
subplot(2,1,1);
plot2d(f/1e9, 20*log(abs(H_FFE)), style=2);
xgrid(4);
xtitle("FFE Transfer Function" ,"Freq (GHz)", "Gain (dB)");
subplot(2,1,2);
plot2d(f(2:$)/1e9, 1e12*(-diff(atan(H_FFE))./diff(2*%pi*f)), style=2);
xgrid(4);
xtitle("", "Freq (GHz)", "Group Delay (ps)");






                                               

											


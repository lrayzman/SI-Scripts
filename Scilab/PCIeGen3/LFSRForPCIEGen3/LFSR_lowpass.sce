//Simulation of DC wander based on LFSR-generated bitstream
//
//

stacksize(64*1024*1024);

clear;																							//Clear user variables

//////////////////////////////////////////////////SPECIFY////////////////////////////////////////

///// LFSR Specifications /////
n=23;                 //Length of LFSR
c=[23 22 20 16];  //Location of feedback coefficients 
//c=[15 14];
                      //Do not include bit zero (always implied)
                      //Ex: X^3+X^2+1 => [3 2]
                      //    Corresponds to 3 bit LFSR with feedback at outputs Q2 and Q1
                      //    
                      //    Corresponds to 3 bit LFSR with feedback at outputs Q2 and Q1
                      //                       /----//
                      //                      /    //---------------------|
                      // |-------------------|     ||                     |
                      // |                    \    \\---|                 |
                      // |                     \----\\  |                 |
                      // |                              |                 |
                      // |                              |                 |
                      // |  |--------|     |---------|  |  |---------|    |
                      // |--| D0  Q0 |-----| D1   Q1 |-----| D2   Q2 |------>  output
                      //    |        |     |         |     |         |
                      //    |        |     |         |     |         |
                      //    |--------|     |---------|     |---------|
                      
lenlfsr=2^n-1;              //Length of LFSR sequence (do not modify)  


//// circuit specifications /////            
rs=20;                          //Source resistance (approximates well matched transmission line)
rl=20;                          //Load resistance
cap=160e-9;                     //AC coupling capacitance
vout=1.2;                       // Peak to peak driver voltage
deemph=6;                       // De-emphasis (ind DB)

//// Time-domain specifications /////            
bitrate=8e9;                    // UI Baud rate
samplerate=1;                   // Samples per UI (Do not alter)
deltat=1/(bitrate*samplerate);  // Sample time (Do not alter)
lenseq=1.2e7;                     //Length of sequence in UI
            
///////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////LFSR Sequence Generation////////////////////////////////////
//Seed all LFSR registers to 1s
S=ones(1,n);


//Generation of polynomial coefficients vector
cfs=zeros(1,n);

for i=1:length(c),
  cfs(length(cfs)-c(i)+1)=1;
end



//
//LFSR generator
//
//
//
// This function generates a sequence of n bits produced by the linear feedback
// recurrence relation that is governed by the coefficient vector c.
// The initial values of the bits are given by the vector k
//
//
// Inputs:
//        c   -   coefficients vector
//        k   -   initial register values
//        n   -   Length of LFSR sequence

//
//  Outputs:
//        n  - LFSR bistream
function y = lfsr(c,k,n)

y=zeros(1,n);                                           //Initialize bitstream

kln=length(k);

winId=progressionbar('LFSR calculation progress');     //Create progress bar

progbardiv=int(n/33);
c_prime=c';

for j=1:n,
   if j<=kln then
      y(j)=k(j);
   else
      y(j)=modulo(y(j-kln:j-1)*c_prime,2);   
    end   
    
    if 0==modulo(j, progbardiv) then      //Advance progress bar
      progressionbar(winId);
    end 
end
    winclose(winId);   //Remove progression bar
    
endfunction

//Compute LFSR sequence
lfsrseq_short=vout*(10^(-deemph/20))*lfsr(cfs,S,lenlfsr)-(vout*(10^(-deemph/20)))/2;  


//
//Array duplicator
//
//
//
// This function generates a matrix of length L by duplicating the entries
// of array V. If L is less than size of V then only the first L entries are
// duplicated (i.e. truncation)
//
//
// Inputs:
//        l   -   length
//        v   -   input array (must be in column form)

//
//  Outputs:
//        y  - duplicated arrays

function y = arrdup(l,v)

winId=progressionbar('Array duplicator progress');     //Create progress bar
  
y=zeros(1,l);
n=length(v);                                           // Get size of input array

k=floor(l/n);                                          //Find number of duplicates and remainder
o=modulo(l, n);                                      

progbardiv=int(k/33);


for m=0:k-1,
  y(m*n+1:(m+1)*n)=v;
  
     if 0==modulo(m, progbardiv) then      //Advance progress bar
      progressionbar(winId);
    end 

end 

if o<> 0 then
  y(l-o+1:l)=v(1:o);
end

winclose(winId);   //Remove progression bar


    
endfunction

lfsrseq=arrdup(lenseq,lfsrseq_short);
clear lfsrseq_short;

/////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////Compute LPF transfer function////////////////////////////////////

//
//Compute LPF H(S)
//
//
//               1    
// H(S) =  ---------- 
//         1+ s(rl+rs)cap

s=poly(0,'s');
tau=(rl+rs)*cap;
sl=syslin('c',1/(s*tau+1));
sld=dscr(sl,deltat);


//
//Compute time-domain wander 
//
//
output=dsimul(sld, lfsrseq);
clear lfsrseq;

//Decimate the output resolution for plot
decim_fact=100;
n=[1:decim_fact:length(output)];
output=output(n);
clear n;

xinit();
xgrid(4);
xtitle("DC Wander","UI","Wander(volts)");
plot2d([0:decim_fact:lenseq-1], output, rect=[0 -6e-3 (lenseq-1) 6e-3], nax=[1 5 0 13], style=2);



///////////////////////////////////////////////////////////////////////////////////////////////////




//Print some statistics
//printf("\n**********************************\n");
//printf("Total length of sequence: %d \n", L);
//printf("Maximum run length: %d \n", max(runlen) );
//printf("Minimum run length: %d \n", min(runlen));
//printf("DC Balance: %d\%\n", 100*numofones/L);
//printf("**********************************\n");




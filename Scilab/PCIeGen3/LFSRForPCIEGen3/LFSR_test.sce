//Implementation of a generic LFSR for the purpose of studying run lengths
//of random binary sequence

//stacksize(64*1024*1024);

clear;																							//Clear user variables

//////////////////////////////////////////////////SPECIFY//////////////////////////////////////////////////////


n=11;       //Length of LFSR
L=2^n-1;    //Length of sequence
c=[11 9];  //Location of feedback coefficients 
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
            
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Seed all to 1s
S=ones(1,n);



//Generation of polynomial coefficients vector
cfs=zeros(1,n);

for i=1:length(c),
  cfs(length(cfs)-c(i)+1)=1;
end


progbardiv=int(L/33);

//
//LFSR generator
//
//
//
function y = lfsr(c,k,n)
// This function generates a sequence of n bits produced by the linear feedback
// recurrence relation that is governed by the coefficient vector c.
// The initial values of the bits are given by the vector k

winId=progressionbar('LFSR calculation progress');     //Create progress bar
y=zeros(1,n);

kln=length(k);

for j=1:n,
   if j<=kln then
      y(j)=k(j);
   else
//      reg=y(j-kln:j-1);
      y(j)=modulo(y(j-kln:j-1)*c',2);   
    end   
    
    if 0==modulo(j, progbardiv) then      //Advance progress bar
      progressionbar(winId);
    end 
end
  winclose(winId);   //Remove progression bar
endfunction

//Compute LFSR
lfsrout=lfsr(cfs,S,L);


//Compute run length distributions
runlen=zeros(1,n);
runlenidx=1;
chgidx=1;


winId=progressionbar('Run length calculation progress');     //Create progress bar

for k=2:L
    if lfsrout(k-1)<>lfsrout(k) then
      runlenidx=k-chgidx;
      chgidx=k;
      runlen(runlenidx)=runlen(runlenidx)+1;
   end
  
      if 0==modulo(k, progbardiv) then      //Advance progress bar
      progressionbar(winId);
    end 
end

winclose(winId);   //Remove progression bar


//Build and plot a histogram of distributions
xinit("Bargraph");
bar(runlen)

//Compute wander
wander=zeros(1, L);
wanderinstlvl=0;
numofones=0;
numofzeros=0;

winId=progressionbar('Wander calculation progress');     //Create progress bar

for k=1:L
    if lfsrout(k)==1 then
       wanderinstlvl=wanderinstlvl+1;
       numofones=numofones+1;
       wander(k)=wanderinstlvl;
     else
        wanderinstlvl=wanderinstlvl-1;
        numofzeros=numofzeros+1;
        wander(k)=wanderinstlvl;
     end
        
      if 0==modulo(k, progbardiv) then      //Advance progress bar
      progressionbar(winId);
    end 
end
winclose(winId);   //Remove progression bar

//Plot wander
xinit("Wander");
plot2d([0:1:L-1], wander');

//Print some statistics
printf("\n**********************************\n");
printf("Total length of sequence: %d \n", L);
printf("Maximum run length: %d \n", length(runlen) );
printf("Minimum run length: %d \n", 1);
printf("DC Balance: %d\%\n", 100*numofones/L);
printf("**********************************\n");




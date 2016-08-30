N=4096


// Square wave
signal = ones(1,N);															

for m=1:N/4
	signal(2*m) = -1;
end 


//Sinosoid

//n=[0:1:N-1];
//signal = sin(2*%pi*n/N);


signal2=signal^2;

rms=sqrt(sum(signal2)/N)




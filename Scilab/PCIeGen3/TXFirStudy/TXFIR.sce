//Simulation of Eye Closer due to TX FIR filter at transmitter
// Based on coefficients
// 

//stacksize(16*1024*1024);

clear;																													//Clear all user created variables
getf("HSPiceUtilities.sci");                                                                                    // Include extraction function


//Data Sequences Constants

K=8;																													//Oversampling ratio

Tbit=125*10^(-12);																													// Bit interval

Nbit = 1024;																													// Number of bits in sequence


//Constants

deltaT =  Tbit / K;																													//Sampling resolution

N=round(2^(ceil(log(Nbit*K)/log(2))));																								                    //Length of sample vector

n=[0:1:N-1];																													//Index of time points

tofn=n*deltaT;																													//Vector of time points

k=[0:1:N-1];  																													//Index of frequency points

f=k/(N*deltaT);																													//Vector of frequency points (Hz)

f(1)=f(2)/10^9;

//ohmega=2*%pi*f;																													//Vector of frequency points (rad)


//SPECIFY
												
LPF=50*10^(-12);																													//LPF: rise/fall time(S)




//******************* Gaussian LPF ************************//

function [x] = Gausk(r, deltaT, N, k)
qgaussian =0.275 * r;
x=zeros(n);
for m=0:N/2-1
 if ((2 * %pi * m)/(N * deltaT) * qgaussian) > 7 then
 		x(m+1) = 0;
 else
 	 x(m+1) = exp (-((2 * %pi * m) / (N * deltaT))^2 * qgaussian^2); 
 
 end
end

for m=0:N/2-1
  x(m+N/2+1) = x(N/2 - m)
end

endfunction

//***********************************************************//



//*******************3-tap PCIe Gen3 FIR*******************//
//3-tap De-emphasis FIR circuit
//Input:
//				c : coefficients vector describing (in order)
//                  c0 - pre-cursor coefficient
//                  c1 - main cursor coefficient
//				    c2 - post-cursor coefficient
//             tbit: Unit interval of FIR
//				fr: evaluated at frequency(hz)
//
// Coefficients are to sum to 1 per specification. All coefficients
// must include proper sign
//

function [P]=FIR3tap(c, tbit, fr)
P=c(1)+c(2)*exp(-%i*2*%pi*fr*tbit)+c(3)*exp(-%i*2*%pi*fr*2*tbit);
  
endfunction
//***********************************************************//

//*******************Generate Data Sequences****************//

u=[0:1:Nbit-1];																								//Bits vector
v=[0:1:K-1];						 																		//Samples per bit vector

usize=size(u,2);
vsize=size(v,2);

xofu=zeros(u);

for m=1:usize;
	rand('uniform'); 																							//Uniform distribution in range [0:1]
	r=rand();
	if r > 0.5 then
		xofu(m) = 0.5;
	else
		xofu(m) = -0.5;
  	end;
end;

xprimeofu = zeros(1, usize * vsize);

for m=0:(usize-1)																								//Fill in samples vector
	for n=1:vsize
	xprimeofu(vsize*m+n) = xofu(m+1);
	end;
end;


Xkofu = deltaT * fft(xprimeofu, -1);

//***********************************************************//


//*********Sweep through all EQ settings*************//

results=[];
for c0=0:-0.03125:-0.1875,
  for c2=0:-0.03125:-0.3125,
    
    c1=1+c0+c2;                                                              //Compute main cursor coefficient
    coeffs=[c0,c1,c2];
    if (abs(c0+c2) < 0.375) then                                             //Consider only valid coefficients
      
      P=FIR3tap(coeffs, Tbit, f);                                            //Compute the equalizer transfer function

      Xk = Xkofu .* Gausk(LPF, deltaT, N, k)' .* P;
      xn = 1/ deltaT * fft(Xk, 1);                                           //Compute time-sequence


      //Measure eye 
     [tUI, eh, ew] = eye_measure(tofn, real(xn), 0.01, 0, Tbit);


        // Log eye parameters
          results=cat(2, results, [c0; c1; c2; tUI ; eh ; ew]);
        
        //Post results for simulation
        printf("\n*Measurements for c0=%0.5f, c1=%0.5f, c2=%0.5f", c0, c1, c2);
        printf("\n*Measured bit-period: %0.2fps", tUI*1e12);
        printf("\n*Measured Eye Height: %0.3fV", eh);
        printf("\n*Measured Eye Width: %0.2fps\n", ew*1e12 );
    else
       results=cat(2, results, [c0; c1; c2; tUI ; %nan ; %nan]);
    end  
   end
end

//***********************************************************//

//*******************Post Results****************//



results_filt=[];

//First filter out irrelevant entries
for a=1:size(results,2),
  if ~isnan(results(5,a)) & ~isnan(results(6,a)) then
    results_filt=cat(2, results_filt, results(:,a));
  end
end  


    printf("\n|-----------------------------");
    printf("|------------------------------|\n|    c0   |    c1   |    c2   ");
    printf("|   tUI    |   EH   |    EW    |\n|-----------------------------");
    printf("|------------------------------|\n");


    //Print Body
    for a=1:size(results_filt, 2),
        printf("|%8.5f |%8.5f |%8.5f |", results_filt(1,a), results_filt(2,a), results_filt(3,a));
        printf(" %.2fps | %0.3fV | %6.2fps |\n", results_filt(4,a)*1e12, results_filt(5,a), results_filt(6,a)*1e12);
    end

    printf("|-----------------------------");
    printf("|------------------------------|\n");




    //Plot Eye Height and Eye Width Results
    drawlater;
    clf();
    subplot(2,1,1);
    plot2d3([1:a], results_filt(6,:)*1e12, style=2);
    xtitle("Eye Width","Sim #", "Eye opening (ps)");
    //a=get("current_axes");
    //a.x_ticks.locations = linspace(1,numofsweeps,numofsweeps)';
    xgrid(4);
    subplot(2,1,2);
    plot2d3([1:a], results_filt(5,:), style=2);
    //a=get("current_axes");
    //a.x_ticks.locations = linspace(1,numofsweeps,numofsweeps)';
    xtitle("Eye Height","Sim #", "Eye opening (V)");
    xgrid(4);
    drawnow; 


  xinit("EWSweep");
  c0=0:0.03125:0.1875;
  c2=0:0.03125:0.3125;
  EW=matrix(results(6,:), length(c2), length(c0));
  EH=matrix(results(5,:), length(c2), length(c0));
  plot3d(c2,c0,EW*1e12, -60, 0.5, "Coeff c2 @ Coeff c0@ Eye Width (ps)", [2,1,4],[0,0.3125,0,0.1875,110,126]);
  xinit("EWSweep");
  plot3d(c2,c0,EH, -60, 11, "Coeff c2 @ Coeff c0@ Eye Height (V)", [2,1,4],[0,0.3125,0,0.1875,0.3,1]);
  
  



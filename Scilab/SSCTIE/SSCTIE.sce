//Calculation of Time Interval Error of SSC modulation

clear;
stacksize(64*1024*1024);

//******************** SPECIFY ******************************

SSCMag=0.5;                 // Modulation magnitude in percent
SSCFreq=33e3;               // Modulation frequency
SSCProf="tri";              // Modulation profile -- must be either "tri" or "sin"

f0=6e9;                     // Bit rate (1/UI)
//***********************************************************


//Triangular ssc
function  fssctri=ssctri(f0, Mag, Freq, per)

ptsnum=size(per,2);
fssctri(1:floor(ptsnum/2))=f0-2*(Mag/100)*f0*Freq*per(1:floor(ptsnum/2));
fssctri(ceil(ptsnum/2):ptsnum)=f0*(1-Mag/50)+2*(Mag/100)*f0*Freq*per(ceil(ptsnum/2):ptsnum);
endfunction

//Sine ssc
function  fsscsin=sscsin(f0, Mag, Freq, per)
  ptsnum=size(per,2);
  fsscsin=f0*((1-0.5*SSCMag/100) + (0.5*SSCMag/100)*cos(2*%pi*SSCFreq*tper))  
endfunction

//Average period (0 level of TIE)
fave=f0*(1-0.5*SSCMag/100);  


//Num of average period in one SSC cycle
numofper=floor(fave/SSCFreq);

//Frequency of one SSC cycle
tper=[1/fave:1/fave:numofper/fave];
if SSCProf=="tri" then
    foft=ssctri(f0, SSCMag, SSCFreq, tper);
elseif SSCProf=="sin" then
   foft=sscsin(f0, SSCMag, SSCFreq, tper);
end    
xinit("1");
plot2d(tper*1e6, foft/1e9);
xtitle("SSC Frequency", "Time (uS)", "Frequency (GHz)");

//Period error
toft=foft^(-1);
tdiff=(1/fave-toft);
xinit("2");
plot2d(tper*1e6, tdiff*1e12);
xtitle("Period Jitter", "Time (uS)", "Period (ps)");

//TIE
tie=tper-cumsum(toft);
xinit("3");
plot2d(tper*1e6, tie*1e9);
xtitle("TIE", "Time (uS)", "Error (ns)");

//Print results
tdiffpp=1e12*(max(tdiff)-min(tdiff));
tiediffpp=1e9*(max(tie)-min(tie));
tiediffppUI=(max(tie)-min(tie))*fave;

printf("\n**********************************\n");
printf("Average frequency: %f GHz  \n", fave/1e9);
printf("Peak-to-peak period jitter: %0.2f picoseconds  \n", tdiffpp);
printf("Peak-to-peak TIE: %0.2f nanoseconds\n", tiediffpp);
printf("Peak-to-peak TIE: %0.2f UI\n", tiediffppUI);
printf("**********************************\n");
























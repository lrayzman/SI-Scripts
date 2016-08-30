// Plot of arbitrary pulse train
// (c)2008 Lenny Rayzman

//////////SPECIFY/////////////////////
bitstream=[-1 1 1 -1 1 1 1 -1 1 -1 1 -1 -1 1 1 1 -1];
samplerate=1000;                // Number of points per period

//////////////////////////////////////

fofn=zeros(1, length(bitstream)*samplerate);     // Generate pulse train
tofn=fofn;

for i=1:length(fofn),
    fofn(i)=bitstream(int((i-1)/samplerate)+1);
    tofn(i)=i/samplerate;
end

plot2d(tofn, fofn, style=2, rect=[0, -1.25, length(bitstream), 1.25]);
xgrid(4);
xtitle(' ', 'Time (unit interval)', 'Amplitude')






//Simulation of DC wander based on LFSR-generated bitstream
//
//

//stacksize(128*1024*1024);

clear;																							//Clear user variables

n=11;
output=zeros(1,2^n-1);
fd=mopen('output_save','r')
load(fd,'n', 'output');
mclose(fd)

plot2d(output);

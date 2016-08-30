%%% link_channel_gen.m – generates channel impulse response based on
%%% measured data stored in an *.s4p file 
clear all; close all; clc;

%%% Create channel response for the simulator %%%
channelName='C:\CppSim\SimRuns\DFE\dfe_simple\channel_data.s4p';
mode='s21';
[f,H]=extract_mode_from_s4p(channelName,mode);
figure(1)
subplot(211),plot(f*1e-9,20*log10(abs(H)),'b'); 
xlabel('frequency [GHz]'); 
ylabel('Transfer function [dB]'); 
grid on;

Tsym=100e-12;	%%% Symbol Rate: e.g., Tsym = 1/fsym = 1/10 Gb/s
Ts=Tsym/100;		%%% CppSim internal time step, also used to sample
			%%% channel impulse response
imp=xfr_fn_to_imp(f,H,Ts,Tsym);
nsym_short=300*100e-12/Tsym; 	%%% persistence of the impulse response
%%% tail in the channel in terms of the
%%% number of symbols
imp_short=imp(1:floor(nsym_short*Tsym/Ts));
figure(1)
subplot(212), plot(imp,'b.-'); 
hold on; 
plot(imp_short,'r.-');
ylabel('imp response');
legend('long','short');

%%% Create the channel impulse response taps file, with appropriate
%%% sampling according to Ts used in the sims
save link_channel.dat imp_short -ascii; 

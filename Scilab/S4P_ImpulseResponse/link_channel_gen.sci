// Calculates impulse response for a system described by .s4p file and creates
// an impulse response file that can be used with "link_channel" CppSim primitive
//
// Adapted from Matlab code included in CppSim created by Prof. Vladimir Stojanovic of MIT

//  
// IMPORTANT NOTE: The Touchstone file parser is not robust. Only 4-port files supported
//
//

stacksize(64*1024*1024);
clear;		
//xdel;
//xdel;

//////////////////////////////////////SPECIFY//////////////////////////////////////

Tsym=100e-12;	                                      //Symbol Rate: e.g., Tsym = 1/fsym = 1/10 Gb/s
Ts=Tsym/100;		                                      //CppSim internal time step, also used to sample

nsym_short=300;                                     // persistence of the impulse response
                                                    // tail in the channel in terms of the
                                                    // number of symbols. 
                                                    // NOTE: Signal must completely settle to steady state=0 within this time.

channelname = "channel_data.s4p";            // Filename of S4P file describing the channel
impname = "link_channel.dat";                       // Filename of the link channel impulse response


s_mode   = "s21";                                   // S-parameters mode
Num_of_ports = 4;                                   // Number of ports. Currently fixed to 4;






/////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////Extraction Function////////////////////////////////////
function [f, H] = extract_mode_from_s4p(filename, s_mode)

//  Extracts selected 's_mode' parameters from s-parameters files
//
//
//
// Inputs:
//        filename -   Filename of the s-params file
//        s_mode   -   S-parameter selector
//
//
//  Outputs:
//        f -  frequency points
//        H  - transfer function
//


freq_unit="GHZ";        //Defaults
sim_type="S";
param_type="DB"   
z_term_type = "R";
z_term_value = 50;




stop_readheader = %F;
num_of_freq = 0;          // Number of s-param frequency points
freq_scale = 1e9;            // Frequency points scaling factor

s_data=[];
param1=[];
param2=[];

[fhandle,err]=mopen(filename, "r");  

//Parse the options header
while stop_readheader == %F,  
  if meof(fhandle) then                                           //If end of file, stop
    stop_readheader = %T;
  else      
    if mgeti(1, "uc", fhandle) == 35 then                          //If reached options line
      [scan_num, freq_unit, sim_type, param_type, z_term_type, z_term_value] = mfscanf(1, fhandle, '%s %c %s %c %f')        //read in options
      stop_readheader = %T;                                                                                                 //Stop reading header                                  
  
  end
  end
end


//Assign frequency scaling
select convstr(freq_unit, "u")
  case  "HZ"    then
      freq_scale = 1;
  case  "KHZ"   then
      freq_scale = 1e3;
  case  "MHZ"   then
      freq_scale = 1e6;
  case  "GHZ"   then
      freq_scale = 1e9;
  else
    error("Unknown frequency unit %s",freq_unit);
    return;
end
  

while ~meof(fhandle),
    textline = mgetl(fhandle, 1);                                                                                       //Read in line
    if ~(length(textline) == 0) then                                                                                    //If blank line
        if ~(part(textline, 1) == '!') then                                                                             //or comment line. TODO: NEEDS IMPROVEMENT HERE                                                                                
           [scan_num, col0,col1,col2,col3,col4,col5,col6,col7,col8] = msscanf(textline, '%f%f%f%f%f%f%f%f%f');          //Read in the data
           if (scan_num == 9) then                                                                                      //This is start of the data block for given frequency                            //Just read line containing frequenies
            offset = 0;                                                                                   
            num_of_freq = num_of_freq + 1;
            f(num_of_freq) = col0*freq_scale;
            s_data(num_of_freq, offset*8+1:offset*8+8) = [col1,col2,col3,col4,col5,col6,col7,col8];
           elseif (scan_num == 8)  then                                                                                 //This is continuation of the data block                                                      
            offset = offset + 1;
             s_data(num_of_freq, offset*8+1:offset*8+8) = [col0, col1,col2,col3,col4,col5,col6,col7];
           end
         end
    end
    
end
  
mclose(fhandle);

//Select data for Port
select convstr(s_mode, "u")
    case "S11"
        param1=s_data(:,1)';
        param2=s_data(:,2)';
    case "S12"
        param1=s_data(:,3)';
        param2=s_data(:,4)';
    case "S13"
        param1=s_data(:,5)';
        param2=s_data(:,6)';
    case "S14"
        param1=s_data(:,7)';
        param2=s_data(:,8)';
    case "S21"
        param1=s_data(:,9)';
        param2=s_data(:,10)';
    case "S22"
        param1=s_data(:,11)';
        param2=s_data(:,12)';
    case "S23"
        param1=s_data(:,13)';
        param2=s_data(:,14)';
    case "S24"
        param1=s_data(:,15)';
        param2=s_data(:,16)';
    case "S31"
        param1=s_data(:,17)';
        param2=s_data(:,18)';
    case "S32"
        param1=s_data(:,19)';
        param2=s_data(:,20)';
    case "S33"
        param1=s_data(:,21)';
        param2=s_data(:,22)';
    case "S34"
        param1=s_data(:,23)';
        param2=s_data(:,24)';
     case "S41"
        param1=s_data(:,25)';
        param2=s_data(:,26)';
    case "S42"
        param1=s_data(:,27)';
        param2=s_data(:,28)';
    case "S43"
        param1=s_data(:,29)';
        param2=s_data(:,30)';
    case "S44"
        param1=s_data(:,31)';
        param2=s_data(:,32)';
    else
        error("unknown mode %s", s_mode);
end


//Frequency matrix conversion
select convstr(param_type, "u")
    case 'MA'
        H=param1.*exp(%i*param2*%pi/180);
    case 'RI'
        H=param1+%i*param2;
    case 'DB'
        H=10.^(param1/20).*exp(%i*param2*%pi/180);
    else
        error("Unknown parameter type %s",param_type)
        return;
end

//Transpose frequency vector
f=f';

endfunction


//////////////////////////////////////Transfer Function to Impulse function////////////////////////////////////
function imp=xfr_fn_to_imp(f,H,Ts,Tsym)

// Create impulse response from transfer function in frequency domain  
// Impulse response is interpolated to the sample time required by the
// simulator
//
//
// Inputs:
//        f -   frequency points in Hz
//        H -   Transfer function
//        Ts - Simulator timestep
//        Tsym - Symbol (UI) period
//
//  Outputs:
//        imp -  impulse response
//

num_fft_pts=2^12;

// set the symbol frequency
f_sym=1/Tsym;
// get the maximum sampling frequency from the transfer function
f_sym_max=2*max(f);
// stop the simulation if the symbol frequency is smaller than the maximum
// measured sampling frequency

if (f_sym > f_sym_max) then 
   error("Max input frequency too low for requested symbol rate, can''t interpolate!\n");
   return;
end	


f_sym_max=f_sym*floor(f_sym_max/f_sym);

Hm=abs(H);
Hp=atan(imag(H),real(H))



// need to force phase to zero at zero frequency to avoid funky behavior


if f(1)==0 then
   Hm_ds=[Hm(:, $-1:-1:2) Hm];
   Hp_ds=[-Hp(:,$-1:-1:2) Hp];
   fds=[-f(:,$-1:-1:2) f];
   fds_m = fds; 
   fds_p = fds;
else
   Hm_ds=[Hm(:, $-1:-1:1) Hm];
   Hp_ds=[-Hp(:,$-1:-1:1) 0 Hp];
   fds_m=[-f(:,$-1:-1:1) f];
   fds_p=[-f(:,$-1:-1:1) 0 f];
end


//Spline interpolation
df = (f_sym_max/2)/num_fft_pts;
f_ds_interp = mtlb_imp(mtlb_a(-f_sym_max/2,df),df,f_sym_max/2);
Hm_ds_spln = splin(fds_m, Hm_ds);
Hm_ds_interp = interp(f_ds_interp, fds_m, Hm_ds, Hm_ds_spln, "natural")
Hp_ds_unwrap = unwrap(Hp_ds);    
Hp_ds_spln = splin(fds_p, Hp_ds_unwrap);
Hp_ds_interp = interp(f_ds_interp, fds_p, Hp_ds_unwrap, Hp_ds_spln, "natural")

Hm_ds_interp_sh = mtlb_fftshift(Hm_ds_interp);
Hp_ds_interp_sh = mtlb_fftshift(Hp_ds_interp);


H_ds_interp_sh = Hm_ds_interp_sh .*exp(%i*Hp_ds_interp_sh);


// impulse response from ifft of interpolated frequency response



imp = mtlb_ifft(H_ds_interp_sh);
imp_r = real(imp);

dt_sym = 1/f_sym_max;


//refit data into simulator's time step
dt_time = mtlb_imp(0,dt_sym,dt_sym*(max(size(imp_r))-1));
time = mtlb_imp(0,Ts,dt_time($));
imp = (interp1(dt_time,imp_r,time,"spline")*Ts)/dt_sym;


endfunction

//////////////////////////////////////Unwrap Matlab Emulation function///////////////////////////////
function unwrp = unwrap(wrapped)

//
//  Emulation of Matlab unwrap function which adjust largest deviation
//  between adjacent phase entries to maximum of +pi or -pi
//
// Inputs:
//        wrapped - wrapped phase vector. Must be 1-D vector with at least 2 entries
//
//  Outputs:
//        unrwp -  unwrapped phase vector
//
//
// TODO: Implement a multi-dimensional vector unwrapping
//

vect_size = size(wrapped);


if vect_size(2) == 1 then           //Transpose row  vector into column vector, if necessary              
  wrapped = wrapped';
else
  wrapped = wrapped;
end


lngth = size(wrapped,2);

//Set the phase at first entry
unwrp(1) = wrapped(1);

//Main loop
for i = 2:lngth,
    k = 0;                                                  //Reset multiplier
    ph_delta = wrapped(i) - unwrp(i-1);                      
    if abs(ph_delta) > %pi then                             //If phase jump is greater than Pi
        if ph_delta < 0 then                                //If negative phase jump
            k = round(abs(ph_delta)/(2*%pi));
        else                                                //If positive phase jump                        
            k = -round(abs(ph_delta)/(2*%pi));
        end
    end
     unwrp(i) = wrapped(i) + 2*k*%pi;                       //Adjust phase by factor of k*2pi 
end


unwrp=unwrp';

endfunction


//////////////////////////////////////Main Routine////////////////////////////////////


//Extract frequency response from S4P file
[f,H]=extract_mode_from_s4p(channelname,s_mode);

//Plot it
xinit("Graph1")
plot2d(f*1e-9,20*log10(abs(H)), axesflag=1,  style=2);
xgrid(12)
xtitle("Transfer Function", "frequency [GHz]", "Transfer function [dB]");



//Calculate impulse response
imp=xfr_fn_to_imp(f,H,Ts,Tsym);

Ts_num_short = floor(nsym_short*(Tsym/Ts));
imp_short=imp(1:Ts_num_short);


xinit("Graph2")
//imp_plot_x = (1:Ts_num_short);                //TODO: Plot in terms of Symbols
//imp_plot_x = floor(imp_plot_x/(Tsym/Ts));    
plot2d(imp_short);
xtitle("Impulse response", "Sample", "Amplitude");

//Save data to file
savematfile(impname, "imp_short", "-ascii", "-tabs");









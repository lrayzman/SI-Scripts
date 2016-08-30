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

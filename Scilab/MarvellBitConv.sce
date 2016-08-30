clear;

//Enter Marvell values
txt=['Default';'Overwrite';];
readback=x_mdialog('Enter values',txt,['';'']);

default=readback(1);
overwrite=readback(2);


//Convert default to binary

default_bin=[];

for i=0:7,
  index=i+1;
  c=part(default,index);
  
  select c
    case '0' then default_bin(i*4+1:i*4+4)=['0','0','0','0'];
    case '1' then default_bin(i*4+1:i*4+4)=['0','0','0','1'];
    case '2' then default_bin(i*4+1:i*4+4)=['0','0','1','0'];
    case '3' then default_bin(i*4+1:i*4+4)=['0','0','1','1'];
    
    case '4' then default_bin(i*4+1:i*4+4)=['0','1','0','0'];
    case '5' then default_bin(i*4+1:i*4+4)=['0','1','0','1'];
    case '6' then default_bin(i*4+1:i*4+4)=['0','1','1','0'];
    case '7' then default_bin(i*4+1:i*4+4)=['0','1','1','1'];
    
    case '8' then default_bin(i*4+1:i*4+4)=['1','0','0','0'];
    case '9' then default_bin(i*4+1:i*4+4)=['1','0','0','1'];
    case 'A' then default_bin(i*4+1:i*4+4)=['1','0','1','0'];
    case 'B' then default_bin(i*4+1:i*4+4)=['1','0','1','1'];
    
    case 'C' then default_bin(i*4+1:i*4+4)=['1','1','0','0'];
    case 'D' then default_bin(i*4+1:i*4+4)=['1','1','0','1'];
    case 'E' then default_bin(i*4+1:i*4+4)=['1','1','1','0'];
    case 'F' then default_bin(i*4+1:i*4+4)=['1','1','1','1'];
    end
  
end

if size(default_bin,2) ~= 32 then
  
   x_message_modeless("Error: Invalid number of Default value characters") 
   abort;
end 


//Cleanup overwrite
length_overwrite_len=length(overwrite);

fixed_overwrite=[];
fixed_overwrite_index=1;

for i=1:length_overwrite_len,

  c=part(overwrite,i);
  if (c=='x' | c=='0' | c=='1') then
      fixed_overwrite_bin(fixed_overwrite_index)=c;
      fixed_overwrite_index=fixed_overwrite_index+1;
  end
end 

fixed_overwrite_bin=fixed_overwrite_bin';

//pause
//size(fixed_overwrite_bin,2)

if size(fixed_overwrite_bin,2) ~= 32 then
    x_message_modeless("Error: Invalid number of Overwrite value characters")  
   abort;
end 


final_value=[];


//Merge the two values
for i=1:32,
  
    if (fixed_overwrite_bin(i)=='x') then
      final_value(i)=default_bin(i);
    else
      final_value(i)=fixed_overwrite_bin(i);
    end
end 

final_value=final_value';

final_value_hex=[];

//Convert to hex

for i=0:7,
//  c=part(default,index);
  
  select final_value(i*4+1:i*4+4)
    case ['0','0','0','0'] then final_value_hex(i+1)='0';
    case ['0','0','0','1'] then final_value_hex(i+1)='1';
    case ['0','0','1','0'] then final_value_hex(i+1)='2';
    case ['0','0','1','1'] then final_value_hex(i+1)='3';
    
    case ['0','1','0','0'] then final_value_hex(i+1)='4';
    case ['0','1','0','1'] then final_value_hex(i+1)='5';
    case ['0','1','1','0'] then final_value_hex(i+1)='6';
    case ['0','1','1','1'] then final_value_hex(i+1)='7';
    
    case ['1','0','0','0'] then final_value_hex(i+1)='8';
    case ['1','0','0','1'] then final_value_hex(i+1)='9';
    case ['1','0','1','0'] then final_value_hex(i+1)='A';
    case ['1','0','1','1'] then final_value_hex(i+1)='B';
    
    case ['1','1','0','0'] then final_value_hex(i+1)='C';
    case ['1','1','0','1'] then final_value_hex(i+1)='D';
    case ['1','1','1','0'] then final_value_hex(i+1)='E';
    case ['1','1','1','1'] then final_value_hex(i+1)='F';
    end
  
end

x_message_modeless(strcat(final_value_hex));

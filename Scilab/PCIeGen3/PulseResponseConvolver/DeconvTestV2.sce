// Deconvolution algorithm test

clear;

lenofn=21;

M=3;

termsohofn=zeros(lenofn, lenofn);
termsohofn(1,1)=1;

for i=2:lenofn,  //for all time points

termscolm=zeros(1,lenofn);
termscolm(i)=1;

      last=1;

      //find the -Mth point of h
      if i>M then
         last=i-M+1;
      end  
       
     //for current point minus to -Mth point find all points of p[n]
      for k=i-1:-1:last,
         
         //get previous column of vector
         termscolm=termscolm+-1*termsohofn(:,k)';
      end 
            
termsohofn(:,i)=termscolm';
end  


//Shortcut
termsmscolmfull=zeros(1,lenofn);
termsmscolmfull(1:M:$)=1;
termsmscolmfull(2:M:$)=-1;
termsmscolmfull=termsmscolmfull(:,$:-1:1);

termsohofn2=zeros(lenofn, lenofn);

for i=1:lenofn,
  termsohofn2(:,i)=[termsmscolmfull($-i+1:$),zeros(1,lenofn-(i))]';
end











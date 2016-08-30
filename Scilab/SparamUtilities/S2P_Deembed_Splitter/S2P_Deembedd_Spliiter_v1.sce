// ======================   S-params splitter===========================
// 
// Split De-embedding procedure
//
// (c)2011  L. Rayzman
//
//
// Created      : 11/17/2011
// Last Modified: 
//
//  Note: Only 2-port S-params supported at this time
// ====================================================================
// ====================================================================

clear;	

//stacksize(128*1024*1024);	

///////////////////////////////////////////////////////////////////////////////
fsparam = emptystr();                           // Filename of S2p source file
spfreqs=[];                                     // Frequency points vector
spdata=[];                                      // Source S-param matrix data
spdata_split=[];                                // Split s-param matrix data

tdata=[];                                       // T-parameters data
tdata_split=[];                                 // Split t-param matrix data

C=[];                                           // Eigenvector matrix
Lambda=[];                                       // Eigenvalue diagonal

numofports=0;                                   // Number of ports
numofreqs=0;                                    // Number of frequencies

entries_choice=emptystr();                      // Text matrix that describes available entries to view
entry_idx=0;                                    //  

srow=1;                                         // Set the Sxy to plot
scol=1;
spdata_row_col=[];                              // Data points from Sxy where x=row y=col



///////////////////
// Get Scilab Version
///////////////////
version_str=getversion();
version_str=tokens(version_str,'-');
version_str=tokens(version_str(2),'.');
version(1)=msscanf(version_str(1), '%d');
version(2)=msscanf(version_str(2), '%d');


if (version(1)<5) then
  error("Invalid Scilab version. Version 5.2 or greater is required");
elseif (version(2) < 2) then
  error("Invalid Scilab version. Version 5.2 or greater is required");
end    

///////////////////
// Setup files/directories
///////////////////
fsparam=uigetfile("*.s2p", "",  "Please choose S-parameters file");                                                

if fsparam==emptystr() then
    messagebox("Invalid source file selection. Script aborted", "","error","Abort");      
    abort;
end

///////////////////
// Read touchstone file
///////////////////
  
[spfreqs,spdata] =sptlbx_readtchstn(fsparam);

numofports=size(spdata,1);                                               //Find number of ports

if numofports <> 2 then
    messagebox("Only 2-port parameters are supported at this time. Script aborted", "","error","Abort");      
    abort;
end

numofreqs=size(spdata,3);                                                //Find number of frequency points


///////////////////
// Plot
///////////////////


//  S11 & S22 plot and make pretty
drawlater();
spdata_row_col=matrix(spdata(1,1,:), 1, numofreqs);   


subplot(211);                                                                
plot2d(spfreqs, 20*log10(abs(spdata_row_col)), style=2);                               // Magnitude plot
subplot(212);   
plot2d(spfreqs, 180/%pi*atan(imag(spdata_row_col), real(spdata_row_col)), style=2);    // Phase plot

             
spdata_row_col=matrix(spdata(2,2,:), 1, numofreqs);  
subplot(211);                                                                
plot2d(spfreqs, 20*log10(abs(spdata_row_col)), style=5);                               // Magnitude plot
subplot(212);   
plot2d(spfreqs, 180/%pi*atan(imag(spdata_row_col), real(spdata_row_col)), style=5);    // Phase plot

                                                                                       // Prettiness
a=gcf();                                                                               // Add gray to the colormap
a.color_map(33,:)=[0.85 0.85 0.85];    
subplot(211);                                                                       
xtitle("S11/S22", "Frequency(Hz)", "Magnitude(dB)");  
a=gca();
a.grid=[33,33];                                                                         // Turn on grid
subplot(212);  
a=gca();
a.grid=[33,33]; 
xtitle("S11/S22", "Frequency(Hz)", "Phase(Deg)");

drawnow();


//  S12 & S21 plot and make pretty
xinit()
drawlater();
spdata_row_col=matrix(spdata(1,2,:), 1, numofreqs);   


subplot(211);                                                                
plot2d(spfreqs, 20*log10(abs(spdata_row_col)), style=2);                               // Magnitude plot
subplot(212);   
plot2d(spfreqs, 180/%pi*atan(imag(spdata_row_col), real(spdata_row_col)), style=2);    // Phase plot

             
spdata_row_col=matrix(spdata(2,1,:), 1, numofreqs);  
subplot(211);                                                                
plot2d(spfreqs, 20*log10(abs(spdata_row_col)), style=5);                               // Magnitude plot
subplot(212);   
plot2d(spfreqs, 180/%pi*atan(imag(spdata_row_col), real(spdata_row_col)), style=5);    // Phase plot

                                                                                       // Prettiness
a=gcf();                                                                               // Add gray to the colormap
a.color_map(33,:)=[0.85 0.85 0.85];    
subplot(211);                                                                       
xtitle("S12/S21", "Frequency(Hz)", "Magnitude(dB)");  
a=gca();
a.grid=[33,33];                                                                         // Turn on grid
subplot(212);  
a=gca();
a.grid=[33,33]; 
xtitle("S12/S21", "Frequency(Hz)", "Phase(Deg)");

drawnow();

spdata_row_col=[];


///////////////////
// Compute the split S-params
///////////////////

// Step 1:  Convert into T-parameters
tdata=zeros(2,2,numofreqs);                                                    // Initialize t-matrix

tdata(1,1,:)=(matrix(spdata(2,1,:), 1, numofreqs))^(-1);                                           // T11=1/S21

tdata(1,2,:)=(-1)*(matrix(spdata(2,2,:), 1, numofreqs)) ...                                     // T12=-S22/S21
             ./(matrix(spdata(2,1,:), 1, numofreqs));

tdata(2,1,:)=(matrix(spdata(1,1,:), 1, numofreqs)) ...                                          // T21=S11/S21
             ./(matrix(spdata(2,1,:), 1, numofreqs));             

tdata(2,2,:)=(matrix(spdata(2,1,:), 1, numofreqs).*matrix(spdata(1,2,:), 1, numofreqs) ...   // T22=(S21S12-S11S22)/S21
             - matrix(spdata(1,1,:), 1, numofreqs).*matrix(spdata(2,2,:), 1, numofreqs))...
             ./(matrix(spdata(2,1,:), 1, numofreqs));             


// Step 2: Diagonalize. Check to ensure that it is diagonizable
C=zeros(2,2,numofreqs);    
Lambda=zeros(2,2,numofreqs); 
 

//winId=waitbar('Diagonalization Progress');
for i=1:numofreqs
    [C(:,:,i), Lambda(:,:,i)]=spec(tdata(:,:,i));
    if rank(C(:,:,i))<>2 then 
        messagebox("Cannot diagonalize T-parameters. Script aborted", "","error","Abort");      
        clear;
        winclose(winId);
        abort;
    end
//
//    if(modulo(i, (numofreqs/100))==1) then
//        waitbar(i/numofreqs,winId);
//    end
end
clear tdata;
//winclose(winId);

// Step 3: Find square root
Lambda=sqrt(Lambda);
tdata_split=zeros(2,2,numofreqs);

// Step 4: Compute split T-parameter using eigenvectors
//winId=waitbar('T-param Splitting Progress');
for i=1:numofreqs
    tdata_split(:,:,i)=C(:,:,i)*Lambda(:,:,i)*inv(C(:,:,i));
//
//    if(modulo(i, (numofreqs/100))==1) then
//        waitbar(i/numofreqs,winId);
//    end
end
//winclose(winId);


// Step 5: Convert to S-param
spdata_split=zeros(2,2,numofreqs);                                            // Initialize S-matrix 


spdata_split(1,1,:)=matrix(tdata_split(2,1,:), 1, numofreqs)..
                    ./(matrix(tdata_split(1,1,:), 1, numofreqs));                                            // S11=T21/T11
                    
spdata_split(1,2,:)=(matrix(tdata_split(1,1,:), 1, numofreqs).*matrix(tdata_split(2,2,:), 1, numofreqs) ...   // S12=(T11T22-T21T12)/T11
                    - matrix(tdata_split(2,1,:), 1, numofreqs).*matrix(tdata_split(1,2,:), 1, numofreqs))...
                    ./(matrix(tdata_split(1,1,:), 1, numofreqs));   

spdata_split(2,1,:)=(matrix(tdata_split(1,1,:), 1, numofreqs))^(-1);                                           // S21=1/T11

spdata_split(2,2,:)=(-1)*(matrix(tdata_split(1,2,:), 1, numofreqs)) ...                                       // S22=-T12/T11
                     ./(matrix(tdata_split(1,1,:), 1, numofreqs));


clear tdata_split;

///////////////////
// Plot
///////////////////


//  S11 & S22 plot and make pretty
drawlater();
spdata_row_col=matrix(spdata_split(1,1,:), 1, numofreqs);   


xinit();
subplot(211);                                                                
plot2d(spfreqs, 20*log10(abs(spdata_row_col)), style=2);                               // Magnitude plot
subplot(212);   
plot2d(spfreqs, 180/%pi*atan(imag(spdata_row_col), real(spdata_row_col)), style=2);    // Phase plot

             
spdata_row_col=matrix(spdata_split(2,2,:), 1, numofreqs);  
subplot(211);                                                                
plot2d(spfreqs, 20*log10(abs(spdata_row_col)), style=5);                               // Magnitude plot
subplot(212);   
plot2d(spfreqs, 180/%pi*atan(imag(spdata_row_col), real(spdata_row_col)), style=5);    // Phase plot

                                                                                       // Prettiness
a=gcf();                                                                               // Add gray to the colormap
a.color_map(33,:)=[0.85 0.85 0.85];    
subplot(211);                                                                       
xtitle("S11/S22", "Frequency(Hz)", "Magnitude(dB)");  
a=gca();
a.grid=[33,33];                                                                         // Turn on grid
subplot(212);  
a=gca();
a.grid=[33,33]; 
xtitle("S11/S22", "Frequency(Hz)", "Phase(Deg)");

drawnow();

//  S12 & S21 plot and make pretty
xinit()
drawlater();
spdata_row_col=matrix(spdata_split(1,2,:), 1, numofreqs);   


subplot(211);                                                                
plot2d( 20*log10(abs(spdata_row_col)), style=2);                               // Magnitude plot
subplot(212);   
plot2d( 180/%pi*atan(imag(spdata_row_col), real(spdata_row_col)), style=2);    // Phase plot

             
spdata_row_col=matrix(spdata_split(2,1,:), 1, numofreqs);  
subplot(211);                                                                
plot2d(spfreqs, 20*log10(abs(spdata_row_col)), style=5);                               // Magnitude plot
subplot(212);   
plot2d(spfreqs, 180/%pi*atan(imag(spdata_row_col), real(spdata_row_col)), style=5);    // Phase plot

                                                                                       // Prettiness
a=gcf();                                                                               // Add gray to the colormap
a.color_map(33,:)=[0.85 0.85 0.85];    
subplot(211);                                                                       
xtitle("S12/S21", "Frequency(Hz)", "Magnitude(dB)");  
a=gca();
a.grid=[33,33];                                                                         // Turn on grid
subplot(212);  
a=gca();
a.grid=[33,33]; 
xtitle("S12/S21", "Frequency(Hz)", "Phase(Deg)");

drawnow();


///////////////////////////////////////////////////////////////////////////////////

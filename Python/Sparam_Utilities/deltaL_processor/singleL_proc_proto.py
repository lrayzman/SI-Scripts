# -*- coding: utf-8 -*-
#
# ============================================================================
# ============================================================================
# 
#
#  THIS IS A PROTOTYPE FOR A SINGLE LINE DERIVATION
#
# Performs a single line loss and delay calculation from (a set of) s2p or s4p files 
#
# 
# It also computes per unit length canonnical loss equation fit to loss data according 
#  to:
#   
#                                      
#     loss(dB)=length in inch (DC loss + alpha*f^0.5 + beta*f + gamma * f^2)
#
#       where 
#            alpha, beta, gamma -  loss coefficients per inch
#
# When multiple files are presented in each set, the output is averaged
# 
#  
#
# (c)2019  L. Rayzman
#
#  
# Created      : 10/08/19 
# Last Update  : 10/08/19 -- 
#
#
#
#
#   INPUT LIST FILE FORMAT:
#      config name 1; ; len 1; line s*p filename(s) 1, line s*p filename(s) 2, ..., line s*p filename(s) n
#      config name 2; ; len 2; line s*p filename(s) 1, line s*p filename(s) 2, ..., line s*p filename(s) n
#        ....
#      config name m; ; len m; line s*p filename(s) 1, line s*p filename(s) 2, ..., line s*p filename(s) n
#          
# 
#   OUTPUT:
#      For each config name, the tool will generate a loss per inch and group delay per inch 
#      files in csv format in the specified output directory
#      
#      Additional CSV file will be generated in the same directory 
#      listing loss fit coefficients for all configurations
#      
#
#   Notes: 
#      - Config name should only have valid filename characters (such as alphanumerics + underscore)
#      - Length units are in inches, frequencies in hertz
#      - Currently only s2p or s4p input files are supported
#      - s*p files in each set must be of same port count
#      - No error checking is done on files from each set. 
#        It's assumed they are of same dimensions 
#
# 
#
#  TODO:  
#
#    - BUG: a configuration listing a single s-parameter file does not work
#    - delay curve fit: try applying a smoothing function to help improve convergence
#    
#
# ============================================================================
# ============================================================================
#


#
# ============================================================================
# ============================= IMPORTS ======================================
#

import sys, os
import getopt

import numpy as np
import scipy.optimize as optimize

import skrf as rf

import pandas as pds

import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages


#
# ============================================================================
# ============================== SPECIFY =====================================
#





#
# ============================================================================
# ============================= FUNCTIONS ====================================
#



# Function to read in s-parameter and extract the loss and delay data
def sxp_util_guess_mapmode(sdata):
    '''function that guesses the port mapping for 2n port files
     
     Based on original Scilab code
    
    
     
    
    Parameters
    ----------
    sdata : numpy ndarray
        original fxnxn  SxP data (including frequency vector)
    
    Returns
    -------
    smapmode : int
        SxP mapping mode
        
        0 ==> Unable to guess/unknown
        
        1 ==> 1-------- 2   (Odd/Even Mapping)
              3-------- 4
         
          
        2 ==> 1 ------- n/2+1 (Sequential Mapping)
              2 ------- n/2+2 (Canonical form for mode conversion)
                                                     
    '''      

    bDetIl = True
    smapmode = 0
    
    
    # Get number of ports
    numofports = np.shape(sdata)[1] 
    
    if numofports % 2:
        return 0
    
    # Nothing to do for 2 port
    if numofports == 2:
        return 1
    
    #
    # Check odd/even mapping 
    #
    for i in range(int(numofports/2)-1):

        # First first frequency point for "thru"
        TempM0 = sdata[0, 2*i+1, 2*i]
            
        # Simple check for amplitude @ low freq
        
        if (np.abs(TempM0) < 0.9):
            bDetIl = False
            break
    
    #
    # If not odd/even mapping, check seq
    #
    if not bDetIl:
        
        bDetIl = True
        
        for i in range(int(numofports/2)-1):
        
            # First first frequency point for "thru"
            TempM0 = sdata[0,i + int(numofports/2), i]
            
            # Simple check for amplitude @ low freq
            if (np.abs(TempM0) < 0.9):
                bDetIl = False
                break

        # If got to here, then it is sequential mapping
        if bDetIl:
            smapmode = 2
    
    # If found all already, then it was odd/even mapping
    else:
        smapmode = 1

    
    return smapmode
    

# Function to read in s-parameter and extract the loss and delay data
def get_sxp_data(filename, lfreq):
    '''reads data from s2p or s4p file

    Parameters
    ----------
    filename : string
        filename of the input s2p or s4p file
        
    lfreq : truncate read data below this frequency

    Returns
    -------
    freq_vec : numpy array
        read in frequency vector
    loss_vec: numpy array
        read in loss data
    gdelay_vec: numpy array
        read in group delay
    '''   
    
    
    # Read in s-paramter data
    try:
        sp_network = rf.Network(filename)
    except:
       sys.exit('Unable to read s-parameter file:' + filename)
       
    numofports = np.shape(sp_network.s)[1]

    # raise error if it's not a 2- or 4-port network
    if (numofports != 2) and (numofports != 4):
        sys.exit('Only 2- or 4-port files supported:' + filename)
        
        
    smapmode = sxp_util_guess_mapmode(sp_network.s)
    
    print('get_sxp_data: detected mode ' + str(smapmode) + ' for ' + filename)
    
    freq_vec = sp_network.frequency.f
    
    # For 4-port case
    if numofports == 4:
        
        if  smapmode == 0:
            sys.exit('Unable to determine s-parameter mapping mode for:' + filename)         
        
        # odd/even mapping
        elif  smapmode == 1:
            sp_network.renumber([0,1,2,3], [0,2,1,3])
        
        # Don't need to flip anything for sequential mode
       
        # Convert to mixed mode
        sp_network.se2gmm(p=2) 
        
    
    
    
    # Extract loss and gdelay vectors with truncation of frequencies below lfreq
    lfidx = np.min(np.where(freq_vec >= lfreq))
    
    loss_vec = np.abs(sp_network.s_mag[lfidx:,1,0])
#    phase_vec = sp_network.s_deg[lfidx:,1,0]
    gdelay_vec = np.real(sp_network.group_delay[lfidx:,1,0])        
    
    

    
    freq_vec = freq_vec[lfidx:]
    
    
    return freq_vec, loss_vec, gdelay_vec


# Parse the input files list
def parse_inlist(in_list):
    ''' parse input file list

    Parameters
    ----------
    in_list : string
        filename of the input file list

    Returns
    -------
    list_content : dict
        parsed list data
        
    ''' 
    list_content  = {}
    
    try:
        with open(in_list) as fh_inlinst:
            try:
                inlist_lines = fh_inlinst.readlines()
            except:
                sys.exit('Unable to read input list file')
    except:
        sys.exit('Unable to open input list file. Please check filename')
        
  
    line_cnt = 1
    for line in inlist_lines:
        
        line = line.split(sep=';')
        
        if any([not field for field in line]):
            sys.exit('Input file syntax error at line #' + str(line_cnt))
        
        # Check for valid number of fields
        if len(line) != 3:
            sys.exit('Input file syntax error at line #' + str(line_cnt))
        
        
        list_content.update({line[0] : {'files' : line[2].split(sep=','),
                                        'len' : float(line[1])}})
        
        
        line_cnt += 1

    return list_content



# Loss fit function
def loss_fit_coeffs(f, loss_data, dc_loss):    
    
    loss_fit_1ststg_func = lambda f, alpha, beta: alpha*(f**0.5) + beta*f
    loss_fit_2ndstg_func = lambda f, beta: beta*f
    loss_fit_3rdstg_func = lambda f, gamma: gamma*(f**2)
    
    
    alpha = 0
    beta = 0
    gamma = 0
    
    # Sub 0.5GHz band for alpha fit
    band1_idx = np.abs(f-1e9).argmin()
    
    # 1 parameter fit
    try:
        [alpha, beta], pcov  = optimize.curve_fit(loss_fit_1ststg_func, f[:band1_idx], loss_data[:band1_idx]-dc_loss, p0=[0,0])
    except RuntimeError:
        sys.exit('stg 1 param loss lsq failed to minimize')
    except ValueError:
        sys.exit('stg 1 param loss lsq failed with wrong input data')
    except optimize.OptimizeWarning:
        sys.exit('stg 1 param loss lsq failed to estimate covariance error')


    
    # Add 15GHz band for beta fit
    band2_idx = np.abs(f-15e9).argmin()
    try:
        [beta], pcov  = optimize.curve_fit(loss_fit_2ndstg_func, f[band1_idx:band2_idx], loss_data[band1_idx:band2_idx]- dc_loss - (alpha*f[band1_idx:band2_idx]**0.5), p0=[beta])
    except RuntimeError:
        sys.exit('stg 2 param loss lsq failed to minimize')
    except ValueError:
        sys.exit('stg 2 param loss lsq failed with wrong input data')
    except optimize.OptimizeWarning:
        sys.exit('stg 2 param loss lsq failed to estimate covariance error')    
    
    
    
    #Add >15GHz band for gamma fit  
    if f.max() > 15e10:
        try:
            [gamma], pcov  = optimize.curve_fit(loss_fit_3rdstg_func, f[band2_idx:], loss_data[band2_idx:band2_idx]- dc_loss - (alpha*f[band2_idx:]**0.5 + beta*f[band2_idx:]))
        except RuntimeError:
            sys.exit('stg 3 param loss lsq failed to minimize')
        except ValueError:
            sys.exit('stg 3 param loss lsq failed with wrong input data')
        except optimize.OptimizeWarning:
            sys.exit('stg 3 param loss lsq failed to estimate covariance error')            
            
            
        
    # Synthesize 
    loss_syn = dc_loss + alpha*(f**0.5) + beta*f + gamma *(f**2)
    
    return alpha, beta, gamma, loss_syn


# Group delay fit function

def dly_fit_coeffs(f, dly_data, dc_cond):   
#    
#    #
#    # This is using Djorjevic-Sarkar model
#    #
#    # Where effective relative permitivity is given by
#    #
#    # eps_r(w) = eps_inf(w) + K/2  * ln(wb^2 - w^2 / wa^2  - w^2)          
#    #
#    #      where K = delta_eps / ln(wb/wa)
#
#    


    # Some constants
    c = 299792458
    in_m = 39.3700787
    eps_not = 8.8541878176e-12

    # Calculate Dk
    eps_data = (dly_data*c*in_m)**2


    eps_fit_func = lambda f, eps_inf, K, f_a, f_b: eps_inf + 0.5*K*np.log((f_b**2 + f**2)/(f_a**2 + f**2))
    
    
    #
    # Coefficients
    #
    # initial values
    eps_inf = 4
    f_a = 1e4
    f_b = 200e9
    K=0.05
    
  
    
    # Reject very low freqs
    band_idx1 = range(np.where(f >= 0.05e9)[0][0], len(f)-1)
    
    
    # Try LM algorithm (unbounded)
    try:
        [eps_inf, K, f_a, f_b], pcov  = optimize.curve_fit(eps_fit_func, f[band_idx1],eps_data[band_idx1], p0=[eps_inf, K, f_a, f_b], method='lm')
        #[eps_inf, K], pcov  = optimize.curve_fit(eps_fit_func, f[band_idx1],eps_data[band_idx1], p0=[eps_inf, K], ftol=0.1, method='lm')
    except RuntimeError:
        sys.exit('eps lm failed to minimize')
    except ValueError:
        sys.exit('eps lm  failed with wrong input data')
    except optimize.OptimizeWarning:
        sys.exit('eps lm  failed to estimate covariance error')    

    # Sometimes returns negative values for f_ because of the square
    f_a = np.abs(f_a)
    f_b = np.abs(f_b)

    
    gpdly_syn = np.sqrt(eps_fit_func(f, eps_inf, K, f_a, f_b)) / c / in_m
    
    # Compute relative permittivty and loss tangent parameters at 1GHz
    eps_1g = eps_inf + 0.5*K*np.log((f_b**2 + 1e18)/(f_a**2 + 1e18))

    tand_1g = K*(np.arctan(1e9/f_a) - np.arctan(1e9/f_b))/eps_1g
    

    # DEBUG 
#    plt.figure(figsize=[12,10])
#    plt.plot(f, eps_data, f[band_idx1], eps_fit_func(f[band_idx1], eps_inf, K, f_a, f_b))
#    plt.grid()    
    
    print(eps_inf, K, f_a, f_b)
    
    return eps_1g, tand_1g, f_a, f_b, gpdly_syn



#
# ============================================================================
# ============================= MAIN BODY ====================================
#

def run_CMD(in_arg, out_arg,lfreq):
    
    '''
       Top level function for deltaL processor
    '''


    # parse the input file list
    in_list = parse_inlist(in_arg.replace(os.path.sep, '/'))
    
    
    
    # Set up plot of multiple graphs to PDF
        # create a directory if needed    
    if not os.path.exists(out_arg.replace(os.path.sep, '/')):
        os.mkdir(out_arg.replace(os.path.sep, '/'))
    
    pp = PdfPages(out_arg.replace(os.path.sep, '/')+'\\curve_fit_plots.pdf')
    
    # Setup summary for curve fitting parameters
    cf_coeffs_summry = pds.DataFrame(columns=['cfg_name','alpha','beta','gamma','eps_1g','tand_1g', 'f_a','f_b'])
        
    
    # Process entries in the list
    for line_config_name, line_config_content in in_list.items():
        
        
        # Initialize arrays
        freqs = np.array([])
        
        sploss = np.array([])


        gpdly = np.array([])
        
                
        # Compute average loss data
        for sxp_file in line_config_content['files']:
            
            freq_vec, loss_vec, gdelay_vec = get_sxp_data(sxp_file.strip(),lfreq)
            
            # essentially initialized the data array
            if sploss.size == 0:
                freqs =  np.hstack((freqs, freq_vec))
                sploss =  np.hstack((sploss, loss_vec))
                gpdly = np.hstack((gpdly, gdelay_vec))
                
            # otherwise put into existing array
            else:
                if freqs.size == freq_vec.size:
                    sploss =  np.vstack((sploss, loss_vec))
                    gpdly = np.vstack((gpdly, gdelay_vec))
                else:        
                    sys.exit('S-parameter data is not matching in frequency points')               
        

        
        
            
        # compute the per inch loss data
        loss_vec = 20*np.log10(np.mean(sploss, axis = 0)) / line_config_content['len']
        magdB_loss_data = pds.DataFrame({'freqs' : freqs, 'loss' : loss_vec})
                
        
        # compute the per inch group delay
        gdelay_vec = (np.mean(gpdly, axis = 0)) / line_config_content['len']
        gpdly_data = pds.DataFrame({'freqs' : freqs, 'gdly' : gdelay_vec})

        
        # dump both to csv files
        magdB_loss_data.to_csv(out_arg.replace(os.path.sep, '/')+'\\'+line_config_name+'_loss.csv', header=False, index=False)
        gpdly_data.to_csv(out_arg.replace(os.path.sep, '/')+'\\'+line_config_name+'_gdly.csv', header=False, index=False)
        
        
        #
        # Fit loss data 
        # 
        trc_wd = 5
        trc_hght = 2
        dcloss=20*np.log10(2/(2+ (0.0254)/(5.8e7*trc_wd*2.54e-5*trc_hght*2.54e-5)/50))
        
        alpha, beta, gamma, magdB_loss_syn = loss_fit_coeffs(freqs, magdB_loss_data['loss'], dcloss)      
        

        # plot loss fit
        plt.ioff()
        fig = plt.figure(figsize=[20,15])
        plt.plot(freqs/1e9,magdB_loss_data['loss'], freqs/1e9, magdB_loss_syn)
        plt.grid(which='both')
        plt.xlabel('Frequency(GHz)',fontsize=16)
        plt.ylabel('Loss (dB/in)',fontsize=16)
        plt.tick_params(labelsize=12)
        plt.title('Loss fit per inch : ' + line_config_name, fontsize=20)           
        
        # these are matplotlib.patch.Patch properties
        props = dict(boxstyle='round', alpha=0.2)
        textstr = '\n'.join((
            r'$\alpha=%.3e$' % (alpha, ),
            r'$\beta=%.3e$' % (beta, ),
            r'$\gamma=%.3e$' % (gamma, )))        
        
        # place a text box in upper left in axes coords
        ax = plt.gca()
        ax.text(0.87, 0.95, textstr, transform=ax.transAxes, fontsize=14,verticalalignment='top', bbox=props)        
        plt.savefig(pp, format='pdf')
        plt.close(fig)
                    
                
        
        #
        # Fit group delay
        #
        
        eps_1g, tand_1g, f_a, f_b, gpdly_syn= dly_fit_coeffs(freqs, gdelay_vec, 1e-12)

        # plot group delay fit
        plt.ioff()
        fig = plt.figure(figsize=[20,15])
        plt.plot(freqs/1e9,gpdly_data['gdly'], freqs/1e9, gpdly_syn)
        plt.grid(which='both')
        plt.xlabel('Frequency(GHz)',fontsize=16)
        plt.ylabel('Delay (S/in)',fontsize=16)
        plt.tick_params(labelsize=12)
        plt.title('Delay fit per inch : ' + line_config_name, fontsize=20)           
        
        textstr = '\n'.join((
            r'$\epsilon_{1G}=%.3f$' % (eps_1g, ),
            r'$tan\delta_{1G}=%0.4f$' % (tand_1g, ),
            r'$f_a=%.3e$' % (f_a, ),   
            r'$f_b=%.3e$' % (f_b, )))   
        
        ax = plt.gca()
        ax.text(0.82, 0.95, textstr, transform=ax.transAxes, fontsize=14,verticalalignment='top', bbox=props)        
        plt.savefig(pp, format='pdf')
        plt.close(fig)
                            
       
        # append to table
        cf_coeffs_summry = cf_coeffs_summry.append({'cfg_name' :  line_config_name  ,
                                 'alpha' : alpha ,
                                 'beta' : beta,
                                 'gamma': gamma,
                                 'eps_1g': eps_1g,
                                 'tand_1g': tand_1g,
                                 'f_a': f_a,
                                 'f_b': f_b}, ignore_index=True)
    
    # Save fit coefficients to csv
    
    cf_coeffs_summry.to_csv(out_arg.replace(os.path.sep, '/')+'\\curve_fit_coeffs.csv', index=False)
    
    pp.close()



def main(argv):
    '''
       Parse command line arguments
    '''
    in_arg = ''
    out_arg = ''
    lfreq = 0
    
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hl:o:f:", ["help", "listfile=", "outdir=","lowfreq="])
        
    except getopt.GetoptError as err:
        # print help information and exit:
        sys.stdout.write(err)  # will print something like "option -a not recognized"
        sys.stdout.write('Usage: singleL_proc.py -l <s*p list input file> -o <csv output directory> -f <low frequency cutoff hz>')
        sys.exit(2)

    for opt, val in opts:
        # Help option
        if opt in ("-h", "--help"):
            sys.stdout.write('Usage: singleL_proc.py -l <s*p list input file> -o <csv output directory> -f <low frequency cutoff hz>')
            sys.exit()
        
        # Grab input s*p list file
        elif opt in ("-l", "--input"):
            in_arg = val    
        
        # Grab output directory
        elif opt in ("-o", "--output"):
            out_arg = val
            
        # Grab lwo freq directory
        elif opt in ("-f", "--lowfreq"):
            lfreq = np.float(val)
           
        # Not sure what happenede
        else:
            assert False, "unhandled option"
            sys.exit(2)
    
    # If got here means good to process
    run_CMD(in_arg,out_arg, lfreq)


if __name__ == '__main__':

    #run command line version
     main(sys.argv)





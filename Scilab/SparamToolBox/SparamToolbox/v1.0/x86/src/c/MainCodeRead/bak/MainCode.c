#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#define _USE_MATH_DEFINES 
#include <math.h>
//#include <spar_type.h>

#define errcode0 0 			// Return OK
#define errcode1 1			// Invalid or null  sfilename
#define errcode2 2			// File extension has invalid format
#define errcode3 3			// Unable to access file
#define errcode4 4			// Unable to allocate memory for file read
#define errcode5 5			// Error reading file
#define errcode6 6			// Unable to allocate memory
#define errcode7 7			// Parsing error: expecting commented line or options line
#define errcode8 8			// Parsing error: reached end-of-file before options line
#define errcode9 9			// Parsing error: invalid parameter in options line
#define errcode10 10		// Parsing error: unsupported touchstone format in options line
#define errcode11 11		// Unable to allocate memory for S-param matrix
#define errcode12 12		// Parsing error: invalid format of floating-point value
#define errcode13 13		// Parsing error:  unexpected number of tokens in data line
#define errcode14 14		// Unexpected format type
#define errcode15 15		// Parsing error: expecting frequency to increase
#define errcode1000 1000	// Unexpected error



int fetchline(char *pindatastream, char **pdataline, int* pIdx, int iFileEndIdx)
{
	int iStartIdx=0;
	int iEndIdx=0;

	/* deallocate memory for the line (if allocated) */
	if (*pdataline != NULL)
	{
		free(*pdataline);
	}
		
	/* Save starting point of line */
	iStartIdx = *pIdx;

	/* Search through inddatastream until find eol (or eof) and set end indx */
	while ((*pIdx < iFileEndIdx) && ((char)pindatastream[*pIdx] != 0x0A) && ((char)pindatastream[*pIdx] != 0x0D))
	{
		(*pIdx)++;
	}

	iEndIdx = *pIdx-1;

	/* At eol (when not eof), advance index to skip eol characters */
	if (*pIdx < iFileEndIdx)
	{
		if ((char)pindatastream[*pIdx] == 0x0D)
		{
			(*pIdx)++;
			if (*pIdx < iFileEndIdx) 
			{
			 if ((char)pindatastream[*pIdx] == 0x0A)
			 {
				(*pIdx)++;
			 }
			}
		}	
		else if ((char)pindatastream[*pIdx] == 0x0A)
		{
			(*pIdx)++;
		}
	}


	if ((iEndIdx-iStartIdx) > -1)
	{
		if((*pdataline=(char*)calloc((iEndIdx-iStartIdx+2), sizeof(char)))==NULL)
		{
			return(2);
		}

		/* copy line */
		memcpy(*pdataline, &pindatastream[iStartIdx], (iEndIdx-iStartIdx+1));
	}
	else
	{
		if((*pdataline=(char*)calloc(1, sizeof(char)))==NULL)
		{
			return(2);
		}
	}


	/* flag end of file */
	if (*pIdx == iFileEndIdx)
	{
		return(1);
	}
	else
	{
		return(0);
	}
	

	//return 2 if error, return 1 if eof, return 0 if went through


}

int main()
{
	
	char sfilename[150]="20in_2c_lowSNR01_14_2010_pin2pin.s12p";	// Temporary sfilename


	unsigned int iNport = 0;				// Number of ports
	unsigned int iFilelen = 0;				// File length
	unsigned int iFileidx = 0;				// File pointer index

	int bFoundOptionsLine = 0;			// Flags that options line is found
	int bEOF		= 0;				// Flags that EOF is found
	
	int i, j, k, l;
											// OPTIONS
											//
	int iFormat = 0;						// S-parameters format
											//   0=Magnitude-Angle (default)
											//   1=dB-Angle	
											//   2=Real-Imaginary
	double fRefRes   = 50.0;				// Reference Resistance
	double fFreqUnit = 1;					// Frequency unit multiplier
	

	char *psfiledata=NULL;						// File contents
	char *psfileline=NULL;						// Extracted file line
	FILE *ffspfile;

											// STAND-IN FOR S-Parameter structure
	double *Freq;							// Frequencies vector
	double *Real;							// Real Matrix
	double *Imag;							// Imaginary Matrix

	double ffstvaltemp=0;					// Temporary variables
	double fscndvaltemp=0;


	
/* Guess at a number of ports from file name */
	
	
	if ((i=strlen(sfilename)) == 0)		// Find the end of sfilename
	{
		return(errcode1);
	}
	
	i--;
	j=i;
	while ((sfilename[j] != '.') && j>=0) j--;
	
	
	/* Let's do some basic checking on the extension */
	if(j==0) return (errcode2);
	
	if((toupper(sfilename[j+1])!= 'S') || (toupper(sfilename[i])!= 'P')) return (errcode2);
		
	/* Extract port count */
        for (j=j+2; j<i; j++)
       	{
       		if (!isdigit(sfilename[j])) 
       		{
       			return(errcode2);
       		}
       		else
   		{	
			k=sfilename[j];
   			iNport=atoi(&(char)k)*(int)pow(10,(i-j-1))+iNport;
   			if (errno == ERANGE)
    			{
       				return(errcode1000);
    			}
       		}		
       	} 
       	
       	if (iNport <= 0) return (errcode2);
       		
/* open and read in the entire file */

	if ((ffspfile=fopen(sfilename,"rb")) == NULL) 
	{
	  
	    return(errcode3);
	}
	
	if (fseek(ffspfile, 0L, SEEK_END)!= 0)
	{
	  fclose(ffspfile);
	  return(errcode3);
	}
	
	/* Get file length */
	if ((iFilelen=ftell(ffspfile))==0)
	{
	  fclose(ffspfile);
	  return(errcode3);
	}

	
	/* Read entire file into memory */
	if (fseek(ffspfile, 0, SEEK_SET)!= 0)
	{
      fclose(ffspfile);
	  return(errcode3);
	}
	
	if((psfiledata=(char*)malloc(sizeof(char)*iFilelen))==NULL)
	{
		fclose(ffspfile);
		return(errcode4);
	}
	
	if (fread(psfiledata, sizeof(char), iFilelen, ffspfile)  < iFilelen)
	{
		fclose(ffspfile);
		return(errcode5);
	}
	
	fclose(ffspfile);



/* Read in the options line */


	while (!bEOF && !bFoundOptionsLine)
	{
		
		/* Get a line from file */
		k=fetchline(psfiledata, &psfileline, &iFileidx, iFilelen);
		if (k==2)
		{
			return(errcode6);
		}

		if (k==1)
		{
			bEOF=1;
		}

		/* find either comment line or options line */
		/* Use k as flag that did not find comment or options line */
		for (i=0; i<(int)strlen(psfileline); i++)
		{
			switch (psfileline[i])
			{
					case '!':  
						i=strlen(psfileline)-1; 
						k=0;
						break;
					case '#':  
						bFoundOptionsLine=1; 
						i=strlen(psfileline)-1; 
						k=0;
						break;
					case 0x20:
					case 0x09:
						break;
					default:
						k=1;

			}
		}

		if (k==1)
		{
			return(errcode7);
		}
	}

	if(bEOF && !bFoundOptionsLine)
	{
		return(errcode8);
	}


/*  Parse options line for all options */

	
	psfileline = strtok(psfileline, " \t");
	while(psfileline != NULL)
	{
		if (*psfileline == '#')
		{
			psfileline = strtok(NULL, " \t");
		}
		else if(!strcmp(_strupr(psfileline), "HZ"))
		{
			fFreqUnit = 1;
			psfileline = strtok(NULL, " \t");
		}
		else if(!strcmp(_strupr(psfileline), "KHZ"))
		{
			fFreqUnit = 1000;
			psfileline = strtok(NULL, " \t");
		}
		else if(!strcmp(_strupr(psfileline), "MHZ"))
		{
			fFreqUnit = 1000000;
			psfileline = strtok(NULL, " \t");
		}
		else if(!strcmp(_strupr(psfileline), "GHZ"))
		{
			fFreqUnit = 1000000000;
			psfileline = strtok(NULL, " \t");
		}
		else if(!strcmp(_strupr(psfileline), "MA"))
		{
			iFormat = 0;
			psfileline = strtok(NULL, " \t");
		}
		else if(!strcmp(_strupr(psfileline), "DB"))
		{
			iFormat = 1;
			psfileline = strtok(NULL, " \t");
		}
		else if(!strcmp(_strupr(psfileline), "RI"))
		{
			iFormat = 2;
			psfileline = strtok(NULL, " \t");
		}
		else if(!strcmp(_strupr(psfileline), "R"))
		{
			if (psfileline = strtok(NULL, " \t"))
			{
				if (fRefRes=strtod(psfileline, NULL))
				{
						psfileline = strtok(NULL, " \t");
				}
				else
				{
					return(errcode9);
				}
			}
			else
			{
				return(errcode9);
			}
		}
		else if (!strcmp(_strupr(psfileline), "S"))
		{
			psfileline = strtok(NULL, " \t");
		}
		else if(!strcmp(_strupr(psfileline), "Y") || !strcmp(_strupr(psfileline), "Z")
				|| !strcmp(_strupr(psfileline), "G") || !strcmp(_strupr(psfileline), "H"))
		{
			return(errcode10);
		}
		else
		{
			return(errcode9);
		}

	}

/*  Get frequency data */

	// Different algorithms depending on number of ports



	/* Initialize stuff */
	i=0;		// Used as frequency vector index
	j=0;		// Used as token count in a line
	k=0;		// Used as fetchline return value
	l=0;		// Used as line count for each frequency

	if((Freq=(double*)malloc(0))==NULL)
	{
		
		return(errcode11);
	}

	if((Real=(double*)malloc(0))==NULL)
	{
		
		return(errcode11);
	}

	if((Imag=(double*)malloc(0))==NULL)
	{
		
		return(errcode11);
	}


	/* Single or 2-port S-parameter */
	if (iNport <= 2)
	{
		j=1;
		while(!bEOF)
		{
			k=fetchline(psfiledata, &psfileline, &iFileidx, iFilelen);
			if (k==2)
			{
				return(errcode6);
			}
			if (k==1)
			{
				bEOF=1;
			}

			/* Read in the tokens */
			psfileline = strtok(psfileline, " \t");

			/* Ignore comment line */
			if ((psfileline != NULL) && psfileline[0]=='!');
			{
				continue;
			}
			
			while(psfileline != NULL)
			{
				// Frequency data
				if (j==1)
				{
					if((Freq = realloc(Freq, sizeof(double)*(i+1)))== NULL)
					{
						return(errcode11);
					}
					Freq[i]=fFreqUnit*strtod(psfileline, NULL);
					psfileline = strtok(NULL, " \t");

					// Frequency not increasing, assuming noise data
					if(i>0 && Freq[i]<=Freq[i-1])
					{
						bEOF=1;
					}
					j++;
				}
				// Get first value in a pair
				else if((j<=2*iNport*iNport+1) && (j%2==0))
				{

					ffstvaltemp=strtod(psfileline, NULL);
					psfileline = strtok(NULL, " \t");
					j++;

				}
				// Get second value in a pair
				else if((j<=2*iNport*iNport+1) && (j%2==1))
				{

					fscndvaltemp=strtod(psfileline, NULL);
					psfileline = strtok(NULL, " \t");
					j++;

					// convert data and put into matrix
					if((Real = realloc(Real, sizeof(double)*((i+1)*iNport*iNport+(j-1)/2)))== NULL)
					{
							return(errcode11);
					}

					if((Imag = realloc(Imag, sizeof(double)*((i+1)*iNport*iNport+(j-1)/2)))== NULL)
					{
							return(errcode11);
					}

					switch (iFormat)
					{
						case 0:													// Mag-Angle
							fscndvaltemp=fscndvaltemp*(M_PI/180);
							Real[i*iNport*iNport+(j-1)/2-1]=ffstvaltemp*cos(fscndvaltemp);
							Imag[i*iNport*iNport+(j-1)/2-1]=ffstvaltemp*sin(fscndvaltemp);
							break;
						case 1:													// dB-Angle
							ffstvaltemp=pow(10, ffstvaltemp/20);
							fscndvaltemp=fscndvaltemp*(M_PI/180);
							Real[i*iNport*iNport+(j-1)/2-1]=ffstvaltemp*cos(fscndvaltemp);
							Imag[i*iNport*iNport+(j-1)/2-1]=ffstvaltemp*sin(fscndvaltemp);
							break;
						case 2:	
							Real[i*iNport*iNport+(j-1)/2-1]=ffstvaltemp;	// Real-Imag
							Imag[i*iNport*iNport+(j-1)/2-1]=fscndvaltemp;
							break;
						default:
							return(errcode14);
					}
				}
				else
				{
					//If comment, stop reading line further
					if (psfileline[0]== '!')
					{
						psfileline = NULL;
					}
					else
					{
						return(errcode13);
					}
				}
			}
			// Should have gotten all expected data pairs
			if (j!=2*iNport*iNport+2)
			{
				return(errcode13);	
			}
			//We're done with this frequency point
			j=1;
			i++;
		}
	}

	/* Three or more port S-parameter */
	if(iNport > 2)
	{
		j=1;
		l=0;
		while(!bEOF)
		{
					k=fetchline(psfiledata, &psfileline, &iFileidx, iFilelen);
					if (k==2)
					{
						return(errcode6);
					}
					if (k==1)
					{
						bEOF=1;
					}
					l++;

					/* Read in the tokens */
					psfileline = strtok(psfileline, " \t");

					/* Ignore comment line */
					if ((psfileline != NULL) && psfileline[0]=='!')
					{
						continue;
					}

					while(psfileline != NULL)
					{
					
						// Frequency data
						if (j==1)
						{
							if((Freq = realloc(Freq, sizeof(double)*(i+1)))== NULL)
							{
								return(errcode11);
							}

							Freq[i]=fFreqUnit*strtod(psfileline, NULL);
							psfileline = strtok(NULL, " \t");


							// Frequency not increasing, error
							if(i>0 && Freq[i]<=Freq[i-1])
							{
								return(errcode15);
							}
							j++;
						}
						// Get first value in a pair
						else if((j<=2*iNport*iNport+1) && (j%2==0))
						{

							ffstvaltemp=strtod(psfileline, NULL);
							psfileline = strtok(NULL, " \t");
							j++;

						}
						// Get second value in a pair
						else if((j<=2*iNport*iNport+1) && (j%2==1))
						{

							fscndvaltemp=strtod(psfileline, NULL);
							psfileline = strtok(NULL, " \t");
							j++;

							// convert data and put into matrix
							if((Real = realloc(Real, sizeof(double)*((i+1)*iNport*iNport+(j-1)/2)))== NULL)
							{
									return(errcode11);
							}

							if((Imag = realloc(Imag, sizeof(double)*((i+1)*iNport*iNport+(j-1)/2)))== NULL)
							{
									return(errcode11);
							}

							switch (iFormat)
							{
								case 0:													// Mag-Angle
									fscndvaltemp=fscndvaltemp*(M_PI/180);
									Real[i*iNport*iNport+(j-1)/2-1]=ffstvaltemp*cos(fscndvaltemp);
									Imag[i*iNport*iNport+(j-1)/2-1]=ffstvaltemp*sin(fscndvaltemp);
									break;
								case 1:													// dB-Angle
									ffstvaltemp=pow(10, ffstvaltemp/20);
									fscndvaltemp=fscndvaltemp*(M_PI/180);
									Real[i*iNport*iNport+(j-1)/2-1]=ffstvaltemp*cos(fscndvaltemp);
									Imag[i*iNport*iNport+(j-1)/2-1]=ffstvaltemp*sin(fscndvaltemp);
									break;
								case 2:	
									Real[i*iNport*iNport+(j-1)/2-1]=ffstvaltemp;	// Real-Imag
									Imag[i*iNport*iNport+(j-1)/2-1]=fscndvaltemp;
									break;
								default:
									return(errcode14);
							}

						}
						else
						{
							//If comment, stop reading line further
							if (psfileline[0]== '!')
							{
								psfileline = NULL;
							}
							else
							{
								return(errcode13);
							}
						}
					}
			// We're on the last data line for the frequency
			if (l==iNport*(int)ceil((double)iNport/4))
			{
				//Should have gotten all expected data pairs
				if(j!=2*iNport*iNport+2)
				{
					return(errcode13);	
				}
				//We're done with this frequency point
				j=1;
				l=0;
				i++;
			}
		}	
	}
	

	return(errcode0);
}


//=========================S-parameter ToolBox====================== 
//
// READ_TCHSTN()
//  
// Touchstone file reader routines
// 
// (c)2010-2015  L. Rayzman
// 
// Created      : 02/06/2010
// Last Modified: 07/22/2015  - Added check for touchstone version
//                              Removed resistriction for >4-port files
//                                    to conform to the 4-data points 
//                                    per line rule
//                08/18/2015  - Added ability to read in comments
//                              
// ====================================================================
/* ==================================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#define _USE_MATH_DEFINES 
#include <math.h>
#include <stdarg.h>
#include "spar_type.h"
#include "scomm_type.h"
#include "err_codes.h"

/* ==================================================================== */
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


/* ==================================================================== */
SparErr read_tchstn(char *filename, SParType **spmat, SCommType **strComments)
{

	
	unsigned int iNport = 0;				// Number of ports
	unsigned int iFilelen = 0;				// File length
	unsigned int iFileidx = 0;				// File pointer index

	unsigned int iCommidx = 0;             // Comments array index

	int bFoundOptionsLine = 0;			// Flags that options line is found
	int bEOF		= 0;				// Flags that EOF is found
	
	int i, j, k, l, m;
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

	double ffstvaltemp=0;					// Temporary variables
	double fscndvaltemp=0;
	char *psfilelinetemp=NULL;                      


	/* Guess at a number of ports from file name */
	
	
	if ((i=strlen(filename)) == 0)		// Find the end of filename
	{
		return(CreateSpErr(0, errcode1));
	}
	
	i--;
	j=i;
	while ((filename[j] != '.') && j>=0) j--;
	
	
	/* Let's do some basic checking on the extension */
	if(j==0) return(CreateSpErr(0, errcode2));
	
	if((toupper(filename[j+1])!= 'S') || (toupper(filename[i])!= 'P')) return(CreateSpErr(0, errcode2));
		
	/* Extract port count */
        for (j=j+2; j<i; j++)
       	{
       		if (!isdigit(filename[j])) 
       		{
       			return(CreateSpErr(0, errcode2));
       		}
       		else
   		{	
			k=filename[j];
   			iNport=atoi(&(char)k)*(int)pow(10,(i-j-1))+iNport;
   			if (errno == ERANGE)
    			{
       				return(CreateSpErr(0, errcode1000));
    			}
       		}		
       	} 
       	
       	if (iNport <= 0) return(CreateSpErr(0, errcode2));



		/* open and read in the entire file */

	if ((ffspfile=fopen(filename,"rb")) == NULL) 
	{
	  
	    return(CreateSpErr(0, errcode3));
	}
	
	if (fseek(ffspfile, 0L, SEEK_END)!= 0)
	{
	  fclose(ffspfile);
	  return(CreateSpErr(0, errcode3));
	}
	
	/* Get file length */
	if ((iFilelen=ftell(ffspfile))==0)
	{
	  fclose(ffspfile);
	  return(CreateSpErr(0, errcode3));
	}

	
	/* Read entire file into memory */
	if (fseek(ffspfile, 0, SEEK_SET)!= 0)
	{
      fclose(ffspfile);
	  return(CreateSpErr(0, errcode3));
	}
	
	if((psfiledata=(char*)malloc(sizeof(char)*iFilelen))==NULL)
	{
		fclose(ffspfile);
		return(CreateSpErr(0, errcode4));
	}
	
	if (fread(psfiledata, sizeof(char), iFilelen, ffspfile)  < iFilelen)
	{
		fclose(ffspfile);
		return(CreateSpErr(0, errcode5));
	}
	
	fclose(ffspfile);


	/* Initialize comments line */                    


	*strComments=(SCommType*)malloc(sizeof(SCommType));

	if(((**strComments).commArr=(char**)malloc(0))==NULL)
	{
		free(psfiledata);
		return(CreateSpErr(0, errcode6));
	}
	(**strComments).nlines=0;

	/* Read in the options line */
	while (!bEOF && !bFoundOptionsLine)
	{
		
		/* Get a line from file */
		k=fetchline(psfiledata, &psfileline, &iFileidx, iFilelen);
		if (k==2)
		{
			free(psfiledata);
			return(CreateSpErr(0, errcode6));
		}

		if (k==1)  /* found EOF */
		{
			bEOF=1;
		}

		/* find either comment line or options line */
		/* Use k as flag that did not find comment or options line */
		/*   k=0 : all is ok (found comment or options line)       */
		/*   k=1 : found other character                           */
		/*   k=2 : found a possible keyword bracket                */
		for (i=0; i<(int)strlen(psfileline); i++)
		{
			switch (psfileline[i])
			{
					case '!':  /* Comments line */
						
						// Allocate space for new comments line
						if(((**strComments).commArr = realloc((**strComments).commArr, sizeof(char*)*(iCommidx+1)))== NULL)
						{
							free(psfiledata);
							return(CreateSpErr(0, errcode6));
						}
    
						// Add comments line to array
						if  (((**strComments).commArr[iCommidx]=(char*)malloc(sizeof(char)*(strlen(psfileline)-i)))==NULL)
						{
							free(psfiledata);
							return(CreateSpErr(0, errcode6));
						}
						memset((**strComments).commArr[iCommidx],0x00,(strlen(psfileline)-i));
						strncpy((**strComments).commArr[iCommidx], psfileline+i+1, (strlen(psfileline)-i-1));
						(**strComments).nlines=++iCommidx;

						i=strlen(psfileline)-1; 
						k=0;
						break;
					case '#':  
						bFoundOptionsLine=1; 
						i=strlen(psfileline)-1; 
						k=0;
						break;
					case 0x20:  /* space and tab */
					case 0x09:
						break;
					case '[':   /* Keyword line */
						i=strlen(psfileline)-1;
                        k=2;
						break;
					default:
						k=1;

			}
		}

		if (k==1)
		{
			free(psfiledata);
			return(CreateSpErr(0, errcode7));
		}
		/* Check if version keyword is present */
		if (k==2)
		{

			psfileline = strtok(psfileline, " \t");
			if (!strcmp(_strupr(psfileline), "[VERSION]"))
			{
				free(psfiledata);
				return(CreateSpErr(0, errcode7));
			}
			else
			{
				free(psfiledata);
				return(CreateSpErr(0, errcode7));
			}
		}
		
		
	}

	if(bEOF && !bFoundOptionsLine)
	{
		free(psfiledata);
		return(CreateSpErr(0, errcode8));
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
					free(psfiledata);
					return(CreateSpErr(0, errcode9));
				}
			}
			else
			{
				free(psfiledata);
				return(CreateSpErr(0, errcode9));
			}
		}
		else if (!strcmp(_strupr(psfileline), "S"))
		{
			psfileline = strtok(NULL, " \t");
		}
		else if(!strcmp(_strupr(psfileline), "Y") || !strcmp(_strupr(psfileline), "Z")
				|| !strcmp(_strupr(psfileline), "G") || !strcmp(_strupr(psfileline), "H"))
		{
			free(psfiledata);
			return(CreateSpErr(0, errcode10));
		}
		else
		{
			free(psfiledata);
			return(CreateSpErr(0, errcode9));
		}

	}


	


/*  Get frequency data */

	/* Initialize stuff */
	i=0;		// Used as frequency vector index
	j=0;		// Used as token count in a line
	k=0;		// Used as fetchline return value
	l=0;        // Used as data points count per frequency for 3-port or more
	m=0;		// Used as offset index in the data matrix

	*spmat=(SParType*)malloc(sizeof(SParType));

	
	/* Copy the attributes to structure. Didn't feel like changing the code*/
	(**spmat).nport=iNport;
	(**spmat).Z0=fRefRes;

	

	if(((**spmat).freq=(double*)malloc(0))==NULL)
	{
		free(psfiledata);
		return(CreateSpErr(0, errcode11));
	}

	if(((**spmat).real=(double*)malloc(0))==NULL)
	{
		free(psfiledata);
		return(CreateSpErr(0, errcode11));
	}


	if(((**spmat).imag=(double*)malloc(0))==NULL)
	{
		free(psfiledata);
		return(CreateSpErr(0, errcode11));
	}



	/* Single or 2-port S-parameter */
	/* Sequence of terms: S11 S21 S12 S22 */
	if (iNport <= 2)
	{
		j=1;
		while(!bEOF)
		{
			k=fetchline(psfiledata, &psfileline, &iFileidx, iFilelen);
			if (k==2)
			{
				free(psfiledata);
				return(CreateSpErr(0, errcode6));
			}
			if (k==1)
			{
				bEOF=1;
			}

			/* save original file line for comments processing*/
			if((psfilelinetemp = (char*)realloc(psfilelinetemp, sizeof(char)*(strlen(psfileline)+1)))== NULL)
			{
				free(psfiledata);	
				return(CreateSpErr(0, errcode6));
			}
			strcpy(psfilelinetemp, psfileline);

			/* Read in the tokens */
			psfileline = strtok(psfileline, " \t");

			/* Skip blank line */
			if (psfileline == NULL)
			{
				continue;
			}
			/* Save comments line */ 
			else if (psfileline[0]=='!')
			{
				// Allocate space for new comments line
				if(((**strComments).commArr = realloc((**strComments).commArr, sizeof(char*)*(iCommidx+1)))== NULL)
				{
						free(psfiledata);
						return(CreateSpErr(0, errcode6));
				}

				// Add comments line to array
				if  (((**strComments).commArr[iCommidx]=(char*)malloc(sizeof(char)*strlen(strchr(psfilelinetemp, '!'))))==NULL)
				{
						free(psfiledata);
						return(CreateSpErr(0, errcode6));
				}
						
				memset((**strComments).commArr[iCommidx],0x00,(strlen(strchr(psfilelinetemp, '!'))));
				strncpy((**strComments).commArr[iCommidx], strchr(psfilelinetemp,'!')+1, strlen(strchr(psfilelinetemp, '!'))-1);
				(**strComments).nlines=++iCommidx;
				
				// Skip to next line
				psfileline = NULL;
				continue;
	  		}
			
			while(psfileline != NULL)
			{
				// frequency data
				if (j==1)
				{
					if(((**spmat).freq = realloc((**spmat).freq, sizeof(double)*(i+1)))== NULL)
					{
						free(psfiledata);
						return(CreateSpErr(0, errcode11));
					}
					(**spmat).freq[i]=fFreqUnit*strtod(psfileline, NULL);
					psfileline = strtok(NULL, " \t");

					// Frequency not increasing, assuming noise data
					if(i>0 && (**spmat).freq[i]<=(**spmat).freq[i-1])
					{
						bEOF=1;
					}

					// Allocate space for the data at this frequency point
					if(((**spmat).real = realloc((**spmat).real, sizeof(double)*((i+1)*iNport*iNport)))== NULL)
					{
						free(psfiledata);	
						return(CreateSpErr(0, errcode11));
					}

					if(((**spmat).imag = realloc((**spmat).imag, sizeof(double)*((i+1)*iNport*iNport)))== NULL)
					{
						free(psfiledata);
						return(CreateSpErr(0, errcode11));
					}


					j++;
				}
				// Get first value in a pair
				else if((j<=2*iNport*iNport+1) && (j%2==0) && psfileline[0] != '!')
				{

					ffstvaltemp=strtod(psfileline, NULL);
					psfileline = strtok(NULL, " \t");
					j++;

				}
				// Get second value in a pair
				else if((j<=2*iNport*iNport+1) && (j%2==1) && psfileline[0] != '!')
				{

					fscndvaltemp=strtod(psfileline, NULL);
					psfileline = strtok(NULL, " \t");
					j++;

					//Compute index of point in the data matrix
					m=i*iNport*iNport+(j-1)/2-1;	

					// convert data and put into matrix
					switch (iFormat)
					{
						case 0:													// Mag-Angle
							fscndvaltemp=fscndvaltemp*(M_PI/180);
							(**spmat).real[m]=ffstvaltemp*cos(fscndvaltemp);
							(**spmat).imag[m]=ffstvaltemp*sin(fscndvaltemp);
							break;
						case 1:													// dB-Angle
							ffstvaltemp=pow(10, ffstvaltemp/20);
							fscndvaltemp=fscndvaltemp*(M_PI/180);
							(**spmat).real[m]=ffstvaltemp*cos(fscndvaltemp);
							(**spmat).imag[m]=ffstvaltemp*sin(fscndvaltemp);
							break;
						case 2:	
							(**spmat).real[m]=ffstvaltemp;	// (**spmat).real-(**spmat).imag
							(**spmat).imag[m]=fscndvaltemp;
							break;
						default:
							free(psfiledata);
							return(CreateSpErr(0, errcode14));
					}
				}
				else
				{
					//If comment, stop reading line further
					if (psfileline[0] == '!')
					{
						// Allocate space for new comments line
						if(((**strComments).commArr = realloc((**strComments).commArr, sizeof(char*)*(iCommidx+1)))== NULL)
						{
							free(psfiledata);
							return(CreateSpErr(0, errcode6));
						}

						// Add comments line to array
						if  (((**strComments).commArr[iCommidx]=(char*)malloc(sizeof(char)*strlen(strchr(psfilelinetemp, '!'))))==NULL)
						{
							free(psfiledata);
							return(CreateSpErr(0, errcode6));
						}
						
						memset((**strComments).commArr[iCommidx],0x00,(strlen(strchr(psfilelinetemp, '!'))));
						strncpy((**strComments).commArr[iCommidx], strchr(psfilelinetemp,'!')+1, strlen(strchr(psfilelinetemp, '!'))-1);
						(**strComments).nlines=++iCommidx;

						// Go to next line
						psfileline = NULL;
					}
					else
					{
						free(psfiledata);
						return(CreateSpErr(0, errcode13));
					}
				}
			}
			// Should have gotten all expected data pairs
			if (j!=2*iNport*iNport+2)
			{
				free(psfiledata);
				return(CreateSpErr(0, errcode13));	
			}
			//We're done with this (*spmat) frequency point
			j=1;
			i++;
		}
	}

	/* Three or more port S-parameter */
	/* Sequence of terms: S11 S12 S13... S1N S21 S22 ... */
	if(iNport > 2)
	{
		j=1;

		while(!bEOF)
		{
					k=fetchline(psfiledata, &psfileline, &iFileidx, iFilelen);
					if (k==2)
					{
						free(psfiledata);
						return(CreateSpErr(0, errcode6));
					}
					if (k==1)
					{
						bEOF=1;
					}

					/* save original file line for comments processing*/
					if((psfilelinetemp = (char*)realloc(psfilelinetemp, sizeof(char)*(strlen(psfileline)+1)))== NULL)
					{
						free(psfiledata);	
						return(CreateSpErr(0, errcode6));
					}
					strcpy(psfilelinetemp, psfileline);

					/* Read in the tokens */
					psfileline = strtok(psfileline, " \t");

					/* Skip blank line */
					if (psfileline == NULL)
					{
						continue;
					}
					/* Save comments line */ 
					else if (psfileline[0]=='!')
					{
						// Allocate space for new comments line
						if(((**strComments).commArr = realloc((**strComments).commArr, sizeof(char*)*(iCommidx+1)))== NULL)
						{
							free(psfiledata);
							return(CreateSpErr(0, errcode6));
						}

						// Add comments line to array
						if  (((**strComments).commArr[iCommidx]=(char*)malloc(sizeof(char)*strlen(strchr(psfilelinetemp, '!'))))==NULL)
						{
							free(psfiledata);
							return(CreateSpErr(0, errcode6));
						}
						
						memset((**strComments).commArr[iCommidx],0x00,(strlen(strchr(psfilelinetemp, '!'))));
						strncpy((**strComments).commArr[iCommidx], strchr(psfilelinetemp,'!')+1, strlen(strchr(psfilelinetemp, '!'))-1);
						(**strComments).nlines=++iCommidx;
						
						// Skip to next line
						psfileline = NULL;
						continue;
	  				}

					while(psfileline != NULL)
					{
					
						// Read in frequency point
						if (j==1)
						{
							if(((**spmat).freq = realloc((**spmat).freq, sizeof(double)*(i+1)))== NULL)
							{
								free(psfiledata);
								return(CreateSpErr(0, errcode11));
							}

							(**spmat).freq[i]=fFreqUnit*strtod(psfileline, NULL);
							psfileline = strtok(NULL, " \t");


							// frequency not increasing, error
							if(i>0 && (**spmat).freq[i]<=(**spmat).freq[i-1])
							{ 
								    free(psfiledata);
								    return(CreateSpErr(0, errcode15));
							}

							// Allocate space for the data at this frequency point
							if(((**spmat).real = realloc((**spmat).real, sizeof(double)*((i+1)*iNport*iNport)))== NULL)
							{
								    free(psfiledata);
									return(CreateSpErr(0, errcode11));
							}

							if(((**spmat).imag = realloc((**spmat).imag, sizeof(double)*((i+1)*iNport*iNport)))== NULL)
							{
								    free(psfiledata);
									return(CreateSpErr(0, errcode11));
							}

							j++;
							l=0;
						}
						// Get first value in a pair
						else if((j<=2*iNport*iNport+1) && (j%2==0) && psfileline[0] != '!')
						{

							ffstvaltemp=strtod(psfileline, NULL);
							psfileline = strtok(NULL, " \t");
							j++;

						}
						// Get second value in a pair
						else if((j<=2*iNport*iNport+1) && (j%2==1) && psfileline[0] != '!')
						{

							fscndvaltemp=strtod(psfileline, NULL);
							psfileline = strtok(NULL, " \t");
							j++;

							
							//Compute index of point in the data matrix
							m=i*iNport*iNport+(((j-1)/2-1)%iNport)*iNport+(int)floor((double)((j-1)/2-1)/(double)iNport);	

							// convert data and put into matrix
							switch (iFormat)
							{
								case 0:													// Mag-Angle
									fscndvaltemp=fscndvaltemp*(M_PI/180);
									(**spmat).real[m]=ffstvaltemp*cos(fscndvaltemp);
									(**spmat).imag[m]=ffstvaltemp*sin(fscndvaltemp);
									break;
								case 1:													// dB-Angle
									ffstvaltemp=pow(10, ffstvaltemp/20);
									fscndvaltemp=fscndvaltemp*(M_PI/180);
									(**spmat).real[m]=ffstvaltemp*cos(fscndvaltemp);
									(**spmat).imag[m]=ffstvaltemp*sin(fscndvaltemp);
									break;
								case 2:	
									(**spmat).real[m]=ffstvaltemp;	// (**spmat).real-(**spmat).imag
									(**spmat).imag[m]=fscndvaltemp;
									break;
								default:
									free(psfiledata);
									return(CreateSpErr(0, errcode14));
							}

							l++;

						}
						else
						{
							//If comment, stop reading line further
							if (psfileline[0] == '!')
							{
								// Allocate space for new comments line
								if(((**strComments).commArr = realloc((**strComments).commArr, sizeof(char*)*(iCommidx+1)))== NULL)
								{
									free(psfiledata);
									return(CreateSpErr(0, errcode6));
								}

								// Add comments line to array
								if  (((**strComments).commArr[iCommidx]=(char*)malloc(sizeof(char)*strlen(strchr(psfilelinetemp, '!'))))==NULL)
								{
									free(psfiledata);
									return(CreateSpErr(0, errcode6));
								}
						
								memset((**strComments).commArr[iCommidx],0x00,(strlen(strchr(psfilelinetemp, '!'))));
								strncpy((**strComments).commArr[iCommidx], strchr(psfilelinetemp,'!')+1, strlen(strchr(psfilelinetemp, '!'))-1);
								(**strComments).nlines=++iCommidx;

								// Go to next line
								psfileline = NULL;
							}
							else
							{
								free(psfiledata);
								return(CreateSpErr(0, errcode13));
							}
						}
					}

			// We've collected all expected data points 
           if(l==iNport*iNport)
		   {
				//Should have gotten all expected data pairs
				if(j!=2*iNport*iNport+2)
				{
					free(psfiledata);
					return(CreateSpErr(0, errcode13));	
				}
				//We're done with this frequency point
				j=1;
				i++;
		    }
		}	
	}

	(**spmat).nfreq=i;

	free(psfiledata);

	return(CreateSpErr(0, errcode0));

	

}
/* ==================================================================== */



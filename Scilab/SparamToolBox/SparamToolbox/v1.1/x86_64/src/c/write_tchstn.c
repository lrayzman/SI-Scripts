//=========================S-parameter ToolBox====================== 
//
// WRITE_TCHSTN()
//  
// Touchstone file write routines
// 
// (c)2010  L. Rayzman
// 
// Created      : 02/06/2010
// Last Modified: 02/14/2014 - Modified routine to write small data chunks
//                             to file 
// ====================================================================
/* ==================================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#define _USE_MATH_DEFINES 
#include <math.h>
#include <time.h>
#include <stdarg.h>
#include <float.h>
#include "spar_type.h"
#include "err_codes.h"
//#include "err_codes.c"




#define BLKSIZE  1024*1024          // Length of temporary memory storage block
#define BLKTHSLD 100                // Length of threshold beyond which 
	                                // block is dumped to file


/* ==================================================================== */
SparErr write_tchstn(char *filename, SParType **spmat)
{




	unsigned int iNport = 0;				// Number of ports
	unsigned int iFilelen = 0;				// File length
	unsigned int iFileidx = 0;				// File pointer index
	unsigned int iBuffLen = 0;				// End of memory storage

	int i, j, k, l, m;
	
	char cDateTimetmpbuf[9];				// Buffer to time and date

	double *pSreal=(**spmat).real;
	double *pSimag=(**spmat).imag;
	double *pSfreq=(**spmat).freq;

	double fprevFreq=-DBL_MIN;				//Previous frequency


	
	FILE *ffspfile;							// File handle
	char *psfilefilename=NULL;				// Actual filename

	char *psfiledata=NULL;					// File contents

	


	/* Allocate memory for temporary storage */
	if((psfiledata=(char*)malloc(sizeof(char)*BLKSIZE))==NULL)
	{
		return(CreateSpErr(0, errcode104));
	}

	iBuffLen=BLKSIZE-BLKTHSLD;


	
    /* Check for extension  */
	if ((i=strlen(filename)) == 0)		// Find the end of filename
	{
		return(CreateSpErr(0, errcode101));
	}
	
	i--;
	j=i;
	while ((filename[j] != '.') && j>=0) j--;


	/* Replace existing extension */
	if(j!=0) 
	{
		j--;		// Workaround for getting the period erased

		// Add an extension if current "extension" doesn't appears to be in *.s*p format
		if ((toupper(filename[j+2])!= 'S') || (toupper(filename[i])!= 'P'))
		{
			j=i;
		}
	}
	/* ...otherwise, add a new one */
	else
	{
		j=i;
	}

	//figure out length of extension from port count
	k=(int)floor(log10((**spmat).nport))+1;

	psfilefilename=(char*)calloc(j+k+5, sizeof(char));
	if(psfilefilename==NULL)
	{
		return(CreateSpErr(0, errcode102));
	}

	// Manually copy string
	for (k=0; k<=j; k++)
	{
		psfilefilename[k]=filename[k];
	}

	//Add extension
	sprintf(psfilefilename,"%s%s%d%c",psfilefilename,".s",(**spmat).nport,'p');

    /* Open file to write */
	if ((ffspfile=fopen(psfilefilename,"w+b")) == NULL) 
	{
	  
	    return(CreateSpErr(0, errcode103));
	}

	/* Create header*/
	j = sprintf((psfiledata+iFilelen), "!Scilab S-parameters Toolbox\n");
	iFilelen=iFilelen+j;
	
	
	j = sprintf((psfiledata+iFilelen), "!Created on %s", _strdate(cDateTimetmpbuf));
	iFilelen=iFilelen+j;

	j = sprintf((psfiledata+iFilelen), " at %s\n", _strtime(cDateTimetmpbuf));
	iFilelen=iFilelen+j;


	j = sprintf((psfiledata+iFilelen), "!Filename: %s\n", psfilefilename);
	iFilelen=iFilelen+j;


	/* Add options line*/
	j = sprintf((psfiledata+iFilelen), "# GHZ S RI R %0.2f", (**spmat).Z0);
	iFilelen=iFilelen+j;


	/* Copy temporary storage into file */
	if((fwrite( psfiledata, sizeof( char ), iFilelen, ffspfile)) != iFilelen)
	{
		return(CreateSpErr(0, errcode106));
	}
	iFilelen=0;

	/* Dump all points for all frequencies into temp storage */
	for (i=0; i<(**spmat).nfreq; i++)
	{

		//Check that frequency value is increasing

		if (*pSfreq <= fprevFreq)
		{
			
			fclose(ffspfile);
			free(psfiledata);
			free(psfilefilename);
			return(CreateSpErr(0, errcode105));
		}

		// Save requency point
		j = sprintf((psfiledata+iFilelen), "\n%0.9e", *pSfreq/1e9);
		iFilelen=iFilelen+j;
		pSfreq++;

		l=0;
	
		//Save data
		for(k=1; k<=((**spmat).nport*(**spmat).nport);k++)
		{

			//Running low on temp memory buffer, dump to file
			if(iFilelen >= iBuffLen)
			{

	     		if((fwrite( psfiledata, sizeof( char ), iFilelen, ffspfile)) != iFilelen)
	            {
		             return(CreateSpErr(0, errcode106));
	            }
				iFilelen=0;
			}

			
			//three port
			if(((**spmat).nport==3) && k>1 && !(l%3))
			{
				j = sprintf((psfiledata+iFilelen), "\n                ");
				iFilelen=iFilelen+j;
				l=0;
			}

			//four or more ports
			if(((**spmat).nport>=4) && k>1 && (!(l%4) || (k-1)==(**spmat).nport))
			{
				j = sprintf((psfiledata+iFilelen), "\n                ");
				iFilelen=iFilelen+j;
				l=0;
			}

			//Sequential ordering for one or two ports
			if((**spmat).nport<=2)
			{
				j = sprintf((psfiledata+iFilelen), " %0.9e", *(pSreal+(k-1)));
				iFilelen=iFilelen+j;

				j = sprintf((psfiledata+iFilelen), " %0.9e", *(pSimag+(k-1)));
				iFilelen=iFilelen+j;

				l++;	
			}
			//Correct the ordering for three or more ports
			else
			{
				m=((k-1)%(**spmat).nport)*(**spmat).nport+(int)floor((double)(k-1)/(double)(**spmat).nport);
				
				j = sprintf((psfiledata+iFilelen), " %0.9e", *(pSreal+m));
				iFilelen=iFilelen+j;

				j = sprintf((psfiledata+iFilelen), " %0.9e", *(pSimag+m));
				iFilelen=iFilelen+j;

				l++;

			}

		}

		pSreal=pSreal+(**spmat).nport*(**spmat).nport;
		pSimag=pSimag+(**spmat).nport*(**spmat).nport;

	}
	
	
	/* Flush out the last memory block to file */
	if((fwrite( psfiledata, sizeof( char ), iFilelen, ffspfile)) != iFilelen)
	{
		return(CreateSpErr(0, errcode106));
	}


	/* Clean up */
	fclose(ffspfile);

	free(psfiledata);
	free(psfilefilename);

	return(CreateSpErr(0, errcode0));

	

}
/* ==================================================================== */



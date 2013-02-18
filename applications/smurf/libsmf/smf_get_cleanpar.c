/*
*+
*  Name:
*     smf_get_cleanpar

*  Purpose:
*     Obtain values of cleaning parameters from a keymap

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_get_cleanpar( AstKeyMap *keymap, const smfData *data, double *badfrac,
*                       dim_t *dcfitbox, int *dcmaxsteps, double *dcthresh,
*                       dim_t *dcsmooth, int *dclimcorr, int *dkclean,
*                       int *fillgaps, int *zeropad, double *filt_edgelow,
*                       double *filt_edgehigh, double *filt_edge_smallscale,
*                       double *filt_edge_largescale,
*                       double *filt_notchlow, double *filt_notchhigh,
*                       int *filt_nnotch, int *dofilt, double *flagslow,
*                       double *flagfast, int *order, double *spikethresh,
*                       dim_t *spikebox, double *noisecliphigh,
*                       double *noisecliplow, int *whiten, int *compreprocess,
*                       dim_t *pcalen, double *pcathresh, int groupsubarray,
*                       double *downsampscale, double *downsampfreq,
*                       int *noiseclipprecom, int *deconvmce, double delay,
*                       double *filt_edgewidth, int *status )

*  Arguments:
*     keymap = AstKeyMap* (Given)
*        keymap containing parameters
*     data = const smfData  * (Given)
*        Pointer to a smfData that is used to define the sample rate
*        needed when converting parameter values form seconds to time
*        slices. If NULL is supplied, a default sample rate of 200 Hz is
*        used.
*     badfrac = double* (Returned)
*        Fraction of bad samples in order for entire bolometer to be
*        flagged as bad (NULL:0)
*     dcfitbox = dim_t* (Returned)
*        Length of box (in samples) over which each linear fit is
*        performed when detecting DC steps. If zero, no steps will be
*        corrected.
*     dcmaxsteps = int* (Returned)
*        The maximum number of DC jumps that can be corrected in each minute
*        of good data (i.e. per 12000 samples) from a bolometer before the
*        entire bolometer is flagged as bad. A value of zero will cause a
*        bolometer to be rejected if any jumps are found in the bolometer
*        data stream.
*     dcthresh = double* (Returned)
*        N-sigma threshold at which to detect DC steps
*     dcsmooth = dim_t * (Returned)
*        Width of median filter for DC step detection.
*     dclimcorr = int * (Returned)
*        The detection threshold for steps that occur at the same time in
*        many bolometers. Set it to zero to suppress checks for correlated
*        steps. If dclimcorr is greater than zero, and a step is found at
*        the same time in more than "dclimcorr" bolometers, then all
*        bolometers are assumed to have a step at that time, and the step
*        is fixed no matter how small it is.
*     dkclean = int* (Returned)
*        If true, clean dark squids from bolos (NULL:-1)
*     fillgaps = int* (Returned)
*        If true, fill regions of data flagged with spikes, DC steps, bad
*        samples with constrained realization of noise.
*     zeropad = int* (Returned)
*        If true, each time stream is padded with zeros at start and end.
*        Otherwise, artificial data that retains continuity between start
*        and end of the data stream is used.
*     filt_edgelow = double* (Returned)
*        Apply a hard-edged low-pass filter at this frequency (Hz) (NULL:0)
*     filt_edgehigh = double* (Returned)
*        Apply a hard-edged high-pass filter at this frequency (Hz) (NULL:0)
*     filt_edge_smallscale* (Returned)
*        Apply low-pass filter that preserves this scale (arcsec) (NULL:0)
*     filt_edge_largescale* (Returned)
*        Apply high-pass filter that preserves this scale (arcsec) (NULL:0)
*     filt_notchlow = double* (Returned)
*        Array of lower-frequency edges for hard notch filters (Hz). The
*        maximum length of this array is SMF__MXNOTCH.
*     filt_notchhigh = double* (Returned)
*        Array of upper-frequency edges for hard notch filters (Hz). The
*        maximum length of this array is SMF__MXNOTCH.
*     filt_nnotch = int* (Returned)
*        Number of notches in notch filter (NULL:0)
*     dofilt = int* (Returned)
*        If true, frequency-domain filtering is required (NULL:0)
*     flagslow = double* (Returned)
*        Flag data during slew speeds less than FLAGSLOW (arcsec/sec) (NULL:0)
*     flagfast = double* (Returned)
*        Flag data during slew speeds greater than FLAGFAST (arcsec/sec)(NULL:0)
*     order = int* (Returned)
*        Fit and remove polynomial baselines of this order (NULL:-1)
*     spikethresh = double* (Returned)
*        Flag spikes SPIKETHRESH-sigma away from mean (NULL:0)
*     spikebox = dim_t* (Returned)
*        The size of the filter box used for flagging spikes.
*     noisecliphigh = double * (Returned)
*        Number of standard deviations to clip the upper bound
*        of a noise distribution in order to generate a bad bolometer
*        mask.
*     noisecliplow = double * (Returned)
*        Number of standard deviations to clip the lower bound
*        of a noise distribution in order to generate a bad bolometer
*        mask.
*     whiten = int * (Returned)
*        Apply a whitening filter to the data?
*     compreprocess = int * (Returned)
*        If set do common-mode rejection and bad-data rejection.
*     pcalen = dim_t * (Returned)
*        Chunk length for PCA cleaning in time slices (if 0 default to full
*        length of the data)
*     pcathresh = double * (Returned)
*        Outlier threshold for PCA amplitudes to remove from data for cleaning
*     groupsubarray = int * (Returned)
*        If set, handle subarrays separately instead of grouping data at same
*        wavelength that were taken simultaneously together.
*     downsampscale = double * (Returned)
*        Determine downsampfreq internally based on this angular scale (arcsec)
*        and the slew speed.
*     downsampfreq = double * (Returned)
*        Target down-sampling rate in Hz.
*     noiseclipprecom = int * (Returned)
*        Should clipping of noisy bolometers happen before common-mode cleaning
*        instead of after as is the default?
*     deconvmce = int * (Returned)
*        Should the effects of the anti-aliasing MCE filter be removed?
*     delay = double * (Returned)
*        A time, in seconds, by which to delay each time stream, causing
*        each sample to be associated with a different position on the sky.
*     filt_edgewidth = double * (Returned)
*        Width of the 0->1 transition zone for a high pass or low pass filter edge
*        (arcsec) (NULL:0)
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function obtains data cleaning values from a keymap and stores
*     them in the supplied variables. The assumed name for each variable in
*     the keymap is the same as the name of the variable. If a NULL pointer
*     is supplied for a given variable, there is no search for its value in
*     the keymap. If a given value is requested (nonzero pointer) and no
*     value exists in the keymap, the value is set to the "NULL" that is given
*     in brackets after the description of each parameter. The notch filter
*     frequency edges are arrays with a maximum length of SMF__MXNOTCH and
*     should be statically allocated before calling this routine. For these
*     special cases (FILT_NOTCHHIGH/NOTCHLOW), if no values are present in the
*     keymap, the way the caller can detect this is by checking the value
*     of filt_nnotch (which will be set to 0).
*
*  Authors:
*     EC: Edward Chapin (UBC)
*     DSB: David S. Berry (JAC, Hawaii)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2009-04-15 (EC):
*        Initial version.
*     2010-01-08 (EC):
*        Add parameter dcflagall to dcflag (renamed from dcbad)
*     2010-01-11 (EC):
*        Add fillgaps
*     2010-03-23 (DSB):
*        Replace old DC jump config parameters with new ones.
*     2010-05-04 (TIMJ):
*        Simplify KeyMap access. We now trigger an error if a key is missing
*        and we ensure all keys have corresponding defaults.
*     2010-07-06 (TIMJ):
*        Add noiseclip parameter.
*     2010-09-10 (DSB):
*        Remove dclimcorr, and rename dcmedianwidth as dcsmooth.
*     2010-09-15 (DSB):
*        Change spikeiter argument to spikebox.
*     2010-09-23 (EC):
*        -Rename FLAGSTAT to FLAGSLOW
*        -Add FLAGFAST
*     2010-09-28 (DSB):
*        Added zeropad.
*     2010-10-12 (EC):
*        Add whiten
*     2010-10-13 (EC):
*        Add compreprocess
*     2011-03-22 (EC):
*        Add pcathresh
*     2011-04-15 (EC):
*        Add groupsubarray
*     2011-06-16 (EC):
*        Add downsampfreq
*     2011-06-21 (EC):
*        Add downsampscale
*     2011-06-22 (EC):
*        Add downsampfreq
*     2011-06-23 (EC):
*        noisecliphigh and noisecliplow instead of noiseclip
*     2011-08-09 (EC):
*        Add noiseclipprecom
*     2011-10-17 (EC):
*        Add pcalen
*     2012-02-21 (EC):
*        Add argument "data" and allow parameters that represent a number
*        of time slices to be given in units of seconds instead.
*     2012-11-14 (DSB):
*        Add argument "deconvmce".
*     2013-02-18 (DSB):
*        Add argument "filt_edgewidth".
*     {enter_further_changes_here}

*  Notes:

*  Copyright:
*     Copyright (C) 2010 Science & Technology Facilities Council.
*     Copyright (C) 2009-2011 University of British Columbia
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
*     MA 02110-1301, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#include <stdio.h>

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/ndg.h"
#include "prm_par.h"

#include "par_par.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

#define FUNC_NAME "smf_get_cleanpar"

void smf_get_cleanpar( AstKeyMap *keymap, const smfData *data, double *badfrac,
                       dim_t *dcfitbox, int *dcmaxsteps, double *dcthresh,
                       dim_t *dcsmooth, int *dclimcorr, int *dkclean,
                       int *fillgaps, int *zeropad, double *filt_edgelow,
                       double *filt_edgehigh, double *filt_edge_smallscale,
                       double *filt_edge_largescale, double *filt_notchlow,
                       double *filt_notchhigh, int *filt_nnotch, int *dofilt,
                       double *flagslow, double *flagfast, int *order,
                       double *spikethresh, dim_t *spikebox,
                       double *noisecliphigh, double *noisecliplow, int *whiten,
                       int *compreprocess, dim_t *pcalen, double *pcathresh,
                       int *groupsubarray, double *downsampscale,
                       double *downsampfreq, int *noiseclipprecom,
                       int *deconvmce, double *delay, double *filt_edgewidth,
                       int *status ) {

  int dofft=0;                  /* Flag indicating that filtering is required */
  int f_nnotch=0;               /* Number of notch filters in array */
  int f_nnotch2=0;              /* Number of notch filters in array */
  int i;                        /* Loop counter */
  int temp;                     /* temporary signed integer */

  /* Main routine */
  if (*status != SAI__OK) return;


  /* Obtain parameters from keymap when non-NULL pointers given */

  if( badfrac ) {
    *badfrac = 0.0;
    astMapGet0D( keymap, "BADFRAC", badfrac );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": BADFRAC=%f", status,
               *badfrac );
  }

  if( dcfitbox ) {
    *dcfitbox = 0;
    smf_get_nsamp( keymap, "DCFITBOX", data, dcfitbox, status );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DCFITBOX=%" DIM_T_FMT, status,
               *dcfitbox );
  }

  if( dcmaxsteps ) {
    *dcmaxsteps = 0;
    astMapGet0I( keymap, "DCMAXSTEPS", &temp );
    if( (temp < 0) ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "DCMAXSTEPS must be 0 or more.", status );
    } else {
      *dcmaxsteps = temp;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DCMAXSTEPS=%i", status,
               *dcmaxsteps );
  }

  if( dclimcorr ) {
    *dclimcorr = 0;
    astMapGet0I( keymap, "DCLIMCORR", dclimcorr );
    if( *dclimcorr < 0 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "DCMLIMCORR must be 0 or more.", status );
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DCLIMCORR=%i", status,
               *dclimcorr );
  }

  if( dcthresh ) {
    *dcthresh = 0;
    astMapGet0D( keymap, "DCTHRESH", dcthresh );
    if( *dcthresh < 0 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "DCTHRESH must be >= 0.", status );
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DCTHRESH=%f", status,
               *dcthresh );
  }

  if( dcsmooth ) {
    *dcsmooth = 0;
    smf_get_nsamp( keymap, "DCSMOOTH", data, dcsmooth, status );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DCSMOOTH=%" DIM_T_FMT, status,
               *dcsmooth );
  }

  if( dkclean ) {
    *dkclean = 0;
    astMapGet0I( keymap, "DKCLEAN", &temp );
    if( temp != 0 && temp != 1 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "DKCLEAN must be either 0 or 1.", status );
    } else {
      *dkclean = temp;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DKCLEAN is %s", status,
               (*dkclean ? "enabled" : "disabled") );
  }

  if( fillgaps ) {
    *fillgaps = 0;
    astMapGet0I( keymap, "FILLGAPS", &temp );
    if( (temp != 0) && (temp != 1) ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "FILLGAPS must be either 0 or 1.", status );
    } else {
      *fillgaps = temp;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": FILLGAPS is %s", status,
               (*fillgaps ? "enabled" : "disabled" ) );
  }

  if( zeropad ) {
    *zeropad = 1;
    astMapGet0I( keymap, "ZEROPAD", &temp );
    if( (temp != 0) && (temp != 1) ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "ZEROPAD must be either 0 or 1.", status );
    } else {
      *zeropad = temp;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": ZEROPAD is %s", status,
               (*zeropad ? "enabled" : "disabled" ) );
  }

  if( filt_edgelow ) {
    *filt_edgelow = 0;
    astMapGet0D( keymap, "FILT_EDGELOW", filt_edgelow );

    if( *filt_edgelow ) {
      dofft = 1;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": FILT_EDGELOW=%f", status,
               *filt_edgelow );
  }

  if( filt_edgehigh ) {
    *filt_edgehigh = 0;
    astMapGet0D( keymap, "FILT_EDGEHIGH", filt_edgehigh );

    if( *filt_edgehigh ) {
      dofft = 1;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": FILT_EDGEHIGH=%f", status,
               *filt_edgehigh );
  }

  if( filt_edge_largescale ) {
    *filt_edge_largescale = 0;
    astMapGet0D( keymap, "FILT_EDGE_LARGESCALE", filt_edge_largescale );

    if( *filt_edge_largescale ) {
      dofft = 1;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": FILT_EDGE_LARGESCALE=%f", status,
               *filt_edge_largescale );
  }

  if( filt_edge_smallscale ) {
    *filt_edge_smallscale = 0;
    astMapGet0D( keymap, "FILT_EDGE_SMALLSCALE", filt_edge_smallscale );

    if( *filt_edge_smallscale ) {
      dofft = 1;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": FILT_EDGE_SMALLSCALE=%f", status,
               *filt_edge_smallscale );
  }

  if( filt_edgewidth ) {
    *filt_edgewidth = 0;
    astMapGet0D( keymap, "FILT_EDGEWIDTH", filt_edgewidth );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": FILT_EDGEWIDTH=%f", status,
               *filt_edgewidth );
  }

  if( filt_notchlow ) {
    if( !astMapGet1D( keymap, "FILT_NOTCHLOW", SMF__MXNOTCH, &f_nnotch,
                      filt_notchlow ) ) {
      f_nnotch=0;
    }
  }

  if( filt_notchhigh ) {
    if( !astMapGet1D( keymap, "FILT_NOTCHHIGH", SMF__MXNOTCH, &f_nnotch2,
                      filt_notchhigh ) ) {
      f_nnotch2=0;
    }
  }

  if( f_nnotch && f_nnotch2 ) {
    /* Number of upper and lower edges must match */
    if( f_nnotch != f_nnotch2 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME,
             ": Elements in FILT_NOTCHHIGH != number in FILT_NOTCHLOW",
             status);
    } else if( (f_nnotch > 1) || (filt_notchlow[0] && filt_notchhigh[0]) ) {
      /* Make sure we have multiple notches, or if there is only 1, that
         the edges are not both set to 0 (defaults from smurf_sc2clean if
         not being used) */
      dofft = 1;
      if( filt_nnotch ) {
        *filt_nnotch = f_nnotch;
      }

      msgOutiff( MSG__DEBUG, "", FUNC_NAME
                 ": number components in notch filter=%i", status,
                 f_nnotch );

      for( i=0; i<f_nnotch; i++ ) {
        msgOutiff( MSG__DEBUG, "", FUNC_NAME ":     %f -- %f Hz", status,
                   filt_notchlow[i], filt_notchhigh[i] );
      }
    } else {
      f_nnotch = 0;
      *filt_nnotch = f_nnotch;
    }
  }

  if( whiten ) {
    astMapGet0I( keymap, "WHITEN", whiten );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": WHITEN is %s", status,
               (*whiten ? "enabled" : "disabled") );

    if( *whiten ) {
      dofft = 1;
    }
  }

  if( dofilt ) {
    *dofilt = dofft;
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DOFILT=%i", status,
               *dofilt );
  }

  if( flagslow ) {
    *flagslow = 0;
    astMapGet0D( keymap, "FLAGSLOW", flagslow );
    if( *flagslow < 0 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "FLAGSLOW cannot be < 0.", status );
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": FLAGSLOW=%f", status,
               *flagslow );
  }

  if( flagfast ) {
    *flagfast = 0;
    astMapGet0D( keymap, "FLAGFAST", flagfast );
    if( *flagfast < 0 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "FLAGFAST cannot be < 0.", status );
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": FLAGFAST=%f", status,
               *flagfast );
  }

  if( order ) {
    *order = -1;
    astMapGet0I( keymap, "ORDER", order );
    if( *order < -1 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "ORDER must be >= -1", status );
    }
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": ORDER=%i", status,
               *order );
  }

  if( spikethresh ) {
    *spikethresh = 0;
    astMapGet0D( keymap, "SPIKETHRESH", spikethresh );
    if( *spikethresh < 0 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "SPIKETHRESH must be >= 0.", status );
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": SPIKETHRESH=%f", status,
               *spikethresh );
  }

  if( spikebox ) {
    *spikebox = 0;
    smf_get_nsamp( keymap, "SPIKEBOX", data, spikebox, status );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": SPIKEBOX=%" DIM_T_FMT, status,
               *spikebox );
  }

  if( noisecliphigh ) {
    astMapGet0D( keymap, "NOISECLIPHIGH", noisecliphigh );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": NOISECLIPHIGH=%g", status,
               *noisecliphigh );
  }

  if( noisecliplow ) {
    astMapGet0D( keymap, "NOISECLIPLOW", noisecliplow );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": NOISECLIPLOW=%g", status,
               *noisecliplow );
  }

  if( compreprocess ) {
    astMapGet0I( keymap, "COMPREPROCESS", compreprocess );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": COMPREPROCESS is %s", status,
               (*compreprocess ? "enabled" : "disabled") );
  }

  if( pcalen ) {
    *pcalen = 0;
    smf_get_nsamp( keymap, "PCALEN", data, pcalen, status );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": PCALEN=%" DIM_T_FMT, status,
               *pcalen );
  }

  if( pcathresh ) {
    *pcathresh = 0;
    astMapGet0D( keymap, "PCATHRESH", pcathresh );
    if( *pcathresh < 0 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "PCATHRESH must be >= 0.", status );
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": PCATHRESH=%f", status,
               *pcathresh );
  }

  if( groupsubarray ) {
    *groupsubarray = 0;
    astMapGet0I( keymap, "GROUPSUBARRAY", &temp );

    if( (temp != 0) && (temp != 1) ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "GROUPSUBARRAY must be either 0 or 1.", status );
    } else {
      *groupsubarray = temp;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": GROUPSUBARRAY is %s", status,
               (*groupsubarray ? "enabled" : "disabled" ) );
  }

  if( downsampscale ) {
    *downsampscale = 0;

    astMapGet0D( keymap, "DOWNSAMPSCALE", downsampscale );

    if( *downsampscale < 0 ) {
      msgOutif( MSG__DEBUG, "", FUNC_NAME
                ": WARNING can't convert downsampscale < 0 to a frequency, "
                "skipping.", status );
      *downsampscale = 0;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DOWNSAMPSCALE=%f", status,
               *downsampscale );
  }

  if( downsampfreq ) {
    *downsampfreq = 0;
    astMapGet0D( keymap, "DOWNSAMPFREQ", downsampfreq );
    if( *downsampfreq < 0 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "DOWNSAMPFREQ must be >= 0.", status );
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DOWNSAMPFREQ=%f", status,
               *downsampfreq );
  }

  if( noiseclipprecom ) {
    *noiseclipprecom = 0;
    astMapGet0I( keymap, "NOISECLIPPRECOM", &temp );
    if( temp != 0 && temp != 1 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "NOISECLIPPRECOM must be either 0 or 1.", status );
    } else {
      *noiseclipprecom = temp;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": NOISECLIPPRECOM is %s", status,
               (*noiseclipprecom ? "enabled" : "disabled") );
  }

  if( deconvmce ) {
    *deconvmce = 0;
    astMapGet0I( keymap, "DECONVMCE", &temp );
    if( temp != 0 && temp != 1 ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "DECONVMCE must be either 0 or 1.", status );
    } else {
      *deconvmce = temp;
    }

    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DECONVMCE is %s", status,
               (*deconvmce ? "enabled" : "disabled") );
  }

  if( delay ) {
    *delay = 0.0;
    astMapGet0D( keymap, "DELAY", delay );
    msgOutiff( MSG__DEBUG, "", FUNC_NAME ": DELAY=%f", status,
               *delay );
  }


}

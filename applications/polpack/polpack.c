/* 
*  Name:
*     polpack.c
*
*  Purpose:
*     Contains all the C functions defined within POLPACK.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils
 
*  Authors:
*     DSB: David Berry (STARLINK)

*  History:
*     27-AUG-1997 (DSB):
*        Original version.
*     22-APR-1999 (DSB):
*        Removed new colourmap argument from doplka.
*     7-DEC-2000 (DSB):
*        Added cstring, pol1_tclex, pol1_tclgt and pol1_tcldl.
*        Modified getSVar to return length of string.
*/


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "f77.h"
#include "sae_par.h"
#include "merswrap.h"
#include <tcl.h>

#define GRP__NOID 0
#define PACK_DIR "POLPACK_DIR"

extern F77_SUBROUTINE(grp_grpsz)( INTEGER(igrp), INTEGER(size),
                                  INTEGER(status) );
extern F77_SUBROUTINE(grp_infoc)( INTEGER(igrp), INTEGER(index),
                                  CHARACTER(item), CHARACTER(value),
                                  INTEGER(status) TRAIL(item) TRAIL(value) );
extern F77_SUBROUTINE(err_rep)( CHARACTER(param), CHARACTER(mess),
                                INTEGER(STATUS) TRAIL(param) TRAIL(mess) );

extern F77_SUBROUTINE(cat_rapnd)( INTEGER(ciout), INTEGER(status) );
extern F77_SUBROUTINE(cat_put0r)( INTEGER(gid), REAL(val), LOGICAL(no), INTEGER(status) );


static Tcl_Interp *interp=NULL;

char *split( char * );
void Error( const char *, int * );
const char *Envir( const char *, int * );
void SetVar( FILE *, char *, char *, int, int * );
char *GetName( int, int, int * );
void SetSVar( FILE *, const char *, const char *, int, int * );
int GetSVar( const char *, char *, int, int * );
void SetIVar( FILE *, const char *, int, int * );
void SetRVar( FILE *, const char *, float, int * );
void SetLVar( FILE *, const char *, LOGICAL(a), int * );
void GetLVar( const char *, LOGICAL(a), int * );
void GetIVar( const char *, int *, int * );
void GetRVar( const char *, float *, int * );
char *cstring( const char *, int, int * );

F77_SUBROUTINE(doplka)( INTEGER(IGRP1), INTEGER(IGRP2), INTEGER(IGRP3), 
                        INTEGER(DPI), LOGICAL(HAREA),
                        LOGICAL(SAREA), INTEGER(PSF),
                        CHARACTER(SI), INTEGER(FIT),
                        INTEGER(OEFIT), CHARACTER(LOGFIL),
                        CHARACTER(BADCOL), CHARACTER(CURCOL), 
                        CHARACTER(REFCOL), CHARACTER(SELCOL), 
                        CHARACTER(VIEW), REAL(PLO), REAL(PHI), 
                        LOGICAL(XHAIR), CHARACTER(XHRCOL), LOGICAL(STHLP),
                        INTEGER(IGRPS), INTEGER(SSIZE), LOGICAL(SKYOFF),
                        INTEGER(SKYPAR), INTEGER(IGRP4), LOGICAL(DBEAM),
                        CHARACTER(MODE), LOGICAL(POL), CHARACTER(REFIN), 
                        INTEGER(STATUS) 
                        TRAIL(SI) TRAIL(LOGFIL) TRAIL(BADCOL)
                        TRAIL(CURCOL) TRAIL(REFCOL) TRAIL(SELCOL)
                        TRAIL(VIEW) TRAIL(XHRCOL) TRAIL(MODE) TRAIL(REFIN) ){
/*
*  Name:
*     doplka

*  Purpose:
*     Activates the main Polka tcl script.

*  Description:
*     This C function executes the POLKA Tcl script in a child process.
*     Values for various user preferences are communicated to the Tcl 
*     script by storing settings for various Tcl variables in a temporary
*     text file whose name is passed to the script. When the Tcl script 
*     terminates, the (potentially modified) options values are read back 
*     from this file and passed back to the caller.

*  Parameters:
*     IGRP1 = INTEGER (Given)
*        The GRP identifier for the group holding the input image names
*        to pass to the TCL script.
*     IGRP2 = INTEGER (Given)
*        The GRP identifier for the group holding the O-ray output image 
*        names to pass to the TCL script.
*     IGRP3 = INTEGER (Given)
*        The GRP identifier for the group holding the E-ray output image 
*        names to pass to the TCL script. Ignored in single-beam mode.
*     DPI = INTEGER (Given)
*        The screen dots per inch to use. If a zero or negative value
*        is supplied, then the TK default is used.
*     HAREA = LOGICAL (Given and Returned)
*        Should the help area be displayed?
*     SAREA = LOGICAL (Given and Returned)
*        Should the status area be displayed?
*     LOGFIL = CHARACTER * ( * ) (Given)
*        The name of a log file in which to store all messages generated
*        by any ATASKs activated by the TCL script.
*     PSF = INTEGER (Given and Returned)
*        The size of star-like features in the image (in pixels).
*     SI = CHARACTER * ( * ) (Given and Returned)
*        A character string specifying which status items to display,
*        and in what order.
*     FIT = INTEGER (Given abd Returned)
*        The fit type (1-5) for aligning images.
*     OEFIT = INTEGER (Given abd Returned)
*        The fit type (1-5) for aligning the O and E rays.
*     BADCOL = CHARACTER (Given and Returned)
*        The colour with which to mark missing pixel data. The supplied
*        variable should be long enough to receive the longest colour name.
*     CURCOL = CHARACTER (Given and Returned)
*        The colour with which to mark the current objects. The supplied
*        variable should be long enough to receive the longest colour name.
*     REFCOL = CHARACTER (Given and Returned)
*        The colour with which to mark the reference objects. The supplied
*        variable should be long enough to receive the longest colour name.
*     SELCOL = CHARACTER (Given and Returned)
*        The colour with which to mark the selected area. The supplied
*        variable should be long enough to receive the longest colour name.
*     VIEW = CHARACTER (Given and Returned)
*        How should the images be viewded? : Aligned or Stacked.
*     PLO = REAL (Given and Returned)
*        The lower percentile for the image display.
*     PHI = REAL (Given and Returned)
*        The upper percentile for the image display.
*     XHAIR = LOGICAL (Given and Returned)
*        Is a cross-hair required over the image display area?
*     XHRCOL = CHARACTER (Given and Returned)
*        The colour with which to draw the cross-hair (if required). The 
*        supplied variable should be long enough to receive the longest 
*        colour name.
*     STHLP = LOGICAL (Given)
*        Should a hyper-text browser be created automatically at start-up
*        displaying the help system contents?
*     IGRPS = INTEGER (Given)
*        Identifier for a GRP group holding the supplied sky frames. This
*        is ignored if SSIZE is zero.
*     SSIZE = INTEGER (Given)
*        The number of sky frames in the group identified by IGRPS.
*     SKYOFF = LOGICAL (Given and Returned)
*        Should the sky background be removed from the output images?
*     SKYPAR = INTEGER (Given and Returned)
*        No. of fitting parameters along each axis of a sky surface.
*     IGRP4 = INTEGER (Given)
*        The GRP identifier for the group holding the name of the output
*        cube holding Stokes parameters.
*     DBEAM = LOGICAL (Given)
*        Run in dual-beam mode?
*     MODE = CHARACTER (Given and Returned)
*        The type of polarisation being measured; Linear or Circular.
*     POL = LOGICAL (Given)
*        Are we processing polarimeter data? This controls the types of 
*        mappings available.
*     REFIN = CHARACTER (Given)
*        The name of the reference image. If blank, then the first image
*        in IGRP1 will be used.
*     STATUS = INTEGER (Given and Returned)
*        The inherited global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     18-APR-1997 (DSB):
*        Original version.
*     28-APR-1999 (DSB):
*        Modified to execute the TCL interpreter in a child process instead
*        of the current process. This gets round problems running POLPACK
*        as a monolith (eg from ICL or from IRAF cl), caused by the AMS
*        being used to communicate both between the command language
*        process and the monolith process, and between the monolith process
*        and the KAPPA/CCDPACK etc processes which are fired up by the
*        TCL script.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*/

   GENPTR_INTEGER(IGRP1)
   GENPTR_INTEGER(IGRP2)
   GENPTR_INTEGER(IGRP3)
   GENPTR_INTEGER(DPI)
   GENPTR_LOGICAL(HAREA)
   GENPTR_LOGICAL(SAREA)
   GENPTR_INTEGER(PSF)
   GENPTR_CHARACTER(SI)
   GENPTR_INTEGER(FIT)
   GENPTR_INTEGER(OEFIT)
   GENPTR_CHARACTER(LOGFIL)
   GENPTR_CHARACTER(BADCOL)
   GENPTR_CHARACTER(CURCOL)
   GENPTR_CHARACTER(REFCOL)
   GENPTR_CHARACTER(SELCOL)
   GENPTR_REAL(PLO)
   GENPTR_REAL(PHI)
   GENPTR_CHARACTER(VIEW)
   GENPTR_LOGICAL(XHAIR)
   GENPTR_CHARACTER(XHRCOL)
   GENPTR_INTEGER(IGRPS)
   GENPTR_INTEGER(SSIZE)
   GENPTR_LOGICAL(SKYOFF)
   GENPTR_LOGICAL(STHLP)
   GENPTR_INTEGER(IGRP4)
   GENPTR_LOGICAL(DBEAM)
   GENPTR_LOGICAL(POL)
   GENPTR_INTEGER(STATUS)
   GENPTR_CHARACTER(MODE)
   GENPTR_CHARACTER(REFIN)

#define BUFLEN 512

   char buf[BUFLEN];
   char *dir = NULL;
   char *name = NULL;
   char file_name[255];
   char outfile_name[255];
   char *script = NULL;
   char *value = NULL;
   int i;
   int report;
   int j;
   int n;                      
   int size;
   FILE *fd = NULL;

/* Check the global status. */
   if( *STATUS != SAI__OK ) return;

/* Get a unique temporary file name. This file is used to pass values to
   the Polka Tcl script. */
   if( !tmpnam( file_name ) ){
      *STATUS = SAI__ERROR;
      Error( "Unable to create a temporary file name using \"tmpnam\".", 
              STATUS );
      return;
   } 

/* Open the file for writing. */
   if( fd ) fclose( fd );
   fd = fopen( file_name, "w" );
   if( !fd ){
      *STATUS = SAI__ERROR;
      Error( "Unable to create a temporary file using \"fopen\".", STATUS );
      return;
   } 

/* If a reference image was supplied store its name, in the "in_list"
   variable. Also set REFONLY to indicate that the first image in
   "in_list" is to be used only as a reference image and is not to be
   included in the list of images to be processed when creating the
   output files. */
   if( cnf_lenf( REFIN, REFIN_length ) > 0 ) {
      SetSVar( fd, "in_list", REFIN, REFIN_length, STATUS );
      SetVar( fd, "REFONLY", "1", 0, STATUS );
   } else {
      SetVar( fd, "REFONLY", "0", 0, STATUS );
   }

/* Get the number of images to process. */
   F77_CALL(grp_grpsz)( INTEGER_ARG(IGRP1), INTEGER_ARG(&size),
                        INTEGER_ARG(STATUS) );

/* Append the name of the input images in the file to variable "in_list". */
   for( i = 1; i <= size && *STATUS == SAI__OK; i++ ){
      name = GetName( *IGRP1, i, STATUS );
      SetVar( fd, "in_list", name, 1, STATUS );
   }

/* If producing Stokes parameters as output, store the name of the output
   data set in variable "stokes". */
   if( *IGRP4 != GRP__NOID ) {
      name = GetName( *IGRP4, 1, STATUS );
      SetVar( fd, "stokes", name, 0, STATUS );
   }

/* Store the name of the O-ray output images in Tcl variable "o_list". */
   if( *IGRP2 != GRP__NOID ) {
      for( i = 1; i <= size && *STATUS == SAI__OK; i++ ){
         name = GetName( *IGRP2, i, STATUS );
         SetVar( fd, "o_list", name, 1, STATUS );
      }
   }

/* Do the same for the E-ray output images (if in dual-beam mode). */
   if( *IGRP3 != GRP__NOID ) {
      if( F77_ISTRUE(*DBEAM) ) {
         for( i = 1; i <= size && *STATUS == SAI__OK; i++ ){
            name = GetName( *IGRP3, i, STATUS );
            SetVar( fd, "e_list", name, 1, STATUS );
         }
      }
   }

/* Store the sky frames in "sky_list" if any have been supplied. */
   if( *SSIZE > 0 ) {
      for( i = 1; i <= *SSIZE && *STATUS == SAI__OK; i++ ){
         name = GetName( *IGRPS, i, STATUS );
         SetVar( fd, "sky_list", name, 1, STATUS );
      }
   }

/* If a positive value has been supplied, store the screen dots per inch
   to use in TCL variable "dpi". */
   if ( *DPI > 0 ) { 
      SetIVar( fd, "dpi", *DPI, STATUS );
   }

/* Indicate if dual or single beam mode should be used, by setting Tcl
   variable DBEAM. */
   SetLVar( fd, "DBEAM", DBEAM, STATUS );

/* If a WWW browser is to be created at start-up define the START_HELP
   variable. */
   if( F77_ISTRUE(*STHLP) ) {
      SetVar( fd, "START_HELP", "1", 0, STATUS );
   }

/* Set the Tcl variables storing the options values to use. */
   SetLVar( fd, "ATASK_SKYOFF", SKYOFF, STATUS );
   SetLVar( fd, "ATASK_XHAIR", XHAIR, STATUS );
   SetLVar( fd, "ATASK_HAREA", HAREA, STATUS );
   SetLVar( fd, "ATASK_SAREA", SAREA, STATUS );
   SetIVar( fd, "ATASK_PSF", *PSF, STATUS );
   SetIVar( fd, "ATASK_SKYPAR", *SKYPAR, STATUS );
   SetSVar( fd, "ATASK_SI", SI, SI_length, STATUS );
   SetSVar( fd, "ATASK_VIEW", VIEW, VIEW_length, STATUS );
   SetSVar( fd, "ATASK_BADCOL", BADCOL, BADCOL_length, STATUS );
   SetSVar( fd, "ATASK_CURCOL", CURCOL, CURCOL_length, STATUS );
   SetSVar( fd, "ATASK_REFCOL", REFCOL, REFCOL_length, STATUS );
   SetSVar( fd, "ATASK_SELCOL", SELCOL, SELCOL_length, STATUS );
   SetSVar( fd, "ATASK_XHRCOL", XHRCOL, XHRCOL_length, STATUS );
   SetIVar( fd, "ATASK_FIT", *FIT, STATUS );
   SetIVar( fd, "ATASK_OEFIT", *OEFIT, STATUS );
   SetRVar( fd, "ATASK_PLO", *PLO, STATUS );
   SetRVar( fd, "ATASK_PHI", *PHI, STATUS );
   SetLVar( fd, "POL", POL, STATUS );
   if( LOGFIL_length > 0 ) {
      SetSVar( fd, "ATASK_LOGFILE", LOGFIL, LOGFIL_length, STATUS );
   }
   if( *IGRP4 != GRP__NOID ) {
      SetSVar( fd, "ATASK_POLMODE", MODE, MODE_length, STATUS );
   }

/* Get another unique temporary file name. This file is used to collect
   any standard output from the TCL script. */
   if( !tmpnam( outfile_name ) ){
      *STATUS = SAI__ERROR;
      Error( "Unable to create a temporary file name using \"tmpnam\".", 
              STATUS );
      return;
   } 

/* Get the value of the package directory environment variable, and
   construct the full command for the TCL script (redirecting standard
   output and error to the temporary file chosen above). The one and only
   argument to the script is the name of the file containing the variable
   values. Also, set the variable POLPACK_DIR to the directory path. */
   dir = (char *) Envir( PACK_DIR, STATUS );      
   if( *STATUS == SAI__OK ){
      script = (char *) malloc( (size_t) ( strlen( dir )
                                           + strlen( "/Polka.tcl " )  
                                           + strlen( file_name ) 
                                           + strlen( " 1>" )  
                                           + strlen( outfile_name ) 
                                           + strlen( " 2>&1" ) 
                                           + 1 ) );
      if( !script ) {
         *STATUS = SAI__ERROR;
         Error( "Failed to allocate memory for full TCL script name.", 
                 STATUS );
      } else {
         strcpy( script, dir );
         strcpy( script + strlen( script ), "/Polka.tcl " );
         strcpy( script + strlen( script ), file_name );
         strcpy( script + strlen( script ), " 1>" );
         strcpy( script + strlen( script ), outfile_name );
         strcpy( script + strlen( script ), " 2>&1" );
         SetVar( fd, "POLPACK_DIR", dir, 0, STATUS );
      }
   }

/* Close the file used to pass arguments to the TCL script. */
   fclose( fd );

/* Execute the TCL script. */
   if( *STATUS == SAI__OK ){
      (void) system( script );

/* Attempt to open the file containing the standard output and error from 
   the TCL script. */
      fd = fopen( outfile_name, "r" );

/* If succesful, display each non-null line of the file and report an error. */
      if( fd ) {

         report = 0;
         while( fgets( buf, BUFLEN, fd ) ){
            if( strlen( buf ) ) {
               msgOut( " ", buf, STATUS );
               report = 1;
            }
         }

         if( report && *STATUS == SAI__OK ){
            *STATUS = SAI__ERROR;
            Error( "Messages received from the TCL script.", STATUS );
         }

         fclose( fd );
         remove( outfile_name );
      }
   }

/* Open the communications file again. The TCL script may have written the
   replacement parameter values into it. */
   if( *STATUS == SAI__OK ){
      fd = fopen( file_name, "r" );
   } else {
      fd = NULL;
   }

   if( fd ){

/* Read each line from it. */
      while( fgets( buf, BUFLEN, fd ) ){
         if( strlen( buf ) ){
            value = split( buf );

            if( !strcmp( buf, "ATASK_SKYOFF" ) ) {
               GetLVar( value, SKYOFF, STATUS );

            } else if( !strcmp( buf, "ATASK_XHAIR" ) ) {
               GetLVar( value, XHAIR, STATUS );

            } else if( !strcmp( buf, "ATASK_HAREA" ) ) {
               GetLVar( value, HAREA, STATUS );

            } else if( !strcmp( buf, "ATASK_SAREA" ) ) {
               GetLVar( value, SAREA, STATUS );

            } else if( !strcmp( buf, "ATASK_PSF" ) ) {
               GetIVar( value, PSF, STATUS );

            } else if( !strcmp( buf, "ATASK_SKYPAR" ) ) {
               GetIVar( value, SKYPAR, STATUS );

            } else if( !strcmp( buf, "ATASK_SI" ) ) {
               (void) GetSVar( value, SI, SI_length, STATUS );

            } else if( !strcmp( buf, "ATASK_FIT" ) ) {
               GetIVar( value, FIT, STATUS );

            } else if( !strcmp( buf, "ATASK_OEFIT" ) ) {
               GetIVar( value, OEFIT, STATUS );

            } else if( !strcmp( buf, "ATASK_PLO" ) ) {
               GetRVar( value, PLO, STATUS );

            } else if( !strcmp( buf, "ATASK_PHI" ) ) {
               GetRVar( value, PHI, STATUS );

            } else if( !strcmp( buf, "ATASK_VIEW" ) ) {
               (void) GetSVar( value, VIEW, VIEW_length, STATUS );

            } else if( !strcmp( buf, "ATASK_XHRCOL" ) ) {
               (void) GetSVar( value, XHRCOL, XHRCOL_length, STATUS );

            } else if( !strcmp( buf, "ATASK_BADCOL" ) ) {
               (void) GetSVar( value, BADCOL, BADCOL_length, STATUS );

            } else if( !strcmp( buf, "ATASK_CURCOL" ) ) {
               (void) GetSVar( value, CURCOL, CURCOL_length, STATUS );

            } else if( !strcmp( buf, "ATASK_REFCOL" ) ) {
               (void) GetSVar( value, REFCOL, REFCOL_length, STATUS );

            } else if( !strcmp( buf, "ATASK_SELCOL" ) ) {
               (void) GetSVar( value, SELCOL, SELCOL_length, STATUS );

            } else if( !strcmp( buf, "ATASK_MODE" ) ) {
               if( *IGRP4 != GRP__NOID ) {
                  (void) GetSVar( value, MODE, MODE_length, STATUS );
               }
            } 
         }
      }
/* Close the communications file. */
      fclose( fd );
   }

/* Remove the temporary file used to pass information to the TCL script. */
   remove( file_name );

/* Free the memory holding the TCL script name. */
   if( script ) free( script );

}

void Error( const char *text, int *STATUS ) {
/*
*  Name:
*     Error

*  Purpose:
*     Report an error using EMS.

*  Description:
*     The supplied text is used as the text of the error message.
*     A blank parameter name is used.

*  Parameters:
*     text
*        The error message text. Only the first 80 characters are used.
*     STATUS
*        A pointer to the global status value. This should have been set
*        to a suitable error value before calling this function.

*  Notes:
*     - If a NULL pointer is supplied for "text", no error is reported.
*/

   DECLARE_CHARACTER(param,1);
   DECLARE_CHARACTER(mess,80);
   int j;

/* Check the supplied pointer. */
   if( text ) {

/* Set the parameter name to a blank string. */
      param[0] = ' ';

/* Copy the first "mess_length" characters of the supplied message into 
      "mess". */
      strncpy( mess, text, mess_length );

/* Pad any remaining bytes with spaces (and replace the terminating null
   character with a space). */
      for( j = strlen(mess); j < mess_length; j++ ) {
         mess[ j ] = ' ';
      }

/* Report the error. */
      F77_CALL(err_rep)( CHARACTER_ARG(param), CHARACTER_ARG(mess),
                         INTEGER_ARG(STATUS) TRAIL_ARG(param) 
                         TRAIL_ARG(mess) );
   }
}

const char *Envir( const char *var, int *STATUS ){
/*
*  Name:
*     Envir

*  Purpose:
*     Get an environment variable.

*  Description:
*     A pointer to the a string holding the value of the specified 
*     environment variable is returned. A NULL pointer is returned an an
*     error is reported if the variable does not exist.

*  Parameters:
*     var
*        The variable name.
*     STATUS
*        A pointer to the global status value. 

*/
   const char *ret;
   char mess[80];

   if( *STATUS != SAI__OK || !var ) return NULL;

   ret = getenv( var );      
   if( !ret ) {
      *STATUS = SAI__ERROR;
      sprintf( mess, "Failed to get environment variable \"%s\".", var );
      Error( mess, STATUS );
   }

   return ret;
}

void SetVar( FILE *fd,  char *name,  char *value, int list, int *STATUS ){
/*
*  Name:
*     SetVar

*  Purpose:
*     Stores the value for a a Tcl variable in a file.

*  Description:
*     This stores the supplied value as a TCL variable assignment statement
*     using the supplied file identifier. If "list" is non-zero a Tcl
*     list is created (or extended if it already exists).

*     
*/

   char mess[80];

   if( *STATUS != SAI__OK ) return;


   if( !list ){
      fputs( "set ", fd );
   } else {
      fputs( "lappend ", fd );
   }

   fputs( name, fd );
   fputs( " \"", fd );
   fputs( value, fd );
   fputs( "\"\n", fd );
}

char *GetName( int igrp, int i, int *STATUS ) {
/*
*  Name:
*     GetName

*  Purpose:
*     Gets an element out of a GRP group.

*  Description:
*     This function returns a pointer to a null-terminated C string holding 
*     an element of a supplied GRP group.

*  Parameters:
*     igrp = int (Given)
*        The GRP identifier for the group.
*     i = int (Given)
*        The index of the element to return.
*     STATUS = *int (Given and Returned)
*        The inherited status.

*  Returned Value:
*     A pointer to a string holding the element. This string should not 
*     be modified or freed by the caller.
*     
*/

   DECLARE_CHARACTER(item,4);
   DECLARE_CHARACTER(name,256);
   DECLARE_INTEGER(IGRP);
   DECLARE_INTEGER(I);
   static char buffer[256];
   char *ret;
   int j;

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return NULL;

/* Store a Fortran string with the value "NAME" for use with GRP_INFOC. */
   item[0] = 'N';
   item[1] = 'A';
   item[2] = 'M';
   item[3] = 'E';

/* Get the name from the group. */
   IGRP = igrp;
   I = i;

   F77_CALL(grp_infoc)( INTEGER_ARG(&IGRP), INTEGER_ARG(&I),
                        CHARACTER_ARG(item), CHARACTER_ARG(name),
                        INTEGER_ARG(STATUS) TRAIL_ARG(item)
                        TRAIL_ARG(name) );

/* Replace all trailing blank characters in the returned Fortran string with 
   null characters. */
   if( *STATUS == SAI__OK ) {
      strcpy( buffer, name );
      for( j = name_length - 1; j >= 0; j-- ) {
         if( isspace( (int) buffer[j] ) ) {
            buffer[j] = 0;
         } else {
            break;
         }
      }
      ret = buffer;
   } else {
      ret = NULL;
   }

/* Return the pointer. */
   return ret;
}

void SetSVar( FILE *interp, const char *var, const char *string, 
               int len, int *STATUS ) {
/*
*  Name:
*     SetSVar

*  Purpose:
*     Store an F77 string in a Tcl variable.

*  Description:
*     This function stores the supplied F77 string in the specified Tcl
*     variable, appending a trailing null character.

*  Parameters:
*     interp = FILE * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     string = const char * (Given)
*        The string to store.
*     len = int (Given)
*        The length of the string to be stored, excluding any trailing
*        null.
*     STATUS = int * (Given and Returned)
*        The inherited status.
*     
*/

   char *buf;
   char mess[81];

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Allocate memory to hold a null-terminated copy of the supplied F77
   string. */
   buf = (char *) malloc ( sizeof(char)*(size_t) ( len + 1 ) );

/* If successful, copy the string, and append a trailing null character. */
   if ( buf ) {
      memcpy( buf, string, len );
      buf[ len ] = 0;

/* Set the Tcl variable value. */
      SetVar( interp, (char *) var, buf, 0, STATUS );

/* Free the memory. */
      free( buf );

/* Report an error if the memory could not be allocated. */
   } else {
      *STATUS = SAI__ERROR;
      sprintf( mess, "Unable to allocate %d bytes of memory. ", len + 1 );
      Error( mess, STATUS );
      sprintf( mess, "Failed to initialise Tcl variable \"%s\".", var );
      Error( mess, STATUS );
   }

}

int GetSVar( const char *val, char *string, int len, int *STATUS ) {
/*
*  Name:
*     GetSVar

*  Purpose:
*     Get an F77 string from a null terminated string.

*  Description:
*     This function gets an F77 string from the specified C string,
*     and stores it in the supplied F77 character variable. Returns the
*     used length of the F77 string.

*  Parameters:
*     val = const char * (Given)
*        The supplied C string.
*     string = char * (Returned)
*        The F77 string to receive the value.
*     len = int (Given)
*        The length of the F77 string.
*     STATUS = int * (Given and Returned)
*        The inherited status.
*     
*/

   int n;
   int i;

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

   for( i = 0; i < len; i++ ) string[ i ] = ' ';
   n = strlen( val );
   if( len < n ) n = len;
   memcpy( string, val, n );
   return n;
}

void SetIVar( FILE *interp, const char *var, int val, int *STATUS ) {
/*
*  Name:
*     SetIVar

*  Purpose:
*     Store an integer in a Tcl variable.

*  Description:
*     This function stores the integer in the specified Tcl variable.

*  Parameters:
*     interp = FILE * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     val = int (Given)
*        The value to store.
*     STATUS = int * (Given and Returned)
*        The inherited status.
*     
*/

   char text[80];

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Format the integer value and store the resulting string in the 
   Tcl variable. */
   sprintf( text, "%d", val );
   SetVar( interp, (char *) var, text, 0, STATUS );

}

void SetRVar( FILE *interp, const char *var, float val, int *STATUS ) {
/*
*  Name:
*     SetRVar

*  Purpose:
*     Store a floating point value in a Tcl variable.

*  Description:
*     This function stores the supplied value in the specified Tcl variable.

*  Parameters:
*     interp = FILE * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     val = float (Given)
*        The value to store.
*     STATUS = int * (Given and Returned)
*        The inherited status.
*     
*/

   char text[80];

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Format the value and store the resulting string in the Tcl variable. */
   sprintf( text, "%g", val );
   SetVar( interp, (char *) var, text, 0, STATUS );

}

void SetLVar( FILE *interp, const char *var, LOGICAL(valptr), int *STATUS ) {
/*
*  Name:
*     SetLVar

*  Purpose:
*     Store an F77 LOGICAL value in a Tcl variable.

*  Description:
*     This function stores the supplied value in the specified Tcl variable.

*  Parameters:
*     interp = FILE * (Given)
*        A pointer to the Tcl interpreter structure.
*     var = const char * (Given)
*        The name of the Tcl variable to use.
*     valptr = LOGICAL (Given)
*        A pointer to the value to store.
*     STATUS = int * (Given and Returned)
*        The inherited status.
*     
*/

   GENPTR_LOGICAL(val)

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Store the value. */
   SetVar( interp, (char *) var, ( F77_ISTRUE(*valptr) ? "1" : "0" ), 
           0, STATUS );

}

void GetLVar( const char *val, LOGICAL(valptr), int *STATUS ) {
/*
*  Name:
*     GetLVar

*  Purpose:
*     Retrieve an F77 LOGICAL value from a C string.

*  Parameters:
*     val = const char * (Given)
*        The C string.
*     valptr = LOGICAL (Returned)
*        A pointer to the F77 variable to receive the returned value.
*     STATUS = int * (Given and Returned)
*        The inherited status.
*     
*/

   GENPTR_LOGICAL(val)

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Tcl uses zero to represent false, and non-zero to represent true. */
   if ( !strncmp( val, "0", 1 ) ) {
      *valptr = F77_FALSE;
   } else {
      *valptr = F77_TRUE;
   }
}

void GetRVar( const char *val, float *valptr, int *STATUS ) {
/*
*  Name:
*     GetRVar

*  Purpose:
*     Retrieve an F77 REAL value from a C string.

*  Parameters:
*     var = const char * (Given)
*        The C string.
*     valptr = float * (Returned)
*        A pointer to the variable to receive the returned value.
*     STATUS = int * (Given and Returned)
*        The inherited status.
*     
*/

   char mess[81];

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

   if( sscanf( val, "%g", valptr ) != 1 ) {
      *STATUS = SAI__ERROR;
      sprintf( mess, "\"%s\" is not a floating point value.", val );
      Error( mess, STATUS );
      sprintf( mess, "Failed to obtained a value for a Tcl variable." );
      Error( mess, STATUS );
   }
}

void GetIVar( const char *val, int *valptr, int *STATUS ) {
/*
*  Name:
*     GetIVar

*  Purpose:
*     Retrieve an F77 INTEGER value from a C string.

*  Parameters:
*     val = const char * (Given)
*        The C string.
*     valptr = int * (Returned)
*        A pointer to the variable to receive the returned value.
*     STATUS = int * (Given and Returned)
*        The inherited status.
*     
*/

   char mess[81];

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

   if( sscanf( val, "%d", valptr ) != 1 ) {
      *STATUS = SAI__ERROR;
      sprintf( mess, "\"%s\" is not an integer value.", val );
      Error( mess, STATUS );
      sprintf( mess, "Failed to obtained a value for Tcl variable." );
      Error( mess, STATUS );
   }
}


char *split( char *buf ){
/*
*  Name:
*     split

*  Purpose:
*     Splits a string up into the first word and the rest. Any spaces
*     inbetween the end of the first word and the start of the second
*     are replaced by nulls, and a pointer is returned to the start of
*     the second word. Any trailing newline character is replaced by a
*     null.

*/
   char *ret;
   char *end;
   int got_name;
   int end_name;

/* Replace any trailing newline character with a null */
   end = buf + strlen( buf ) - 1;
   if( *end == '\n' ) *end = 0;

/* Split the string into name and value */
   got_name = 0;
   end_name = 0;
   end = buf + strlen( buf );

   for( ret = buf; ret < end; ret++ ) {
      if( !got_name ){
         if( !isspace( (int) *ret ) ) got_name = 1;

      } else if( !end_name ){
         if( isspace( (int) *ret ) ){
            *ret = 0;
            end_name = 1;
         } 

      } else {
         if( isspace( (int) *ret ) ){
            *ret = 0;
         } else {
            break;
         } 
      }
   }

   return ret;   
}

F77_SUBROUTINE(pol1_tclex)( CHARACTER(FILE), INTEGER(STATUS) 
                            TRAIL(FILE) ){
/*
*  Name:
*     POL1_TCLEX

*  Purpose:
*     Creates a Tcl interpreter and executes a script in a supplied file.

*  Description:
*     This C function executes a Tcl script in the supplied text file,
*     creating a new Tcl interpreter if necessary to do so. The
*     interpreter should be deleted when no longer needed using POL1_TCLDL.

*  Parameters:
*     FILE = CHARACTER * ( * ) (Given)
*        The name of file containing a Tcl script to be executed in the 
*        interpreter.
*     STATUS = INTEGER (Given and Returned)
*        The inherited global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     7-DEC-2000 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*/

/* Arguments: */
   GENPTR_CHARACTER(FILE)
   GENPTR_INTEGER(STATUS)

/* Local Variables: */
   int code;
   char *file;
   char mess[255];

/* Check the inherited status */
   if( *STATUS != SAI__OK ) return;

/* Get a null terminated copy of the file name. */
   file = cstring( FILE, FILE_length, STATUS );
   if ( file ) {

/* If necessary create an interpreter. */
      if( !interp ) interp = Tcl_CreateInterp();

/* Execute the script. */
      code = Tcl_EvalFile( interp, file );

/* Check for error in the tcl script */
      if( code != TCL_OK ){
         *STATUS = SAI__ERROR;
         if( *interp->result ) {
            sprintf( mess, "Error executing Tcl script %.50s: %.150s\n", file,
                     interp->result );
         } else {
            sprintf( mess, "Error executing Tcl script %.50s", file );
         }
         Error( mess, STATUS );
      }

/*  Free memory used to hold the null-terminated file name */
      free( file );

   }
}

F77_SUBROUTINE(pol1_tcldl)( INTEGER(STATUS) ){
/*
*  Name:
*     POL1_TCLDL

*  Purpose:
*     Deletes a Tcl interpreter.

*  Description:
*     This C function deletes any Tcl interpreter created earlier by
*     POL1_TCLEX, etc.

*  Parameters:
*     STATUS = INTEGER (Given and Returned)
*        The inherited global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     7-DEC-2000 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*/

/* Arguments: */
   GENPTR_INTEGER(STATUS)

/* Just delete any interpreted. Do not check the inherited status since 
   this is a clean up function. */
   if( interp ) {
      Tcl_DeleteInterp( interp );
      interp = NULL;
   }
}

F77_SUBROUTINE(pol1_tclgt)( CHARACTER(VARNAM), INTEGER(ELEM),
                            CHARACTER(VARVAL), INTEGER(NC),
                            INTEGER(STATUS) TRAIL(VARNAM) TRAIL(VARVAL) ){
/*
*  Name:
*     POL1_TCLGT

*  Purpose:
*     Obtains the value of a Tcl list element from a Tcl interpreter.

*  Description:
*     This C function obtains the value of a Tcl list element from a Tcl 
*     interpreter created earlier (e.g. using POL1_TCLEX). Note, this is
*     slow for large lists!!!

*  Parameters:
*     VARNAM = CHARACTER * ( * ) (Given)
*        The name of the Tcl list.
*     ELEM = INTEGER (Given
*        The index of the elment required (zero-based). If -1, the
         variable is obtained as a scalar.
*     VARVAL = CHARACTER * ( * ) (Returned)
*        The value of the list element.
*     NC = INTEGER (Returned)
*        The number of characters returned in the value string.
*     STATUS = INTEGER (Given and Returned)
*        The inherited global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     7-DEC-2000 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*/

/* Arguments: */
   GENPTR_CHARACTER(VARNAM)
   GENPTR_INTEGER(ELEM)
   GENPTR_CHARACTER(VARVAL)
   GENPTR_INTEGER(NC)
   GENPTR_INTEGER(STATUS)

/* Local Variables: */
   int code;
   char *varnam;
   char buf[128];
   char mess[128];

/* Check the inherited status */
   *NC = 0;   
   if( *STATUS != SAI__OK ) return;

/* Do nothing if no interpreter is available. */
   if( interp ) {

/* Get a null terminated copy of the variable name. */
      varnam = cstring( VARNAM, VARNAM_length, STATUS );
      if ( varnam ) {

/* For a string holding a Tcl command which returns the value of the 
   required list element, or scalar. */
         if( *ELEM > -1 ) {
            sprintf( buf, "lindex $%s %d", varnam, *ELEM );
         } else {
            sprintf( buf, "set %s", varnam );
         }

/* Execute this Tcl command. */
         code = Tcl_Eval( interp, buf ); 

/* Check for error in the tcl script */
         if( code != TCL_OK ){
            *STATUS = SAI__ERROR;
            if( *interp->result ) {
               sprintf( mess, "Error executing Tcl command '%.50s': %.150s\n", buf,
                        interp->result );
            } else {
               sprintf( mess, "Error executing Tcl command '%.50s'", buf );
            }
            Error( mess, STATUS );

/* If succesful, return an F77 copy of the result string. */
         } else if( *interp->result ) {
            *NC = GetSVar( interp->result, VARVAL, VARVAL_length, STATUS );
         }

/*  Free memory used to hold the null-terminated variable name */
         free( varnam);
      }
   }
}

char *cstring( const char *fstring, int len, int *STATUS ) {
/*
*  Name:
*     cstring

*  Purpose:
*     Returns a pointer to dynaically allocated memory holding a null
*     terminated copy of an F77 string.

*  Description:
*     This function returns a pointer to dynaically allocated memory 
*     holding a null terminated copy of an F77 string. The pointer should
*     be freed using free() when no longer needed.

*  Parameters:
*     fstring = const char * (Given)
*        The f77 string.
*     len = int (Given)
*        The length of the f77 string to be stored.
*     STATUS = int * (Given and Returned)
*        The inherited status.
*     
*/

   char mess[81];
   char *ret;

   ret = NULL;

/* Check the inherited status. */
   if( *STATUS != SAI__OK ) return;

/* Find the length excluding any trailing spaces. */
   len = len - 1;
   while( len && fstring[len] == ' ' ) len--;
   len++;

/* Allocate memory to hold a null-terminated copy of the supplied F77
   string. */
   ret = (char *) malloc ( sizeof(char)*(size_t) ( len + 1 ) );

/* If successful, copy the string, and append a trailing null character. */
   if ( ret ) {
      memcpy( ret, fstring, len );

      ret[ len ] = 0;

/* Report an error if the memory could not be allocated. */
   } else {
      *STATUS = SAI__ERROR;
      sprintf( mess, "Unable to allocate %d bytes of memory. ", len + 1 );
      Error( mess, STATUS );
   }

   return ret;
}


F77_SUBROUTINE(pol1_rdtdt)( CHARACTER(FILNAM), INTEGER(NCOL),
                            INTEGER_ARRAY(COLID), INTEGER(CIOUT),
                            INTEGER(STATUS) TRAIL(FILNAM) ){
/*
*  Name:
*     POL1_TDTDT

*  Purpose:
*     Read the data from the specified Tcl file.

*  Description:
*     This C function reads the row/column data stored in the tcl variable 
*     data_ in the supplied Tcl file, and copies it into a CAT catalogue.
*     It is implemented in a very low level way to avoid copying the data
*     into a big dynamic array, which is very slow for large data arrays.

*  Parameters:
*     FILENAM = CHARACTER * ( * ) (Given)
*        The name of the Tcl file.
*     NCOL = INTEGER (Given
*        The number of columns in the Tcl table.
*     COLID( NCOL ) = INTEGER (Given)
*        The CAT identifier for the column in which to store each Tcl
*        column. Columns which are not required in the CAT catalogue
*        should be assigned the value -1.
*     CIOUT = INTEGER (Returned)
*        The CAT identifier for the output catalogue.
*     STATUS = INTEGER (Given and Returned)
*        The inherited global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     7-DEC-2000 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*/

/* Arguments: */
   GENPTR_CHARACTER(FILNAM)
   GENPTR_INTEGER(NCOL)
   GENPTR_INTEGER_ARRAY(COLID)
   GENPTR_INTEGER(CIOUT)
   GENPTR_INTEGER(STATUS)

/* Local Variables: */
   DECLARE_LOGICAL(no);
   DECLARE_INTEGER(gid);
   DECLARE_REAL(val);
   char mess[255];
   char *file;
   int i, ok, n, use, nc;
   char buf[81];
   char numbuf[81];
   char *p, *e, *q;
   FILE *fd;

/* Define an f77 false value. */
   no = F77_FALSE;

/* Check the inherited status */
   if( *STATUS != SAI__OK ) return;

/* Get a null terminated copy of the file name. */
   file = cstring( FILNAM, FILNAM_length, STATUS );
   if ( file ) {

/* Open the file. */
      fd = fopen( file, "r" );
      if( !fd ) {
         *STATUS = SAI__ERROR;
         sprintf( mess, "pol1_rdtdt: Error opening file '%s'.\n", file );
         Error( mess, STATUS );
         return;
      }

/* Initialize things. */
      buf[81] = 0;
      e = buf + 81;
      p = e;
      ok = 0;
      q = numbuf;
      *q = 0;
      nc = 0;
   
/* Loop round reading the data stream from the file. */
      while( 1 ) {

/* We we have reached the end of the buffer, re-fill it from the file. If
   the end of the file is reached, abort. */
         if( ! *p ) {
            n = fread( (void *) buf, 1, 81, fd );
            if( !n ) break;

/* If we have not yet found a line containing the string "set data_",
   check the buffer now. If the buffer does not contain the string, 
   continue on for a new buffer. Otherwise, move p on to point to the
   text following the string.*/
            if( !ok ) {
               p = strstr( buf, "set data_" );
               if( !p ){
                  p = e;
                  continue;
               } else {
                  p += 9;
                  ok = 1;
               }
            } else {
               p = buf;
            }
         } 

/*  Count how many number characters there are at the start of the
    remaining part of the buffer. */
         use = strspn( p, "0123456789.-+DEde" );
   
/*  If any, copy them to the number buffer. */
         if( use ) {
            memcpy( q, p, use );
            p += use;
            q += use;
         }
   
/*  If we are still within the buffer, store the number in the number
    buffer in the current row buffer for the output catalogue. */
         if( *p ){
            *q = 0;
            if( numbuf[0] ) {
               sscanf( numbuf, "%f", &val );

               gid = COLID[nc];
               if( gid != -1 ) {
                  F77_CALL(cat_put0r)( INTEGER_ARG(&gid), REAL_ARG(&val),
                                 LOGICAL_ARG(&no), INTEGER_ARG(STATUS) ); 
                  if( *STATUS != SAI__OK ) break;
               }
               nc++;

/* Write out the row buffer when it is full. */
               if( nc == *NCOL ) {
                  F77_CALL(cat_rapnd)( INTEGER_ARG(CIOUT), INTEGER_ARG(STATUS) ); 
                  if( *STATUS != SAI__OK ) break;
                  nc = 0;
               }

            }
            q = numbuf;
   
/*  Skip fowward to the next number character */
            p += strcspn( p, "0123456789.-+DEde" );
   
         }

      }

/*  Close the file. */
      fclose( fd);

/*  Free memory used to hold the null-terminated file name */
      free( file );
   }
}


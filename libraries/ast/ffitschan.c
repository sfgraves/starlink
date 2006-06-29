/*
*+
*  Name:
*     ffitschan.c

*  Purpose:
*     Define a FORTRAN 77 interface to the AST FitsChan class.

*  Type of Module:
*     C source file.

*  Description:
*     This file defines FORTRAN 77-callable C functions which provide
*     a public FORTRAN 77 interface to the FitsChan class.

*  Routines Defined:
*     AST_DELFITS
*     AST_FINDFITS
*     AST_FITSCHAN
*     AST_ISAFITSCHAN
*     AST_PUTCARDS
*     AST_PUTFITS
*     AST_RETAINFITS
*     AST_SETFITS<X>
*     AST_GETFITS<X>

*  Copyright:
*     Copyright (C) 1997-2006 Council for the Central Laboratory of the
*     Research Councils

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public Licence as
*     published by the Free Software Foundation; either version 2 of
*     the Licence, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public Licence for more details.
*     
*     You should have received a copy of the GNU General Public Licence
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: D.S. Berry (Starlink)

*  History:
*     11-DEC-1996 (DSB):
*        Original version.
*     21-FEB-1997 (DSB):
*        Added source and sink functions to AST_FITSCHAN.
*     20-MAR-1997 (DSB):
*        Functions for accessing named keywords removed. Others renamed.
*     28-APR-1997 (DSB):
*        FindFits and GetFits merged.
*     10-SEP-2004 (TIMJ):
*        Only copy the fits header to fortran string if it was found
*        by astFindFits.
*     17-NOV-2004 (DSB):
*        Added AST_SETFITS<X>
*     7-OCT-2005 (DSB):
*        Added AST_GETFITS<X>
*/

/* Define the astFORTRAN77 macro which prevents error messages from
   AST C functions from reporting the file and line number where the
   error occurred (since these would refer to this file, they would
   not be useful). */
#define astFORTRAN77

/* Header files. */
/* ============= */
#include "f77.h"                 /* FORTRAN <-> C interface macros (SUN/209) */
#include "c2f77.h"               /* F77 <-> C support functions/macros */
#include "error.h"               /* Error reporting facilities */
#include "memory.h"              /* Memory handling facilities */
#include "fitschan.h"            /* C interface to the FitsChan class */

#include <stddef.h>
#include <string.h>

/* Prototypes for private functions. */
/* ================================= */
static char *SourceWrap( const char *(*)( void ) );
static void SinkWrap( void (*)( const char * ), const char * );

/* Prototypes for external functions. */
/* ================================== */
/* This is the null function defined by the FORTRAN interface in fobject.c. */
F77_SUBROUTINE(ast_null)( void );

/* Source and sink function interfaces. */
/* ==================================== */
/* These functions are concerned with allowing FORTRAN implementations
   of FitsChan source and sink functions to be passed to the FitsChan 
   class and invoked when necessary by C code in the main class
   implementation. All FORTRAN-specific aspects of this interface are
   encapsulated here. */
static void SinkWrap( void (* sink)( const char * ), const char *line ) {
/*
*  Name:
*     SinkWrap

*  Purpose:
*     Wrapper function to invoke a FORTRAN FitsChan sink function.

*  Type:
*     Private function.

*  Synopsis:
*     static void SinkWrap( void (* sink)( const char * ), const char *line )

*  Description:
*     This function invokes the sink function whose pointer is
*     supplied in order to write an output line to an external data
*     store.

*  Parameters:
*     sink
*        Pointer to a sink function. This should result from a cast
*        applied to a pointer to a function (with two FORTRAN
*        arguments: a character string of length 80 to receive a FITS
*        card and an integer error status), that returns void.  This
*        is the form of FitsChan sink function employed by the FORTRAN
*        language interface to the AST library.
*/

/* Local Variables: */
   DECLARE_CHARACTER(CARD,80);
   DECLARE_INTEGER(STATUS);
   char *d;
   const char *c;
   int i,lim;

/* Check the global error status. */
   if ( !astOK ) return;

/* Copy the supplied null terminated string to a fixed length, blank
   padded string which can be passed to the Fortran routine. */
   c = line;
   d = CARD;

   lim = (int) strlen( line );
   if( lim > 80 ) lim = 80;

   for( i = 0; i < lim; i++ ){
      *(d++) = (*c++);
   }

   for( ; i < 80; i++ ){
      *(d++) = ' ';
   }

/* Cast the sink function pointer to a pointer to the FORTRAN
   subroutine and then invoke it. Transfer the AST error status to and
   from the subroutine's error status argument. */
   STATUS = astStatus;
   ( ( void (*)() ) sink )( CHARACTER_ARG(CARD), INTEGER_ARG(&STATUS)
                            TRAIL_ARG(CARD) );
   astSetStatus( STATUS );
}

static char *SourceWrap( const char *(* source)( void ) ) {
/*
*  Name:
*     SourceWrap

*  Purpose:
*     Wrapper function to invoke a FORTRAN FitsChan source function.

*  Type:
*     Private function.

*  Synopsis:
*     static char *SourceWrap( const char *(* source)( void ) )

*  Description:
*     This function invokes the source function whose pointer is
*     supplied in order to read the next input line from an external
*     data store. It then returns a pointer to a dynamic string
*     containing a copy of the text that was read.

*  Parameters:
*     source
*        Pointer to a source function. This should result from a cast
*        applied to a pointer to a function (with two FORTRAN
*        arguments: a character string of length 80 to return a FITS
*        card and an integer error status), that returns a Fortran
*        integer.  This is the form of FitsChan source function
*        employed by the FORTRAN language interface to the AST
*        library.

*  Returned Value:
*     A pointer to a dynamically allocated, null terminated string
*     containing a copy of the text that was read. This string must be
*     freed by the caller (using astFree) when no longer required.
*
*     A NULL pointer will be returned if there is no more input text
*     to read.

*  Notes:
*     - A NULL pointer value will be returned if this function is
*     invoked with the global error status set or if it should fail
*     for any reason.
*/

/* Local Variables: */
   DECLARE_CHARACTER(CARD,81);   /* Fixed length Fortran string */
   DECLARE_INTEGER(STATUS);      /* Fortran error status value */
   char *result;                 /* Result pointer to return */
   int retval;                   /* Value returned by source subroutine */

/* Initialise. */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Cast the source function pointer to a pointer to the FORTRAN
   function and then invoke it. Transfer the AST error status to and
   from the subroutine's error status argument. */
   STATUS = astStatus;
   retval = ( *(F77_INTEGER_TYPE (*)()) source )( CHARACTER_ARG(CARD),
                                                  INTEGER_ARG(&STATUS)
                                                  TRAIL_ARG(CARD) );
   astSetStatus( STATUS );

/* If a card was returned, make a dynamic copy of it. */
   if ( astOK && retval ) result = astString( CARD, 80 );

/* Return the result. */
   return result;
}

/* FORTRAN interface functions. */
/* ============================ */
/* These functions implement the remainder of the FORTRAN interface. */
F77_INTEGER_FUNCTION(ast_fitschan)( F77_INTEGER_TYPE (* SOURCE)(),
                                    void (* SINK)(),
                                    CHARACTER(OPTIONS),
                                    INTEGER(STATUS)
                                    TRAIL(OPTIONS) ) {
   GENPTR_CHARACTER(OPTIONS)
   F77_INTEGER_TYPE(RESULT);
   char *options;
   const char *(* source)( void );
   int i;
   void (* sink)( const char * );

   astAt( "AST_FITSCHAN", NULL, 0 );
   astWatchSTATUS(

/* Set the source and sink function pointers to NULL if a pointer to
   the null routine AST_NULL has been supplied. */
      source = (const char *(*)( void )) SOURCE;
      if ( source == (const char *(*)( void )) F77_EXTERNAL_NAME(ast_null) ) {
         source = NULL;
      }
      sink = (void (*)( const char * )) SINK;
      if ( sink == (void (*)( const char * )) F77_EXTERNAL_NAME(ast_null) ) {
         sink = NULL;
      }
      options = astString( OPTIONS, OPTIONS_length );

/* Change ',' to '\n' (see AST_SET in fobject.c for why). */
      if ( astOK ) {
         for ( i = 0; options[ i ]; i++ ) {
            if ( options[ i ] == ',' ) options[ i ] = '\n';
         }
      }
      RESULT = astP2I( astFitsChanFor( source, SourceWrap, sink, SinkWrap,
                                       "%s", options ) );
      astFree( options );
   )
   return RESULT;
}

F77_LOGICAL_FUNCTION(ast_isafitschan)( INTEGER(THIS),
                                       INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)
   F77_LOGICAL_TYPE(RESULT);

   astAt( "AST_ISAFITSCHAN", NULL, 0 );
   astWatchSTATUS(
      RESULT = astIsAFitsChan( astI2P( *THIS ) ) ? F77_TRUE : F77_FALSE;
   )
   return RESULT;
}

F77_SUBROUTINE(ast_putcards)( INTEGER(THIS),
                              CHARACTER(CARDS),
                              INTEGER(STATUS)
                              TRAIL(CARDS) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(CARDS)
   char *cards;

   astAt( "AST_PUTCARDS", NULL, 0 );
   astWatchSTATUS(
      cards = astString( CARDS, CARDS_length );
      astPutCards( astI2P( *THIS ), cards );   
      (void) astFree( (void *) cards );
   )
}

F77_SUBROUTINE(ast_putfits)( INTEGER(THIS),
                             CHARACTER(CARD),
                             LOGICAL(OVERWRITE),
                             INTEGER(STATUS)
                             TRAIL(CARD) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(CARD)
   GENPTR_LOGICAL(OVERWRITE)
   int overwrite;
   char *card;

   astAt( "AST_PUTFITS", NULL, 0 );
   astWatchSTATUS(
      card = astString( CARD, CARD_length );
      overwrite = F77_ISTRUE( *OVERWRITE );
      astPutFits( astI2P( *THIS ), card, overwrite );   
      (void) astFree( (void *) card );
   )
}

F77_SUBROUTINE(ast_delfits)( INTEGER(THIS),
                             INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)

   astAt( "AST_DELFITS", NULL, 0 );
   astWatchSTATUS(
      astDelFits( astI2P( *THIS ) );   
   )
}

F77_SUBROUTINE(ast_retainfits)( INTEGER(THIS),
                             INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)

   astAt( "AST_RETAINFITS", NULL, 0 );
   astWatchSTATUS(
      astretainFits( astI2P( *THIS ) );   
   )
}

F77_LOGICAL_FUNCTION(ast_findfits)( INTEGER(THIS),
                                    CHARACTER(NAME),
                                    CHARACTER(CARD),
                                    LOGICAL(INC),
                                    INTEGER(STATUS)
                                    TRAIL(NAME)
                                    TRAIL(CARD) ){
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(NAME)
   GENPTR_CHARACTER(CARD)
   GENPTR_LOGICAL(INC)
   F77_LOGICAL_TYPE(RESULT);
   int i, len;
   char *name;
   char card[ 81 ];
   int inc;

   astAt( "AST_FINDFITS", NULL, 0 );
   astWatchSTATUS(
      name = astString( NAME, NAME_length );
      inc = F77_ISTRUE( *INC );
      RESULT = astFindFits( astI2P( *THIS ), name, card, inc ) ?
               F77_TRUE : F77_FALSE;
      i = 0;
      if ( astOK && F77_ISTRUE(RESULT) ) {
         len = (int) strlen( card );
         for( i = 0; i < CARD_length && i < len; i++ ) CARD[i] = card[i];
      }
      for( ; i < CARD_length; i++ ) CARD[i] = ' ';
      (void) astFree( (void *) name );
   )
   return RESULT;
}


F77_SUBROUTINE(ast_setfitsf)( INTEGER(THIS),
                              CHARACTER(NAME),
                              DOUBLE(VALUE),
                              CHARACTER(COMMENT),
                              LOGICAL(OVERWRITE),
                              INTEGER(STATUS)
                              TRAIL(NAME)
                              TRAIL(COMMENT) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(NAME)
   GENPTR_DOUBLE(VALUE)
   GENPTR_CHARACTER(COMMENT)
   GENPTR_LOGICAL(OVERWRITE)
   int overwrite;
   char *name, *comment;

   astAt( "AST_SETFITSF", NULL, 0 );
   astWatchSTATUS(
      name = astString( NAME, NAME_length );
      comment = astString( COMMENT, COMMENT_length );
      overwrite = F77_ISTRUE( *OVERWRITE );
      astSetFitsF( astI2P( *THIS ), name, *VALUE, comment, overwrite );   
      (void) astFree( (void *) name );
      (void) astFree( (void *) comment );
   )
}


F77_SUBROUTINE(ast_setfitsi)( INTEGER(THIS),
                              CHARACTER(NAME),
                              INTEGER(VALUE),
                              CHARACTER(COMMENT),
                              LOGICAL(OVERWRITE),
                              INTEGER(STATUS)
                              TRAIL(NAME)
                              TRAIL(COMMENT) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(NAME)
   GENPTR_INTEGER(VALUE)
   GENPTR_CHARACTER(COMMENT)
   GENPTR_LOGICAL(OVERWRITE)
   int overwrite;
   char *name, *comment;

   astAt( "AST_SETFITSI", NULL, 0 );
   astWatchSTATUS(
      name = astString( NAME, NAME_length );
      comment = astString( COMMENT, COMMENT_length );
      overwrite = F77_ISTRUE( *OVERWRITE );
      astSetFitsI( astI2P( *THIS ), name, *VALUE, comment, overwrite );   
      (void) astFree( (void *) name );
      (void) astFree( (void *) comment );
   )
}


F77_SUBROUTINE(ast_setfitscf)( INTEGER(THIS),
                               CHARACTER(NAME),
                               DOUBLE_ARRAY(VALUE),
                               CHARACTER(COMMENT),
                               LOGICAL(OVERWRITE),
                               INTEGER(STATUS)
                               TRAIL(NAME)
                               TRAIL(COMMENT) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(NAME)
   GENPTR_DOUBLE_ARRAY(VALUE)
   GENPTR_CHARACTER(COMMENT)
   GENPTR_LOGICAL(OVERWRITE)
   int overwrite;
   char *name, *comment;

   astAt( "AST_SETFITSCF", NULL, 0 );
   astWatchSTATUS(
      name = astString( NAME, NAME_length );
      comment = astString( COMMENT, COMMENT_length );
      overwrite = F77_ISTRUE( *OVERWRITE );
      astSetFitsCF( astI2P( *THIS ), name, VALUE, comment, overwrite );   
      (void) astFree( (void *) name );
      (void) astFree( (void *) comment );
   )
}


F77_SUBROUTINE(ast_setfitsci)( INTEGER(THIS),
                               CHARACTER(NAME),
                               INTEGER_ARRAY(VALUE),
                               CHARACTER(COMMENT),
                               LOGICAL(OVERWRITE),
                               INTEGER(STATUS)
                               TRAIL(NAME)
                               TRAIL(COMMENT) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(NAME)
   GENPTR_INTEGER_ARRAY(VALUE)
   GENPTR_CHARACTER(COMMENT)
   GENPTR_LOGICAL(OVERWRITE)
   int overwrite;
   char *name, *comment;

   astAt( "AST_SETFITSCI", NULL, 0 );
   astWatchSTATUS(
      name = astString( NAME, NAME_length );
      comment = astString( COMMENT, COMMENT_length );
      overwrite = F77_ISTRUE( *OVERWRITE );
      astSetFitsCI( astI2P( *THIS ), name, VALUE, comment, overwrite );   
      (void) astFree( (void *) name );
      (void) astFree( (void *) comment );
   )
}


F77_SUBROUTINE(ast_setfitsl)( INTEGER(THIS),
                              CHARACTER(NAME),
                              LOGICAL(VALUE),
                              CHARACTER(COMMENT),
                              LOGICAL(OVERWRITE),
                              INTEGER(STATUS)
                              TRAIL(NAME)
                              TRAIL(COMMENT) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(NAME)
   GENPTR_LOGICAL(VALUE)
   GENPTR_CHARACTER(COMMENT)
   GENPTR_LOGICAL(OVERWRITE)
   int overwrite, value;
   char *name, *comment;

   astAt( "AST_SETFITSL", NULL, 0 );
   astWatchSTATUS(
      name = astString( NAME, NAME_length );
      comment = astString( COMMENT, COMMENT_length );
      overwrite = F77_ISTRUE( *OVERWRITE );
      value = F77_ISTRUE( *VALUE );
      astSetFitsL( astI2P( *THIS ), name, value, comment, overwrite );   
      (void) astFree( (void *) name );
      (void) astFree( (void *) comment );
   )
}


F77_SUBROUTINE(ast_setfitss)( INTEGER(THIS),
                              CHARACTER(NAME),
                              CHARACTER(VALUE),
                              CHARACTER(COMMENT),
                              LOGICAL(OVERWRITE),
                              INTEGER(STATUS)
                              TRAIL(NAME)
                              TRAIL(VALUE)
                              TRAIL(COMMENT) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(NAME)
   GENPTR_CHARACTER(VALUE)
   GENPTR_CHARACTER(COMMENT)
   GENPTR_LOGICAL(OVERWRITE)
   int overwrite;
   char *name, *comment, *value;

   astAt( "AST_SETFITSS", NULL, 0 );
   astWatchSTATUS(
      name = astString( NAME, NAME_length );
      value = astString( VALUE, VALUE_length );
      comment = astString( COMMENT, COMMENT_length );
      overwrite = F77_ISTRUE( *OVERWRITE );
      astSetFitsS( astI2P( *THIS ), name, value, comment, overwrite );   
      (void) astFree( (void *) name );
      (void) astFree( (void *) value );
      (void) astFree( (void *) comment );
   )
}

F77_SUBROUTINE(ast_setfitscn)( INTEGER(THIS),
                               CHARACTER(NAME),
                               CHARACTER(VALUE),
                               CHARACTER(COMMENT),
                               LOGICAL(OVERWRITE),
                               INTEGER(STATUS)
                               TRAIL(NAME)
                               TRAIL(VALUE)
                               TRAIL(COMMENT) ) {
   GENPTR_INTEGER(THIS)
   GENPTR_CHARACTER(NAME)
   GENPTR_CHARACTER(VALUE)
   GENPTR_CHARACTER(COMMENT)
   GENPTR_LOGICAL(OVERWRITE)
   int overwrite;
   char *name, *comment, *value;

   astAt( "AST_SETFITSS", NULL, 0 );
   astWatchSTATUS(
      name = astString( NAME, NAME_length );
      value = astString( VALUE, VALUE_length );
      comment = astString( COMMENT, COMMENT_length );
      overwrite = F77_ISTRUE( *OVERWRITE );
      astSetFitsCN( astI2P( *THIS ), name, value, comment, overwrite );   
      (void) astFree( (void *) name );
      (void) astFree( (void *) value );
      (void) astFree( (void *) comment );
   )
}

#define MAKE_AST_GETFITS(f,F,Ftype,X,Xtype) \
F77_LOGICAL_FUNCTION(ast_getfits##f)( INTEGER(THIS), \
                                      CHARACTER(NAME), \
                                      Ftype(VALUE), \
                                      INTEGER(STATUS) \
                                      TRAIL(NAME) ){ \
   GENPTR_INTEGER(THIS) \
   GENPTR_CHARACTER(NAME) \
   GENPTR_##Ftype(VALUE) \
   GENPTR_INTEGER(STATUS) \
   F77_LOGICAL_TYPE(RESULT); \
\
   char *name; \
   Xtype *value; \
\
   value = (Xtype *) VALUE; \
\
   astAt( "AST_GETFITS"#F, NULL, 0 ); \
   astWatchSTATUS( \
      name = astString( NAME, NAME_length ); \
      RESULT = astGetFits##X( astI2P( *THIS ), name, value ) ? \
               F77_TRUE : F77_FALSE; \
      (void) astFree( (void *) name ); \
   ) \
   return RESULT; \
}

MAKE_AST_GETFITS(f,F,DOUBLE,F,double)
MAKE_AST_GETFITS(i,I,INTEGER,I,int)
MAKE_AST_GETFITS(l,L,LOGICAL,L,int)
#undef MAKE_AST_GETFITS



#define MAKE_AST_GETFITS(f,F,Ftype,X,Xtype) \
F77_LOGICAL_FUNCTION(ast_getfits##f)( INTEGER(THIS), \
                                      CHARACTER(NAME), \
                                      Ftype##_ARRAY(VALUE), \
                                      INTEGER(STATUS) \
                                      TRAIL(NAME) ){ \
   GENPTR_INTEGER(THIS) \
   GENPTR_CHARACTER(NAME) \
   GENPTR_##Ftype##_ARRAY(VALUE) \
   GENPTR_INTEGER(STATUS) \
   F77_LOGICAL_TYPE(RESULT); \
\
   char *name; \
   Xtype value[2]; \
\
   astAt( "AST_GETFITS"#F, NULL, 0 ); \
   astWatchSTATUS( \
      name = astString( NAME, NAME_length ); \
      RESULT = astGetFits##X( astI2P( *THIS ), name, value ) ? \
               F77_TRUE : F77_FALSE; \
      VALUE[ 0 ] = (F77_DOUBLE_TYPE) value[ 0 ]; \
      VALUE[ 1 ] = (F77_DOUBLE_TYPE) value[ 1 ]; \
      (void) astFree( (void *) name ); \
   ) \
   return RESULT; \
}


MAKE_AST_GETFITS(cf,CF,DOUBLE,CF,double)
MAKE_AST_GETFITS(ci,CI,INTEGER,CI,int)

#undef MAKE_AST_GETFITS

#define MAKE_AST_GETFITS(f,F,X) \
F77_LOGICAL_FUNCTION(ast_getfits##f)( INTEGER(THIS), \
                                      CHARACTER(NAME), \
                                      CHARACTER(VALUE), \
                                      INTEGER(STATUS) \
                                      TRAIL(NAME) \
                                      TRAIL(VALUE) ){ \
   GENPTR_INTEGER(THIS) \
   GENPTR_CHARACTER(NAME) \
   GENPTR_CHARACTER(VALUE) \
   GENPTR_INTEGER(STATUS) \
   F77_LOGICAL_TYPE(RESULT); \
\
   char *name; \
   int i, len; \
   char *value; \
\
   astAt( "AST_GETFITS"#F, NULL, 0 ); \
   astWatchSTATUS( \
      name = astString( NAME, NAME_length ); \
      RESULT = astGetFits##X( astI2P( *THIS ), name, &value ) ? \
               F77_TRUE : F77_FALSE; \
      if ( astOK && F77_ISTRUE(RESULT) ) { \
         len = (int) strlen( value ); \
         for( i = 0; i < VALUE_length && i < len; i++ ) VALUE[i] = value[i]; \
      } else { \
         i = 0; \
      } \
      for( ; i < VALUE_length; i++ ) VALUE[i] = ' '; \
      (void) astFree( (void *) name ); \
   ) \
   return RESULT; \
}

MAKE_AST_GETFITS(s,S,S)
MAKE_AST_GETFITS(cn,CN,CN)

#undef MAKE_AST_GETFITS




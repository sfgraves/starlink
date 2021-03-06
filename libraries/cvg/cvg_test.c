/*
*+
*  Name:
*     CVG_TEST

*  Purpose:
*     Test installation of the stand-alone CVG package.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     PROGRAM

*  Description:
*     This program tests the installation of the stand-alone CVG
*     package. Note, it is not an exhaustive test of the CVG_ system
*     itself.

*  Copyright:
*     Copyright (C) 2013 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     14-NOV-2013 (DSB):
*        Original version
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*/

#include "star/cvg.h"
#include "sae_par.h"
#include "mers.h"
#include "ast.h"
#include "fitsio.h"

#define NROW 3
#define NAMELEN 10

int main( void ){
   AstFitsChan *fc;
   AstFitsTable *table;
   char name[ NROW ][ NAMELEN ] = { "Tom", "Dick", "Harry" };
   double colx[ NROW ] = { -1.0, 0.0, 1.0 };
   double coly[ NROW ] = { 101.1, 202.2, 303.3 };
   double etal;
   fitsfile *fptr;
   int blockf;
   int fstat = 0;
   int status;

/* Initialise the global status */
   status = SAI__OK;

   astBegin;

   table = astFitsTable( NULL, " " );
   astAddColumn( table, "COLX", AST__DOUBLETYPE, 0, NULL, "Pixel" );
   astAddColumn( table, "COLY", AST__DOUBLETYPE, 0, NULL, "Pixel" );
   astAddColumn( table, "NAME", AST__STRINGTYPE, 0, NULL, "" );

   astPutColumnData( table, "COLX", 0, sizeof( colx ), colx );
   astPutColumnData( table, "COLY", 0, sizeof( coly ), coly );
   astPutColumnData( table, "NAME", NAMELEN, sizeof( name ), name );

   fc = astFitsChan( NULL, NULL, " " );
   astPutFits( fc, "TELESCOP= 'JCMT    '           / Name of Telescope", 0 );
   astPutFits( fc, "ORIGIN  = 'Joint Astronomy Centre, Hilo' / Origin of file", 0 );
   astPutFits( fc, " ", 0 );
   astPutFits( fc, "        ---- x,y,z triplet for JCMT relative to centre of earth ----", 0 );
   astPutFits( fc, "ALT-OBS =               4120.0 / [m] Height of observatory above sea level", 0 );
   astPutFits( fc, "LAT-OBS =      19.822838905884 / [deg] Latitude of Observatory", 0 );
   astPutFits( fc, "LONG-OBS=    -155.477027838737 / [deg] East longitude of observatory", 0 );
   astPutFits( fc, "OBSGEO-X=    -5464588.84421314 / [m]", 0 );
   astPutFits( fc, "OBSGEO-Y=    -2493000.19137644 / [m]", 0 );
   astPutFits( fc, "OBSGEO-Z=     2150653.35350771 / [m]", 0 );
   astPutFits( fc, "ETAL    =                  0.6 / Telescope efficiency", 0 );
   astPutTableHeader( table, fc );

   cvgNew( "test.fit", 1, 1, &fptr, &status );
   cvgFt2bt( table, fptr, "TESTEX", 0, 1, &status );
   cvgClose( &fptr, &status );


   cvgOpen( "test.fit", "Read", &fptr, &blockf, &status );
   fits_movabs_hdu( fptr, 2, NULL, &fstat );

   fc = astFitsChan( NULL, NULL, " " );
   cvgHd2fc( fptr, fc, &status );
   astGetFitsF( fc, "ETAL", &etal );
   if( etal != 0.6 && status == SAI__OK ) {
      status = SAI__ERROR;
      errRepf( " ", "Bad ETAL value (%g) - should be 0.6", &status, etal );
   }

   cvgShowHeader( fptr, 1, &status );
   cvgClose( &fptr, &status );

/* If an error occurred, then report a contextual message. */
   if( status != SAI__OK ) {
      errRep( "", "CVG_TEST: CVG_ installation test failed.", &status );
   } else {
      msgOut( "", "CVG_TEST: CVG_ installation test passed.", &status );
   }

   astEnd;

   return status;
}





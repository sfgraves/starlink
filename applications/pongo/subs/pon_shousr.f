      SUBROUTINE PON_SHOUSR( SHOEXT, PAGNAM, N, FROM, TO, STATUS )
*+
*  Name:
*     PON_SHOUSR
 
*  Purpose:
*     Display a list of items at the terminal with pagination.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL PON_SHOUSR( SHOEXT, PAGNAM, N, FROM, TO, STATUS )
 
*  Description:
*     Controls output to the terminal so that it does not scroll off the
*     screen. The lines of output are generated by the supplied routine
*     SHOEXT, which should be defined as
*     
*        SUBROUTINE SHOEXT( I, NLINES, STATUS )
*
*     where
*     
*        I      is the element of the list to be output;
*        NLINES is the actual number of lines output.
*
*     The number of lines to be output is determined by PAGNAM, which
*     should be the name of an INTEGER parameter to be read to
*     determine the page length.
*
*     When the routine SHOEXT is called with I=0, it should output a
*     page header.
 
*  Arguments:
*     SHOEXT = EXTERNAL
*        Name of routine to be used to actually deliver an element.
*     PAGNAM = CHARACTER * ( * ) (Given and Returned)
*        The name of the ADAM parameter which contains the length of
*        the terminal page.
*     N = INTEGER (Given)
*        The number of elements to be delivered.
*     FROM = INTEGER (Given)
*        The index of the first element to be displayed (0=>1).
*     TO = INTEGER (Given)
*        The index of the last element to be displayed (0=> the last
*        last).
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Authors:
*     JBVAD::PAH: Paul Harrison (STARLINK)
*     PCTR: P.C.T. Rees (STARLINK)
*     PDRAPER: P.W. Draper (STARLINK - Durham University)
*     {enter_new_authors_here}
 
*  History:
*     10-APR-1990 (JBVAD::PAH):
*        Original version.
*     24-JUN-1992 (PCTR):
*        Code tidy and prologue changes.
*     22-JUN-1994 (PDRAPER):
*        Sorted out problem with incorrect STATUS usage.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PAR_ERR'          ! PAR_ error codes
 
*  Arguments Given:
      EXTERNAL SHOEXT

      CHARACTER * ( * ) PAGNAM

      INTEGER N
      INTEGER FROM
      INTEGER TO
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER IFIN               ! Last element to be written
      INTEGER IOUT               ! Element to be output
      INTEGER IST                ! First element to be written
      INTEGER NL                 ! Number of lines output per element
      INTEGER NLINES             ! Number of lines output on this page
      INTEGER NOUT               ! Number of elements to be output
      INTEGER PAGELEN            ! Length of page in lines
 
*.
 
*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get the page length.
      CALL PAR_GET0I( PAGNAM, PAGELEN, STATUS )
 
      IF ( N .GT. 0 ) THEN
 
*     Calculate the first and last elements to be delivered, taking
*     into account the possibility of the zero defaults having been
*     passed.
         IST = MIN( MAX( 1, FROM ), N )
         IFIN = MAX( MIN( N, TO ), 0 )
         IF ( IFIN .EQ. 0 ) IFIN = N
         IFIN = MAX( IFIN, IST )
         NOUT = IFIN - IST + 1
 
*     Write the header.
         CALL SHOEXT( -1, NL, STATUS )
         NLINES = NL
         IOUT = 1

*     Loop to display lines to the user.
*     DO WHILE loop.
 10      CONTINUE
         IF ( IOUT .LE. NOUT .AND. STATUS .EQ. SAI__OK ) THEN
 
*        Write an individual data element.
            CALL SHOEXT( IOUT+IST-1, NL, STATUS )
 
*        Calculate the nuber of lines output to the page so far.
            NLINES = NLINES + NL

            IF ( NLINES .GE. PAGELEN-NL ) THEN
 
*           If this means that the top data item is about to scroll
*           off the page, ask for the parameter PAGNAM.
               CALL PAR_CANCL( PAGNAM, STATUS )
               CALL PAR_GET0I( PAGNAM, PAGELEN, STATUS )

               IF ( STATUS .EQ. PAR__NULL ) THEN
 
*              Signal an early exit if a null value was returned.
                  IOUT = NOUT + 1
 
*              Clear up any error in this case.
                  CALL ERR_ANNUL( STATUS )
               END IF

               NLINES = 0
            END IF

            IOUT = IOUT + 1
         GO TO 10
         END IF
      ELSE
         STATUS = SAI__ERROR
         CALL ERR_REP( 'PON_SHOUSR_NONE', 'No entries to be shown.',
     :                 STATUS )
      END IF
 
      END
* $Id$

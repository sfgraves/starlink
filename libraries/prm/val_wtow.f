      INTEGER*2 FUNCTION VAL_WTOW( BAD, ARG, STATUS )
*+
*  Name:
*     VAL_WTOW
 
*  Purpose:
*     Copy a WORD value.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_WTOW( BAD, ARG, STATUS )
 
*  Description:
*     The routine copies a value of type WORD.  It forms part of the
*     set of type conversion routines, but in this instance the
*     argument and result types are both the same, so the argument
*     value is simply copied.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument value (ARG) may be "bad" (this argument
*        actually has no effect on the behaviour of this routine, but
*        is present to match the other type conversion routines).
*     ARG = INTEGER*2 (Given)
*        The WORD value to be copied.
*     STATUS = INTEGER (Given)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADW.  This routine
*        cannot produce numerical errors, so the STATUS argument will
*        not be changed.
 
*  Returned Value:
*     VAL_WTOW = INTEGER*2
*        Returns the copied WORD value.  The value VAL__BADW will
*        be returned if STATUS is not SAI__OK on entry.
 
*  Authors:
*     R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     4-JUL-1988 (RFWS):
*        Original version.
*     {enter_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

      INCLUDE 'PRM_PAR'          ! PRM_ public constants

 
*  Arguments Given:
      LOGICAL BAD                ! Bad data flag
      INTEGER*2 ARG                 ! Value to be copied
 
*  Status:
      INTEGER STATUS             ! Error status
 
*.
 
*  Check status.  Return the function result VAL__BADW if not OK.
      IF( STATUS .NE. SAI__OK ) THEN
         VAL_WTOW = VAL__BADW
 
*  If OK, return the argument value.
      ELSE
         VAL_WTOW = ARG
      ENDIF
 
*  Exit routine.
      END

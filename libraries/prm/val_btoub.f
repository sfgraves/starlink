      BYTE FUNCTION VAL_BTOUB( BAD, ARG, STATUS )
*+
*  Name:
*     VAL_BTOUB
 
*  Purpose:
*     Convert a value from BYTE to UNSIGNED BYTE.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_BTOUB( BAD, ARG, STATUS )
 
*  Description:
*     The routine performs type conversion on a value of type BYTE,
*     converting it to the equivalent UNSIGNED BYTE value.  If a numerical
*     error occurs, the value VAL__BADUB is returned and a STATUS
*     value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument value (ARG) may be "bad".
*     ARG = BYTE (Given)
*        The BYTE value to be converted.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADUB.  A STATUS
*        value will be set by this routine if a numerical error occurs
*        during type conversion.
 
*  Returned Value:
*     VAL_BTOUB = BYTE
*        Returns the converted UNSIGNED BYTE value.  The value VAL__BADUB
*        will be returned under error conditions.
 
*  Authors:
*     R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     11-AUG-1988 (RFWS):
*        Original version.
*     28-OCT-1991 (RFWS):
*        Added LIB$REVERT call.
*     5-NOV-1991 (RFWS):
*        Removed condition handler; use explicit bounds checks instead
*        in the interests of portability.
*     28-JAN-1992 (RFWS):
*        Temporarily removed adjustments to data limits to account for
*        rounding.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

      INCLUDE 'PRM_PAR'          ! PRM_ public constants

      INCLUDE 'PRM_ERR'          ! PRM_ error codes

 
*  Arguments Given:
      LOGICAL BAD                ! Bad data flag
      BYTE ARG                 ! Value to be converted
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  Local Variables:
      BYTE HI                  ! Upper bound on argument
      BYTE LO                  ! Lower bound on argument
      DOUBLE PRECISION DHI       ! Upper bound on data
      DOUBLE PRECISION DLO       ! Lower bound on data
      LOGICAL FIRST              ! First invocation?
 
      SAVE FIRST
      SAVE HI
      SAVE LO
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_B'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_B'      ! Define NUM_ arithmetic functions

 
*  Local Data:
      DATA FIRST / .TRUE. /      ! First invocation
 
*.
 
*  If the conversion can potentially fail, then on the first invocation
*  set up the lower and upper bounds on the argument values.
      IF ( .TRUE. ) THEN
         IF ( FIRST ) THEN
 
*  Find the intersection of the ranges of allowed values between the
*  input and output data types. Perform this calculation in double
*  precision.
            DLO = MAX( NUM_BTOD( NUM__MINB ),
     :                 NUM_UBTOD( NUM__MINUB ) )
            DHI = MIN( NUM_BTOD( NUM__MAXB ),
     :                 NUM_UBTOD( NUM__MAXUB ) )
 
*  Adjust the resulting limits to allow for rounding of both the input
*  and output data types.
C            IF ( DLO .GT. 0.0D0 ) THEN
C               DLO = DLO - 0.5D0 * NUM_UBTOD( VAL__EPSUB )
C            ELSE
C               DLO = DLO - 0.5D0 * ( NUM_UBTOD( VAL__EPSUB ) -
C     :                               NUM_BTOD( VAL__EPSB ) )
C            END IF
C            IF ( DHI .GT. 0.0D0 ) THEN
C               DHI = DHI + 0.5D0 * ( NUM_UBTOD( VAL__EPSUB ) -
C     :                               NUM_BTOD( VAL__EPSB ) )
C            ELSE
C               DHI = DHI + 0.5D0 * NUM_UBTOD( VAL__EPSUB )
C            END IF
C
*  Convert the limits to the input data type and note they have been
*  set up.
            LO = NUM_DTOB( DLO )
            HI = NUM_DTOB( DHI )
            FIRST = .FALSE.
         END IF
      END IF
 
*  Check status.  Return the function result VAL__BADUB if not OK.
      IF( STATUS .NE. SAI__OK ) THEN
         VAL_BTOUB = VAL__BADUB
 
*  If the bad data flag is set, check if the argument given is bad.
*  Return VAL__BADUB if it is.
      ELSE IF( BAD .AND. ( ARG .EQ. VAL__BADB ) ) THEN
         VAL_BTOUB = VAL__BADUB
 
*  If the conversion can potentially fail, then test if the argument
*  value lies within its allowed bounds.  If not, then return the value
*  VAL__BADUB and set a STATUS value.
      ELSE IF( ( .TRUE. ) .AND.
     :         ( NUM_LTB( ARG, LO ) .OR. NUM_GTB( ARG, HI ) ) ) THEN
         VAL_BTOUB = VAL__BADUB
         STATUS = PRM__INTOF
 
*  Otherwise, perform data conversion.
      ELSE
         VAL_BTOUB = NUM_BTOUB( ARG )
      ENDIF
 
*  Exit routine.
      END

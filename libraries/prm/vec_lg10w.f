      SUBROUTINE VEC_LG10W( BAD, N, ARGV, RESV, IERR, NERR, STATUS )
*+
*  Name:
*     VEC_LG10W
 
*  Purpose:
*     Vectorised WORD common logarithm (base 10) function.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL VEC_LG10W( BAD, N, ARGV, RESV, IERR, NERR, STATUS )
 
*  Description:
*     The routine evaluates the common logarithm (base 10) function for a vectorised
*     array ARGV of WORD values.  If numerical errors occur, the
*     value VAL__BADW is returned in appropriate elements of the
*     result array RESV and a STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument values (ARGV) may be "bad".
*     N = INTEGER (Given)
*        The number of argument values to be processed.  If N is not
*        positive the routine returns with IERR and NERR set to zero,
*        but without processing any values.
*     ARGV( N ) = INTEGER*2 (Given)
*        A vectorised (1-dimensional) array containing the N WORD
*        argument values for the common logarithm (base 10) function.
*     RESV( N ) = INTEGER*2 (Returned)
*        A vectorised (1-dimensional) array with at least N elements to
*        receive the function results.  Each element I of RESV receives
*        the WORD value:
*
*           RESV( I ) = LOG10( ARGV( I ) )
*
*        for I = 1 to N.  The value VAL__BADW will be set in
*        appropriate elements of RESV under error conditions.
*     IERR = INTEGER (Returned)
*        The index of the first input array element to generate a
*        numerical error.  Zero is returned if no errors occur.
*     NERR = INTEGER (Returned)
*        A count of the number of numerical errors which occur.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns without action.  A STATUS value will be set by this
*        routine if any numerical errors occur.
 
*  Authors:
*     R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     15-AUG-1988 (RFWS):
*        Original version.
*     28-OCT-1991 (RFWS):
*        Added LIB$REVERT call.
*     7-NOV-1991 (RFWS):
*        Changed to use NUM_TRAP.
*     27-SEP-1995 (BKM):
*        Changed LIB$ESTABLISH and LIB$REVERT calls to NUM_HANDL and NUM_REVRT
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

      INCLUDE 'PRM_PAR'          ! PRM_ public constants

      INCLUDE 'PRM_CONST'        ! PRM_ private constants

      INCLUDE 'PRM_ERR'          ! PRM_ error codes

 
*  Arguments Given:
      LOGICAL BAD                ! Bad data flag
      INTEGER N                  ! Number of argument values to process
      INTEGER*2 ARGV( * )           ! Function argument array
 
*  Arguments Returned:
      INTEGER*2 RESV( * )           ! Function result array
      INTEGER IERR               ! Numerical error pointer
      INTEGER NERR               ! Numerical error count
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  External References:
      EXTERNAL NUM_TRAP          ! Error handling routine
 
*  Global Variables:
      INCLUDE 'NUM_CMN'          ! Define NUM_ERROR flag

 
*  Local Variables:
      INTEGER I                  ! Loop counter
      INTEGER*2 ARG                 ! Temporary argument variable
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_W'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_W'      ! Define NUM_ arithmetic functions

 
*.
 
*  Check status.
      IF( STATUS .NE. SAI__OK ) RETURN
 
*  If required, establish the error handler and initialise the common
*  block error flag.
      IF( .FALSE. ) THEN
         CALL NUM_HANDL( NUM_TRAP )
         NUM_ERROR = SAI__OK
      ENDIF
 
*  Initialise the numerical error pointer and the error count.
      IERR = 0
      NERR = 0
 
*  If the bad data flag is set:
*  ---------------------------
*  Loop to process each element of the input argument array in turn.
      IF( BAD ) THEN
         DO 1 I = 1, N
            ARG = ARGV( I )
 
*  Check if the argument value is bad.  If it is, then put a value of
*  VAL__BADW in the corresponding element of the result array.
            IF( ARG .EQ. VAL__BADW ) THEN
               RESV( I ) = VAL__BADW
 
*  Check if the argument value is acceptable.  If not, then put a value
*  of VAL__BADW in the corresponding element of the result array and
*  increment the numerical error count.
            ELSE IF( .NOT. ( NUM_GTW( ARG, VAL__ZW ) ) ) THEN
               RESV( I ) = VAL__BADW
               NERR = NERR + 1
 
*  Set a STATUS value (if not already set) and update the error
*  pointer.
               IF( STATUS .EQ. SAI__OK ) THEN
                  STATUS = PRM__LOGZN
                  IERR = I
               ENDIF
 
*  If the argument value is acceptable, then evaluate the common logarithm (base 10)
*  function.
            ELSE
               RESV( I ) = NUM_LG10W( ARG )
 
*  If an error handler is established, check if the numerical error
*  flag is set.  If so, put a value of VAL__BADW in the corresponding
*  element of the result array and increment the error count.
               IF( .FALSE. ) THEN
                  IF( NUM_ERROR .NE. SAI__OK ) THEN
                     RESV( I ) = VAL__BADW
                     NERR = NERR + 1
 
*  Set a STATUS value (if not already set) and update the error
*  pointer.
                     IF( STATUS .EQ. SAI__OK ) THEN
                        STATUS = NUM_ERROR
                        IERR = I
                     ENDIF
 
*  Clear the error flag.
                     NUM_ERROR = SAI__OK
                  ENDIF
               ENDIF
            ENDIF
 1       CONTINUE
 
*  If the bad data flag is not set:
*  -------------------------------
*  Loop to process each element of the input argument array in turn.
      ELSE
         DO 2 I = 1, N
            ARG = ARGV( I )
 
*  Check if the argument value is acceptable.  If not, then put a value
*  of VAL__BADW in the corresponding element of the result array and
*  increment the error count.
            IF( .NOT. ( NUM_GTW( ARG, VAL__ZW ) ) ) THEN
               RESV( I ) = VAL__BADW
               NERR = NERR + 1
 
*  Set a STATUS value (if not already set) and update the error
*  pointer.
               IF( STATUS .EQ. SAI__OK ) THEN
                  STATUS = PRM__LOGZN
                  IERR = I
               ENDIF
 
*  If the argument value is acceptable, then evaluate the common logarithm (base 10)
*  function.
            ELSE
               RESV( I ) = NUM_LG10W( ARG )
 
*  If an error handler is established, check if the numerical error
*  flag is set.  If so, put a value of VAL__BADW in the corresponding
*  element of the result array and increment the error count.
               IF( .FALSE. ) THEN
                  IF( NUM_ERROR .NE. SAI__OK ) THEN
                     RESV( I ) = VAL__BADW
                     NERR = NERR + 1
 
*  Set a STATUS value (if not already set) and update the error
*  pointer.
                     IF( STATUS .EQ. SAI__OK ) THEN
                        STATUS = NUM_ERROR
                        IERR = I
                     ENDIF
 
*  Clear the error flag.
                     NUM_ERROR = SAI__OK
                  ENDIF
               ENDIF
            ENDIF
 2       CONTINUE
      ENDIF
 
*  If required, remove the error handler.
      IF( .FALSE. ) THEN
         CALL NUM_REVRT
      ENDIF
 
*  Exit routine.
      END

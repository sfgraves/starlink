      SUBROUTINE VEC_SIGNUW( BAD, N, ARGV1, ARGV2, RESV, IERR, NERR,
     :                          STATUS )
*+
*  Name:
*     VEC_SIGNUW
 
*  Purpose:
*     Vectorised UNSIGNED WORD Fortran SIGN (sign transfer) function.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL VEC_SIGNUW( BAD, N, ARGV1, ARGV2, RESV, IERR, NERR,
*                         STATUS )
 
*  Description:
*     The routine evaluates the Fortran SIGN (sign transfer) function for two vectorised
*     arrays ARGV1 and ARGV2 of UNSIGNED WORD argument values.  If numerical
*     errors occur, the value VAL__BADUW is returned in appropriate
*     elements of the result array RESV and a STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument values (ARGV1 & ARGV2) may be "bad".
*     N = INTEGER (Given)
*        The number of argument pairs to be processed.  If N is not
*        positive the routine returns with IERR and NERR set to zero,
*        but without processing any values.
*     ARGV1( N ), ARGV2( N ) = INTEGER*2 (Given)
*        Two vectorised (1-dimensional) arrays containing the N pairs
*        of UNSIGNED WORD argument values for the Fortran SIGN (sign transfer) function.
*     RESV( N ) = INTEGER*2 (Returned)
*        A vectorised (1-dimensional) array with at least N elements to
*        receive the function results.  Each element I of RESV receives
*        the UNSIGNED WORD value:
*
*           RESV( I ) = SIGN( ARGV1( I ), ARGV2( I ) )
*
 
*        for I = 1 to N.  The value VAL__BADUW will be set in
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
      INTEGER N                  ! Number of elements to process
      INTEGER*2 ARGV1( * )          ! First function argument array
      INTEGER*2 ARGV2( * )          ! Second function argument array
 
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
      INTEGER*2 ARG1                ! Temporary variable for argument 1
      INTEGER*2 ARG2                ! Temporary variable for argument 2
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_UW'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_UW'      ! Define NUM_ arithmetic functions

 
*.
 
*  Check status.
      IF( STATUS .NE. SAI__OK ) RETURN
 
*  If required, establish the numerical error handler and initialise
*  the common block error flag.
      IF( .FALSE. ) THEN
         CALL NUM_HANDL( NUM_TRAP )
         NUM_ERROR = SAI__OK
      ENDIF
 
*  Initialise the numerical error pointer and the error count.
      IERR = 0
      NERR = 0
 
*  If the bad data flag is set:
*  ---------------------------
*  Loop to process each pair of elements from the input argument arrays
*  in turn.
      IF( BAD ) THEN
         DO 1 I = 1, N
            ARG1 = ARGV1( I )
            ARG2 = ARGV2( I )
 
*  Check if the argument values are bad.  If either is, then put a
*  value of VAL__BADUW in the corresponding element of the result
*  array.
            IF( ARG1 .EQ. VAL__BADUW .OR.
     :          ARG2 .EQ. VAL__BADUW ) THEN
               RESV( I ) = VAL__BADUW
 
*  Check if the argument values are acceptable.  If not, then put a
*  value of VAL__BADUW in the corresponding element of the result
*  array and increment the error count.
            ELSE IF( .NOT. ( .TRUE. ) ) THEN
               RESV( I ) = VAL__BADUW
               NERR = NERR + 1
 
*  Set a STATUS value (if not already set) and update the error
*  pointer.
               IF( STATUS .EQ. SAI__OK ) THEN
                  STATUS = SAI__OK
                  IERR = I
               ENDIF
 
*  If the argument values are acceptable, then evaluate the Fortran SIGN (sign transfer)
*  function.
            ELSE
               RESV( I ) = NUM_SIGNUW( ARG1, ARG2 )
 
*  If an error handler is established, check if the numerical error
*  flag is set.  If so, put a value of VAL__BADUW in the corresponding
*  element of the result array and increment the error count.
               IF( .FALSE. ) THEN
                  IF( NUM_ERROR .NE. SAI__OK ) THEN
                     RESV( I ) = VAL__BADUW
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
*  Loop to process each pair of elements from the input argument arrays
*  in turn.
      ELSE
         DO 2 I = 1, N
            ARG1 = ARGV1( I )
            ARG2 = ARGV2( I )
 
*  Check if the argument values are acceptable.  If not, then put a
*  value of VAL__BADUW in the corresponding element of the result
*  array and increment the error count.
            IF( .NOT. ( .TRUE. ) ) THEN
               RESV( I ) = VAL__BADUW
               NERR = NERR + 1
 
*  Set a STATUS value (if not already set) and update the error
*  pointer.
               IF( STATUS .EQ. SAI__OK ) THEN
                  STATUS = SAI__OK
                  IERR = I
               ENDIF
 
*  If the argument values are acceptable, then evaluate the Fortran SIGN (sign transfer)
*  function.
            ELSE
               RESV( I ) = NUM_SIGNUW( ARG1, ARG2 )
 
*  If an error handler is established, check if the numerical error
*  flag is set.  If so, put a value of VAL__BADUW in the corresponding
*  element of the result array and increment the error count.
               IF( .FALSE. ) THEN
                  IF( NUM_ERROR .NE. SAI__OK ) THEN
                     RESV( I ) = VAL__BADUW
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

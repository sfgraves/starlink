      SUBROUTINE BDI1_SETLNK( NARG, ARGS, OARG, STATUS )
*+
*  Name:
*     BDI1_SETLNK

*  Purpose:
*     Service SetLink method for various class to HDSfile links

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL BDI1_SETLNK( NARG, ARGS, OARG, STATUS )

*  Description:
*     Establishes ADI file link between high level objects Scalar, Array
*     and BinDS and the HDSfile.

*  Arguments:
*     NARG = INTEGER (given)
*        Number of method arguments
*     ARGS(*) = INTEGER (given)
*        ADI identifier of method arguments
*     OARG = INTEGER (returned)
*        Output data
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     BDI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/bdi.html

*  Keywords:
*     package:bdi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     9 Aug 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ADI_PAR'
      INCLUDE 'DAT_PAR'

*  Arguments Given:
      INTEGER                   NARG, ARGS(*)

*  Arguments Returned:
      INTEGER                   OARG

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      CHARACTER*(DAT__SZLOC)	ALOC			! Locator array in file
      CHARACTER*(DAT__SZLOC)	LOC			! Locator to file
      CHARACTER*(DAT__SZTYP)	TYP			! Top level type

      INTEGER			DIMS(DAT__MXDIM)	! Dimensions
      INTEGER			MDID			! Model data object
      INTEGER			NDIM			! Dimensionality

      LOGICAL			PRIM			! Is object primitive?
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Default return value
      OARG = ADI__NULLID
      MDID = ARGS(1)

*  Extract locator from HDSfile
      CALL ADI1_GETLOC( ARGS(2), LOC, STATUS )

*  Is object primitive?
      CALL DAT_PRIM( LOC, PRIM, STATUS )

*  Get object type
      CALL DAT_TYPE( LOC, TYP, STATUS )

*  If primitive...
      IF ( PRIM ) THEN

*    Get dimensions
        CALL DAT_SHAPE( LOC, DAT__MXDIM, DIMS, NDIM, STATUS )

*    Write dimensions to high level object
        IF ( NDIM .GT. 0 ) THEN
          CALL ADI_NEW0( 'Array', MDID, STATUS )
          CALL BDI_SETSHP( MDID, NDIM, DIMS, STATUS )
        ELSE
          CALL ADI_NEW0( 'Scalar', MDID, STATUS )
        END IF
        OARG = MDID

*    Store that too, without leading underscore. Trap _CHAR*xx types as
*    ADI doesn't store string lengths that way
        IF ( TYP .EQ. '_CHAR' ) THEN
          CALL BDI_SETTYP( MDID, 'CHAR', STATUS )
        ELSE
          CALL BDI_SETTYP( MDID, TYP(2:), STATUS )
        END IF

*  Structured data
      ELSE

*    If the type is ARRAY the we have an object that we can use to derive
*    dimensions and the basic type
        IF ( TYP(1:5) .EQ. 'ARRAY' ) THEN

*      Create return model object
          CALL ADI_NEW0( 'Array', MDID, STATUS )
          OARG = MDID

*      Clone locator so we can annul below
          CALL DAT_CLONE( LOC, ALOC, STATUS )

*    Otherwise we must search for a component which can supply the
*    relevant information
        ELSE

*      Store the type as the dataset type
          CALL ADI_CPUT0C( MDID, 'DatasetType', TYP, STATUS )

*      The best chance the primary data array
          CALL BDI1_CFIND( MDID, ARGS(2), 'Data', .FALSE.,
     :                     ALOC, NDIM, DIMS, STATUS )
          IF ( STATUS .NE. SAI__OK ) THEN
            CALL ERR_REP( 'BDI1_SETLNK', 'Unable to find primary '/
     :                             /'data array in input', STATUS )
          END IF

        END IF

*    If all is well...
        IF ( STATUS .EQ. SAI__OK ) THEN

*      Get dimensions and type from this object
          CALL ADI1_ARYSHP( ALOC, DAT__MXDIM, DIMS, NDIM, TYP, STATUS )

*      Free the object
          CALL DAT_ANNUL( ALOC, STATUS )

*      Store the info
          CALL BDI_SETSHP( MDID, NDIM, DIMS, STATUS )
          CALL BDI_SETTYP( MDID, TYP(2:), STATUS )

        END IF

      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'BDI1_SETLNK', STATUS )

*  Invoke base method to perform linkage
      CALL ADI_SETLNK( MDID, ARGS(2), STATUS )

      END

      SUBROUTINE SPD_EAEG( NDF, XLOC, TYPE, LABEL, UNITS,
     :   PNTR, ONDF, NELM, STATUS )
*+
*  Name:
*     SPD_EAEG

*  Purpose:
*     Read-access non-existing spectroscopic values.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SPD_EAEG( NDF, XLOC, TYPE, LABEL, UNITS,
*        PNTR, ONDF, NELM, STATUS )

*  Description:
*     This routine creates and accesses a temporary SPECVALS NDF as it
*     would be accessed in the Specdre Extension. The spectroscopic
*     values will be the default values. For this routine it does not
*     matter if the Extension exists or not, or if the SPECVALS
*     structure exists or not. The only information needed from the
*     Extension is the number of the spectrocopic axis.

*  Arguments:
*     NDF = INTEGER (Given)
*        The identifier of the given main NDF.
*     XLOC = CHARACTER * ( * ) (Given)
*        The HDS locator of the Specdre Extension. This should be an
*        extension of the main NDF. If the Specdre Extension does not
*        exist, then this argument must be given as DAT__NOLOC.
*     TYPE = CHARACTER * ( * ) (Given)
*        The numeric type for creating the temporary NDF. This can be
*        '_REAL' or '_DOUBLE'.
*     LABEL = CHARACTER * ( * ) (Returned)
*        The Extension NDF's data component label.
*     UNITS = CHARACTER * ( * ) (Returned)
*        The Extension NDF's data component unit.
*     PNTR = INTEGER (Returned)
*        The pointer to which the centre array is mapped.
*     ONDF = INTEGER (Returned)
*        The identifier of the temporary NDF.
*     NELM = INTEGER (Returned)
*        The number of elements in the mapped array.
*     STATUS = INTEGER (Given and Returned)
*        The global status. This is set if the requested data type is
*        invalid.

*  Notes:
*     This routine recognises Specdre Extension v. 0.7.

*  Authors:
*     hme: Horst Meyerdierks (UoE, Starlink)
*     {enter_new_authors_here}

*  History:
*     14 Jun 1992 (hme):
*        Original version.
*     24 Feb 1994 (hme):
*        Make it an SPD_E* routine, and use internal routine to grow.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! Standard DAT constants
      INCLUDE 'NDF_PAR'          ! Standard NDF constants

*  Arguments Given:
      INTEGER NDF
      CHARACTER * ( * ) XLOC
      CHARACTER * ( * ) TYPE

*  Arguments Returned:
      CHARACTER * ( * ) LABEL
      CHARACTER * ( * ) UNITS
      INTEGER PNTR
      INTEGER ONDF
      INTEGER NELM

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER SPAXIS             ! The spectroscopic axis
      INTEGER INDAT              ! Pointer to grow source data
      INTEGER PLACE              ! NDF placeholder
      INTEGER NDIM               ! Number of axes of NDF
      INTEGER LBND( NDF__MXDIM ) ! Lower bounds of NDF
      INTEGER UBND( NDF__MXDIM ) ! Upper bounds of NDF
      INTEGER INELM              ! Size of grow source
      INTEGER ODIM( NDF__MXDIM ) ! Dimensions of grow target

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check that requested type is valid.
      IF ( TYPE .NE. '_DOUBLE' .AND. TYPE .NE. '_REAL' ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'SPE_INVTYP',
     :      'SPD_EAEG: Error creating spectroscopic values. ' //
     :      'Requested data type is invalid.', STATUS )
         GO TO 500
      END IF

*  Find the main NDF bounds.
      CALL NDF_BOUND( NDF, NDF__MXDIM, LBND, UBND, NDIM, STATUS )

*  Create the temporary NDF.
      CALL NDF_TEMP( PLACE, STATUS )
      CALL NDF_NEW( TYPE, NDIM, LBND, UBND, PLACE, ONDF, STATUS )

*  Get spectroscopic axis number.
*  Get the label and unit from the spectroscopic axis of the
*  main NDF.
      CALL SPD_EABA( NDF, (XLOC.NE.DAT__NOLOC), SPAXIS, STATUS )
      LABEL = 'unknown'
      UNITS = 'unknown'
      CALL NDF_ACGET( NDF, 'LABEL', SPAXIS, LABEL, STATUS )
      CALL NDF_ACGET( NDF, 'UNITS', SPAXIS, UNITS, STATUS )

*  The default data are copied from the spectroscopic axis of the main
*  NDF. That 1-D array is grown to fill the whole N-D array.
*  Get/initialise the dimensions of the target and source data.
      CALL NDF_DIM( ONDF, NDF__MXDIM, ODIM, NDIM, STATUS )

*  Map the target data.
      CALL NDF_MAP( ONDF, 'DATA', TYPE, 'WRITE', PNTR, NELM, STATUS )

*  Map the source data. If they do not exist, NDF will provide a decent
*  default. NDF will also do the type conversion for us. Note that the
*  relevant dimension of the source data is updated here.
      CALL NDF_AMAP( NDF, 'CENTRE', SPAXIS, TYPE, 'READ', INDAT,
     :   INELM, STATUS )

*  Now grow from the source to the target, filling the target.
      IF ( TYPE .EQ. '_DOUBLE' ) THEN
         CALL SPD_EBAAD( NDF__MXDIM, SPAXIS, ODIM, INELM, NELM,
     :      %VAL(INDAT), %VAL(PNTR), STATUS )
      ELSE
         CALL SPD_EBAAR( NDF__MXDIM, SPAXIS, ODIM, INELM, NELM,
     :      %VAL(INDAT), %VAL(PNTR), STATUS )
      END IF

*  Unmap the source data.
      CALL NDF_AUNMP( NDF, 'CENTRE', SPAXIS, STATUS )

*  Tidy up.
 500  CONTINUE
      IF ( STATUS .NE. SAI__OK ) CALL NDF_ANNUL( ONDF, STATUS )

*  Return.
      END

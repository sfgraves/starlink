      SUBROUTINE KPG1_CHAXD( INDF, NDIM, DIM, DATAVL, SCALE, OFFSET,
     :                         STATUS )
*+
*  Name:
*     KPG1_CHAXx
 
*  Purpose:
*     Check for usable AXIS structures.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_CHAXx( INDF, NDIM, DIM, DATAVL, SCALE, OFFSET, STATUS )
 
*  Description:
*     This routine looks for monotonic AXIS structures within the
*     specified axes of the supplied NDF.  If all axes have such AXIS
*     structures, then a flag (DATAVL) is returned .TRUE..  If any axis
*     is non-monotonic, a warning message is issued, DATAVL is returned
*     .FALSE., and a scale of 1.0 and offset of 0.0 are returned.
*
*     Each axis is then checked for linearity.  If the axis is linear,
*     then the corresponding scale and offset of the linear mapping from
*     pixel to data co-ordinates are returned.  Otherwise a warning
*     message is issued and the returned scale and offset refer to a
*     linear approximation to the axis co-ordinate system.
 
*  Arguments:
*     INDF = INTEGER (Given)
*        An identifier for the NDF.
*     NDIM = INTEGER (Given)
*        The number of axes.
*     DIM( NDIM ) = INTEGER (Given)
*        The indices of the axes to be checked, in increasing order.
*     DATAVL = LOGICAL (Returned)
*        Returned .TRUE. if the NDF contains monotonic AXIS structures
*        for all requested axes.  Returned .FALSE. otherwise.
*     SCALE( NDIM ) = ? (Returned)
*        The scale factors in the linear relationships between axis
*        co-ordinates and pixel co-ordinates.  Returned equal to 1.0 if
*        DATVAL is returned .FALSE..
*     OFFSET( NDIM ) = ? (Returned)
*        The offsets in the linear relationships between axis
*        co-ordinates and pixel co-ordinates.  Returned equal to 0.0 if
*        DATVAL is returned .FALSE..
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for each of the real and double-precision
*     data types: replace "x" in the routine name by D or R as
*     appropriate.  The SCALE and OFFSET arrays supplied to the routine
*     must have the data type specified.
*     -  The returned values of SCALE and OFFSET are such that:
*
*        DATA = SCALE( I ) * PIXEL + OFFSET( I )
*
*     where PIXEL is a pixel co-ordinate for the I'th dimension listed
*     in array DIM (i.e. dimension DIM( I ) ), and DATA is the
*     corresponding axis co-ordinate.
 
*  Authors:
*     DSB: David Berry (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     PWD: Peter W. Draper (Starlink, Durham University)
*     {enter_new_authors_here}
 
*  History:
*     4-OCT-1993 (DSB):
*        Original version based on MJC's application (top-level) code.
*     1995 April 11 (MJC):
*        Made generic and n-dimensional.  Corrected evaluation of
*        scale and offset for approximation to linear data co-ordinates.
*        Used modern-style variable declarations.  Fixed typo's.
*     2004 September 1 (TIMJ):
*        Use CNF_PVAL
*     2004 September 30 (PWD):
*        Move CNF_PVAL into declaration section.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF_ constants
      INCLUDE 'CNF_PAR'          ! CNF functions
 
*  Arguments Given:
      INTEGER INDF
      INTEGER NDIM
      INTEGER DIM( NDIM )
 
*  Arguments Returned:
      LOGICAL DATAVL
      DOUBLE PRECISION SCALE( NDIM )
      DOUBLE PRECISION OFFSET( NDIM )
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER AEL                ! No. of elements in mapped axis array
      INTEGER APNTR              ! Pointer to mapped axis array
      INTEGER AXIS               ! Index of current dimension
      DOUBLE PRECISION DALBND( NDF__MXDIM ) ! AXIS lower bounds
      DOUBLE PRECISION DAUBND( NDF__MXDIM ) ! AXIS upper bounds
      INTEGER I                  ! Dimension counter
      INTEGER IDIM               ! Total number of dimensions
      INTEGER LBND( NDF__MXDIM ) ! Lower bounds of the NDF
      LOGICAL MONOTO             ! Is the current axis monotonic?
      INTEGER UBND( NDF__MXDIM ) ! Upper bounds of the NDF
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  See if there is an axis co-ordinate system defined within the NDF.
      CALL NDF_STATE( INDF, 'Axis', DATAVL, STATUS )
 
*  Axis co-ordinate systems can only be used if they are monotonic.
*  Check each requested axis for monotonacity.
      IF ( DATAVL ) THEN
         DO  I = 1, NDIM
            AXIS = DIM( I )
 
*  Map the axis centre values for this dimension as an array of _DOUBLE
*  values.
            CALL NDF_AMAP( INDF, 'Centre', AXIS, '_DOUBLE', 'READ',
     :                     APNTR, AEL, STATUS )
            IF ( STATUS .EQ. SAI__OK ) THEN
 
*  Start a new error context so that any error reports concerning a
*  non-monotonic axis may be annulled.  Instead a warning message will
*  be issued so that the application can continue using world
*  co-ordinates.
               CALL ERR_MARK
               CALL KPG1_MONOD( .TRUE., AEL, %VAL( CNF_PVAL( APNTR ) ), 
     :                          MONOTO,
     :                           STATUS )
 
               IF ( STATUS .NE. SAI__OK ) THEN
                  CALL ERR_ANNUL( STATUS )
                  MONOTO = .FALSE.
               END IF
 
               CALL ERR_RLSE
 
*  Issue a warning message.
               IF ( .NOT. MONOTO ) THEN
                  CALL MSG_SETI( 'AX', AXIS )
                  CALL NDF_MSG( 'NDF', INDF )
                  CALL MSG_OUT( 'KPG1_CHAXx_NOTMONO', 'Axis ^AX of '/
     :              /'^NDF is not monotonic and therefore cannot be '/
     :              /'used for annotation or stored in the graphics '/
     :              /'database.', STATUS )
 
*  Flag that the axis co-ordinates cannot be used.
                  DATAVL = .FALSE.
 
               END IF
 
            END IF
 
*  Unmap the axis centre array.
            CALL NDF_AUNMP( INDF, 'Centre', AXIS, STATUS )
 
         END DO
 
      END IF
 
*  If we still have usable data co-ordinates, check that they are
*  linear.  The linear transformation giving data co-ordinates in terms
*  of world co-ordinates is returned if both axes are linear.  Warning
*  messages are issued for each non-linear axis.
      IF ( DATAVL ) THEN
         CALL KPG1_DCLID( NDIM, INDF, DALBND, DAUBND, SCALE, OFFSET,
     :                     DATAVL, STATUS )
 
*  Force the axes to be considered linear.  The returned values of
*  SCALE and OFFSET will describe a linear approximation to the AXIS
*  values.  Note that KPG1_DCLIx returns the bounds at the outer edge
*  and not the centres, hence the +1 and lack of half-pixel offset
*  in the transformation from world to data co-ordinates derived below.
         IF ( .NOT. DATAVL ) THEN
            DATAVL = .TRUE.
            CALL NDF_BOUND( INDF, NDF__MXDIM, LBND, UBND, IDIM, STATUS )
 
            DO I = 1, NDIM
               AXIS = DIM( I )
               SCALE( I ) = ( DAUBND( I ) - DALBND( I ) ) / NUM_ITOD
     :                      ( UBND( AXIS ) - LBND( AXIS ) + 1 )
               OFFSET( I ) = DAUBND( I ) - SCALE( I ) *
     :                       NUM_ITOD( UBND( AXIS ) )
            END DO
 
         END IF
 
      END IF
 
*  If no usable data co-ordinates are available, return a unit
*  tranformation.
      IF ( .NOT. DATAVL ) THEN
 
         DO I = 1, NDIM
            SCALE( I ) = 1.0D0
            OFFSET( I ) = 0.0D0
         END DO
 
      END IF
 
      END

      SUBROUTINE WCSEDIT( STATUS )
*+
*  Name:
*     WCSEDIT

*  Purpose:
*     Modifies WCS components of a set of NDFs.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL WCSEDIT( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This task performs a set of miscellaneous modifications to the
*     WCS (World Coordinate System) components of a list of NDFs.
*     According to the MODE parameter it can:
*        -  Set the Current frame
*        -  Add a new frame
*        -  Remove a frame
*
*     The routine does not fail if some of the requested edits cannot
*     be performed, but an output parameter MODIFIED records which 
*     NDFs were successfully modified.
*
*     If a new frame is added it becomes the Current frame.  If a frame
*     is removed, the Current frame is not changed (unless the Current
*     frame itself is removed).

*  Usage:
*     WCSEDIT in mode frame

*  ADAM Parameters:
*     COEFFS( * ) = _DOUBLE (Read)
*        If MODE is ADD, this parameter is a list of the coefficients 
*        used for the mapping from the basis frame to the new frame.
*        Its meaning and the number of values required depend on the 
*        value of MAPTYPE:
*           -  UNIT       -- No values are required
*                X' = X
*                Y' = Y
*           -  LINEAR     -- Six values C1-C6 are required:
*                X' = C1 + C2 * X + C3 * Y
*                Y' = C4 + C5 * X + C6 * Y
*           -  PINCUSHION -- Three values C1-C3 are required:
*                X' = X * ( 1 + C1 * ( (X - C2)**2 + (Y - C3)**2 ) )
*                Y' = Y * ( 1 + C1 * ( (X - C2)**2 + (Y - C3)**2 ) )
*     DOMAIN = LITERAL (Read)
*        If MODE is ADD this gives the domain name to be used for the
*        new frame.  Spaces in the name are ignored and letters are
*        folded to upper case.  If the new frame is successfully added
*        and any frame with the same domain name already exists, it
*        will be removed, and a message will be printed to that effect.
*     EPOCH = _DOUBLE (Read)
*        If a "Sky Co-ordinate System" specification is supplied (using
*        parameter BASEFRAME) for a celestial co-ordinate system, then
*        an epoch value is needed to qualify it. This is the epoch at
*        which the supplied sky positions were determined. It should be
*        given as a decimal years value, with or without decimal places
*        ("1996.8" for example). Such values are interpreted as a
*        Besselian epoch if less than 1984.0 and as a Julian epoch
*        otherwise.
*     FRAME = LITERAL (Read)
*        This parameter specifies the 'basis frame', which has the
*        following meaning according to the value of the MODE parameter:
*           -  MODE = CURRENT -- The frame to be made Current
*           -  MODE = REMOVE  -- The frame to remove; if it is a domain
*                                name (see below) then all frames with
*                                that domain will be removed.
*           -  MODE = ADD     -- The new frame will be a copy of the 
*                                basis frame, and will be mapped from it
*                                using the mapping given.
*
*        The value of this parameter can be one of the following:
*           -  A domain name such as SKY, AXIS, PIXEL, etc.
*           -  An integer value giving the index of the required Frame
*              within the WCS component.
*           -  A "Sky Co-ordinate System" (SCS) value such as EQUAT(J2000)
*              (see section "Sky Co-ordinate Systems" in SUN/95).
*        A domain name is usually the most suitable choice.
*     IN = LITERAL (Read)
*        A list specifying the names of the NDFs whose WCS components
*        are to be modified.  The NDF names should be separated by 
*        commas and may include wildcards.
*     LOGFILE = FILENAME (Read)
*        Name of the CCDPACK logfile.  If a null (!) value is given for
*        this parameter then no logfile will be written, regardless of
*        the value of the LOGTO parameter.
*
*        If the logging system has been initialised using CCDSETUP
*        then the value specified there will be used. Otherwise, the
*        default is "CCDPACK.LOG".
*        [CCDPACK.LOG]
*     LOGTO = LITERAL (Read)
*        Every CCDPACK application has the ability to log its output
*        for future reference as well as for display on the terminal.
*        This parameter controls this process, and may be set to any
*        unique abbreviation of the following:
*           -  TERMINAL  -- Send output to the terminal only
*           -  LOGFILE   -- Send output to the logfile only (see the
*                           LOGFILE parameter)
*           -  BOTH      -- Send output to both the terminal and the
*                           logfile
*           -  NEITHER   -- Produce no output at all
*
*        If the logging system has been initialised using CCDSETUP
*        then the value specified there will be used. Otherwise, the
*        default is "BOTH".
*        [BOTH]
*     MAPTYPE = LITERAL (Read)
*        This parameter is required when MODE is ADD, and specifies the
*        type of mapping which connects the basis frame to the new frame.
*        It may take one of the following values:
*           -  UNIT
*           -  LINEAR
*           -  PINCUSHION
*        [UNIT]
*     MODE = LITERAL (Read)
*        The action to be performed.  It may take one of the following
*        values:
*           -  ADD      -- Add a new frame (which becomes Current)
*           -  CURRENT  -- Set the Current frame
*           -  REMOVE   -- Remove a frame
*        [CURRENT]
*     MODIFIED = LITERAL (Write)
*        On exit, this parameter gives a comma-separated list of all the
*        NDFs which were successfully modified.  In particular, if MODE
*        is CURRENT, this list will include all the NDFs which contained
*        the specified frame, but exclude any which did not.

*  Examples:
*     wcsedit * current ccd_reg
*        This sets the current frame of all the NDFs in the current
*        directory to the 'CCD_REG' domain.  The MODIFY parameter is 
*        set on output to contain the names of all those NDFs which
*        had such a frame.
*
*     wcsedit data* remove frame=4
*        The fourth frame in the WCS component of each NDF 'data*.sdf' 
*        is removed.
*
*     wcsedit "first,second" mode=add frame=GRID maptype=pcd 
*             coeffs=[-6.8e-10,0,0] domain=NEW
*        A new frame, in the domain 'NEW', is added to the NDFs first 
*        and second.  It is connected to the previously existing GRID
*        domain by a pincushion distortion mapping centred at the 
*        origin with a distortion coefficient of -6.8e-10.  If any 
*        frames with domain NEW already exist in those NDFs they are
*        removed.

*  Notes:
*     This routine provides similar functionality to that provided by
*     KAPPA applications WCSADD, WCSREMOVE and WCSFRAME, but allows 
*     use of CCDPACK-style NDF lists.

*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils

*  Authors:
*     MBT: Mark Taylor  (STARLINK)
*     {enter_new_authors_here}

*  History:
*     18-MAY-1999 (MBT):
*        Original version.
*     {enter_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! Standard AST constants
      INCLUDE 'IRH_PAR'          ! Standard IRH constants

*  Status:
      INTEGER STATUS             ! Global status

*  External references:
      INTEGER CHR_LEN
      EXTERNAL CHR_LEN           ! Used length of string

*  Local Constants:
      INTEGER MXMDLN             ! Maximum length of MODIFIED string
      PARAMETER( MXMDLN = 2048 ) ! Should be long enough

*  Local Variables:
      CHARACTER * ( 16 ) MAPTYP  ! Type of mapping to use
      CHARACTER * ( 16 ) MODE    ! Action to perform
      CHARACTER * ( IRH__SZNAM ) NAME ! Name of NDF
      CHARACTER * ( AST__SZCHR ) DMBASI ! Domain of basis frame
      CHARACTER * ( AST__SZCHR ) DMRMV ! Domain to remove
      CHARACTER * ( AST__SZCHR ) DOMAIN ! Domain of new frame
      CHARACTER * ( AST__SZCHR ) FRAME ! Basis frame as specified
      CHARACTER * ( MXMDLN ) MODIF ! List of modified NDFs
      DOUBLE PRECISION COEFFS( 6 ) ! Coefficients of mapping
      INTEGER FRBASI             ! AST pointer to basis frame
      INTEGER FRNEW              ! AST pointer to new frame
      INTEGER I                  ! Loop variable
      INTEGER INDF               ! NDF identifier
      INTEGER INGRP              ! IRG identifier for NDF group
      INTEGER IWCS               ! AST pointer to WCS component
      INTEGER JBASIS             ! Index of basis frame
      INTEGER JCUR               ! Index of Current frame in unedited WCS comp
      INTEGER JNEW               ! Index of new frame in WCS component
      INTEGER MAP                ! AST pointer to mapping
      INTEGER NFRAME             ! Number of frames in unedited WCS component
      INTEGER NNDF               ! Number of NDFs
      LOGICAL SUCCES             ! Whether WCS has been successfully modified

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Start up the CCDPACK logging system.
      CALL CCD1_START( 'WCSEDIT', STATUS )

*  Begin AST context.
      CALL AST_BEGIN( STATUS )

*  Begin NDF context.
      CALL NDF_BEGIN

*  Get group of NDFs to operate on.
      CALL CCD1_NDFGR( 'IN', 'UPDATE', INGRP, NNDF, STATUS )

*  Get mode.
      CALL PAR_CHOIC( 'MODE', 'CURRENT', 'CURRENT,ADD,REMOVE', .FALSE.,
     :                MODE, STATUS )

*  Get frame specification.
      CALL PAR_GET0C( 'FRAME', FRAME, STATUS )

*  Get ready to loop over NDFs.
      MODIF = ' '
      IF ( STATUS .NE. SAI__OK ) GO TO 99

*  Loop over NDFs.
      DO 1 I = 1, NNDF

*  Get NDF and WCS component.
         CALL IRG_NDFEX( INGRP, I, INDF, STATUS )
         CALL CCD1_GTWCS( INDF, IWCS, STATUS )

*  Log to user.
         CALL IRH_GET( INGRP, I, 1, NAME, STATUS )
         CALL CCD1_MSG( ' ', ' ', STATUS )
         CALL MSG_SETC( 'NDF', NAME )
         CALL CCD1_MSG( ' ', '^NDF:', STATUS )

*  Store some facts about the initial state of the WCS component.
         NFRAME = AST_GETI( IWCS, 'Nframe', STATUS )
         JCUR = AST_GETI( IWCS, 'Current', STATUS )
         SUCCES = .FALSE.

*  Get the index of the Basis frame, that is the one specified by the
*  FRAME (and possibly EPOCH) parameter, without disturbing the Current
*  frame.
         IF ( STATUS .NE. SAI__OK ) GO TO 99
         CALL KPG1_ASFRM( 'FRAME', 'EPOCH', IWCS, ' ', ' ', .FALSE.,
     :                    STATUS )
         JBASIS = AST_GETI( IWCS, 'Current', STATUS )
         DMBASI = AST_GETC( IWCS, 'Domain', STATUS )
         CALL AST_SETI( IWCS, 'Current', JCUR, STATUS )
         IF ( STATUS .NE. SAI__OK ) THEN
            SUCCES = .FALSE.
            CALL ERR_ANNUL( STATUS )
            CALL MSG_SETC( 'FRM', FRAME )
            CALL CCD1_MSG( ' ', '      Basis frame ''^FRM'' not found',
     :                     STATUS )

*  The requested frame exists.  Now we act according to MODE type.
         ELSE

*  Set Current frame.
            IF ( MODE .EQ. 'CURRENT' ) THEN
               CALL AST_SETI( IWCS, 'Current', JBASIS, STATUS )
               CALL MSG_SETC( 'DOM', DMBASI )
               CALL CCD1_MSG( ' ', 
     :                        '      Current frame set to domain ^DOM',
     :                        STATUS )
               SUCCES = .TRUE.

*  Remove a frame.
            ELSE IF ( MODE .EQ. 'REMOVE' ) THEN

*  Method depends slightly on how it was specified - if a domain was given
*  we want to remove all frames with that domain value, otherwise we can
*  just remove the single frame specified.
*  First try to remove it as a domain name.  This leaves the Current 
*  frame intact where possible.
               CALL PAR_GET0C( 'FRAME', DMRMV, STATUS )
               CALL CCD1_DMPRG( IWCS, DMRMV, 0, STATUS )

*  If this has reduced the number of frames then it has succeeded.
               IF ( AST_GETI( IWCS, 'Nframe', STATUS ) .LT. NFRAME ) 
     :         THEN
                  SUCCES = .TRUE.
               ELSE

*  Otherwise we can just remove the basis frame.
                  CALL AST_REMOVEFRAME( IWCS, JBASIS, STATUS )
                  CALL MSG_SETC( 'DOM', DMBASI )
                  CALL CCD1_MSG( ' ', 
     :                           '      Removed frame in domain ^DOM',
     :                           STATUS )
                  SUCCES = .TRUE.
               END IF

*  Add a frame.
            ELSE IF ( MODE .EQ. 'ADD' ) THEN

*  Get additional required parameters.
               CALL PAR_CHOIC( 'MAPTYPE', 'UNIT', 
     :                         'UNIT,LINEAR,PINCUSHION', .FALSE., 
     :                         MAPTYP, STATUS )
               CALL PAR_GET0C( 'DOMAIN', DOMAIN, STATUS )
               CALL CHR_RMBLK( DOMAIN )
               CALL CHR_UCASE( DOMAIN )

*  Generate the mapping.
               MAP = AST__NULL

*  Unit mapping (null transformation).
               IF ( MAPTYP .EQ. 'UNIT' ) THEN
                  MAP = AST_UNITMAP( 2, ' ', STATUS )

*  Linear transformation.
               ELSE IF ( MAPTYP .EQ. 'LINEAR' ) THEN
                  CALL PAR_EXACD( 'COEFFS', 6, COEFFS, STATUS )
                  CALL CCD1_LNMAP( COEFFS, MAP, STATUS )

*  Pincushion transformation.
               ELSE IF ( MAPTYP .EQ. 'PINCUSHION' ) THEN
                  CALL PAR_EXACD( 'COEFFS', 3, COEFFS, STATUS )
                  STATUS = SAI__ERROR
                  CALL ERR_REP( ' ', 
     :'WCSEDIT: Pincushion mapping not implemented yet.', STATUS )
               END IF

*  Copy the basis frame, and add the new domain name, to create the 
*  new frame.
               FRBASI = AST_GETFRAME( IWCS, JBASIS, STATUS )
               FRNEW = AST_COPY( FRBASI, STATUS )
               CALL AST_SETC( FRNEW, 'Domain', 
     :                        DOMAIN( : CHR_LEN( DOMAIN ) ), STATUS )

*  Add the new frame to the WCS frameset.
               CALL AST_ADDFRAME( IWCS, JBASIS, MAP, FRNEW, STATUS )
               CALL CCD1_MSG( ' ', '      Added new frame', STATUS )
               SUCCES = .TRUE.

*  Remove any previously existing frames in the same domain.
               JNEW = AST_GETI( IWCS, 'Current', STATUS )
               CALL CCD1_DMPRG( IWCS, DOMAIN, JNEW, STATUS )

            END IF

            IF ( SUCCES ) THEN

*  Write out the modified WCS component.
               CALL NDF_PTWCS( IWCS, INDF, STATUS )

*  Append the name of the successfully modified NDF to the output list.
               IF ( CHR_LEN( MODIF ) .LT. LEN( MODIF ) - 2 ) THEN
                  IF ( CHR_LEN( MODIF ) .GT. 0 ) 
     :               MODIF( CHR_LEN( MODIF ) + 1: ) = ','
                  MODIF( CHR_LEN( MODIF ) + 1: ) = NAME
               END IF
            END IF
         END IF

*  Log failure if necessary.
         IF ( .NOT. SUCCES ) 
     :      CALL CCD1_MSG( ' ', '      NDF not modified', STATUS )

 1    CONTINUE

*  Write modification list to output parameter (unless it is full, and
*  so presumably incomplete).
      IF ( CHR_LEN( MODIF ) .GE. LEN( MODIF ) ) THEN
         CALL CCD1_MSG( ' ', ' ', STATUS )
         CALL CCD1_MSG( ' ', 
     :   'Warning: Too many NDFs modified -', STATUS )
         CALL CCD1_MSG( ' ',  
     :   '         output parameter MODIFIED not written.', STATUS )
         CALL CCD1_MSG( ' ', ' ', STATUS )
         MODIF = ' '
      END IF
      CALL PAR_PUT0C( 'MODIFIED', MODIF, STATUS )

*  Exit with error label.  Tidy up after this.
 99   CONTINUE

*  End NDF context.
      CALL NDF_END( STATUS )

*  Close IRH.
      CALL IRH_CLOSE( STATUS )

*  End AST context.
      CALL AST_END( STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
          CALL ERR_REP( 'WCSEDIT_ERR',
     :     'WCSEDIT: Modification of WCS components failed.',
     :     STATUS )
      END IF

*  Close down logging system.
      CALL CCD1_END( STATUS )

      END
* $Id$

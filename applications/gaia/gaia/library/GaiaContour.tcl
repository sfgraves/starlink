#+
#  Name:
#     GaiaContour

#  Type of Module:
#     [incr Tk] class

#  Purpose:
#     Defines a class for image contouring

#  Description:
#

#  Invocations:
#
#        GaiaContour object_name [configuration options]
#
#     This creates an instance of a GaiaContour object. The
#     return is the name of the object.
#
#        object_name configure -configuration_options value
#
#     Applies any of the configuration options (after the instance has
#     been created).
#
#        object_name method arguments
#
#     Performs the given method on this widget.

#  Configuration options:
#     See the "itk_option define" declarations below.

#  Methods:
#     See the method declarations below.

#  Inheritance:
#     TopLevelWidget

#  Copyright:
#     Copyright (C) 1999 Central Laboratory of the Research Councils

#  Authors:
#     PDRAPER: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     15-APR-1999 (PDRAPER):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itk::usual GaiaContour {}

itcl::class gaia::GaiaContour {

   #  Inheritances:
   #  -------------
   inherit util::TopLevelWidget

   #  Constructor:
   #  ------------
   constructor {args} {

      #  Evaluate any options.
      eval itk_initialize $args

      #  Set the top-level window title.
      wm title $w_ "GAIA: Contouring ($itk_option(-number))"

      #  Add short help window.
      make_short_help

      #  Add the File menu.
      add_menubar
      set File [add_menubutton "File" left]
      configure_menubutton File -underline 0

      #  Add the options menu
      set Options [add_menubutton "Options" left]
      configure_menubutton Options -underline 0

      #  Add window help.
      global env
      add_help_button $env(GAIA_DIR)/GaiaContour.hlp "On Window..."
      add_short_help $itk_component(menubar).help \
         {Help menu: get some help about this window}

      #  Add option to create a new window.
      $File add command -label {New window} \
         -command [code $this clone_me_] \
         -accelerator {Control-n}
      bind $w_ <Control-n> [code $this clone_me_]
      $short_help_win_ add_menu_short_help $File \
         {New window} {Create a new toolbox}

      #  Save configuration to a file.
      $File add command \
         -label {Save configuration...} \
         -command [code $this write_config_file] \
         -accelerator {Control-s}
      bind $w_ <Control-s> [code $this write_config_file]
      $short_help_win_ add_menu_short_help $File \
         {Save configuration...}\
         {Write the current configuration to a text file}

      #  Read configuration from a file.
      $File add command \
         -label {Read configuration...} \
         -command [code $this read_config_file] \
         -accelerator {Control-r}
      bind $w_ <Control-r> [code $this read_config_file]
      $short_help_win_ add_menu_short_help $File \
         {Read configuration...}\
         {Read previous configuration back from a text file}

      #  Set the exit menu item.
      $File add command -label Exit \
         -command [code $this close] \
         -accelerator {Control-c}
      bind $w_ <Control-c> [code $this close]

      #  Add an option plot carefully, or not.
      $Options add checkbutton \
         -label {Draw contours using geodesics (slow, but precise)} \
         -variable [scope careful_] \
         -onvalue 1 \
         -offvalue 0

      #  Allow selection of the contoured image.
      add_image_controls_

      #  Add controls for line attributes.
      add_att_controls_

      #  Add controls for level generation.
      add_gen_controls_

      #  Create the button bar
      itk_component add actionframe {frame $w_.action}

      #  Add a button to close window.
      itk_component add close {
         button $itk_component(actionframe).close -text Close \
            -command [code $this close]
      }
      add_short_help $itk_component(close) {Close window}

      #  Add a button to clear all contour levels.
      itk_component add clear {
         button $itk_component(actionframe).clear -text {Clear contours} \
            -command [code $this clear_contours]
      }
      add_short_help $itk_component(clear) {Clear all contour levels}

      #  Draw the contours.
      itk_component add draw {
         button $itk_component(actionframe).draw -text {Draw Contours} \
            -command [code $this draw 1]
      }
      add_short_help $itk_component(draw) {Draw all contours}

      #  Pack all the components into place.
      pack $itk_component(actionframe) -side bottom -fill x -pady 5 -padx 5
      pack $itk_component(close) -side right -expand 1 -pady 3 -padx 3
      pack $itk_component(clear) -side right -expand 1 -pady 3 -padx 3
      pack $itk_component(draw) -side left -expand 1 -pady 3 -padx 3


      #  Set the canvas level tags and record no contours are drawn.
      for {set i 1} {$i <= $itk_option(-maxcnt)} {incr i} {
         set leveltags_($i) cont[incr unique_]
         set drawn_($i) 0
      }

      #  Initialise the key tag.
      set keytag_ "ckey[incr unique_]"
      set texttag_ "ckey[incr unique_]"

   }

   #  Destructor:
   #  -----------
   destructor  {
   }

   #  Methods:
   #  --------

   #  Create a new instance of this object.
   protected method clone_me_ {} {
      if { $itk_option(-clone_cmd) != {} } {
         eval $itk_option(-clone_cmd)
      }
   }

   #  Close this window, kill it if needed, otherwise withdraw.
   public method close {} {
      if { $itk_option(-really_die) } {
         delete object $this
      } else {
         wm withdraw $w_
         #  Remove the contours.
         catch {remove_contours_}
      }
   }

   #  Save the current configuration to a file.
   public method write_config_file {} {
      set w [FileSelect .\#auto -title "Save configuration to a file"]
      if {[$w activate]} {
         save_config [$w get]
      }
      destroy $w
   }

   #  Restore configuration from a file.
   public method read_config_file {} {
      set w [FileSelect .\#auto -title "Read configuration from a file"]
      if {[$w activate]} {
         read_config [$w get]
      }
      destroy $w
   }

   #  Write the current configuration to a named file.
   public method save_config {filename} {
      if { $filename != {} } {
         busy {
            #  Open the output file.
            set fid [::open $filename w]
            puts $fid "\# GAIA Contours configuration file."

            # XXX fill in details

            # And add all the known values.
            ::close $fid
         }
      }
   }

   #  Read in configuration from a file.
   public method read_config {filename} {
      if { [file readable $filename] } {
         busy {
            #  Open the file.
            set fid [open $filename r]

            #  Loop over the file skipping comments and blank
            #  lines.
            set ok 1
            while { $ok  } {
               set llen [gets $fid line]
               if { $llen > 0 } {
                  if { ! [string match {\#*} $line] } {
                     # XXX fill in details...

                  }
               } elseif { $llen < 0 } {

                  # End of file.
                  set ok 0
               }
            }
            ::close $fid
         }
      }
   }

   #  Add controls for selecting the image to be contoured. This can
   #  an image displayed in another window, or retained in a file.
   protected method add_image_controls_ {} {

      #  Separator.
      itk_component add namerule {
         LabelRule $w_.namerule -text "Contour image:"
      }
      pack $itk_component(namerule) -side top -fill x

      #  Menu button for selection from displayed images.
      itk_component add targets {
         LabelMenu $w_.targets \
            -labelwidth 14 \
            -valuewidth 20 \
            -valueanchor e \
            -text "Displayed image:"
      }
      pack $itk_component(targets) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(targets) \
         {Displayed image that will be contoured}

      #  Add a binding to update the menu item whenever it is pressed.
      #  XXX bit of a cheat to get menubutton name.
      set menu [$itk_component(targets) component mb]
      bind $menu <ButtonPress-1> "+[code $this update_targets_]"

      #  Add the menu items.
      update_targets_

      #  Add a control for selecting a image stored in disk file.
      itk_component add conimg {
         LabelFileChooser $w_.conimg \
            -labelwidth 14 \
            -text "Other image:" \
            -filter_types $itk_option(-filter_types) \
            -textvariable [scope imagefile_]
      }
      pack $itk_component(conimg) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(conimg) \
         {File name of undisplayed image to contour}
   }

   #  Add the controls for the contour levels and attributes.
   protected method add_att_controls_ {} {

      itk_component add attrule {
         LabelRule $w_.attrule -text "Contour levels & attributes:"
      }
      pack $itk_component(attrule) -side top -fill x

      #  Use a scrolled frame to get all these in a small amount of
      #  real estate.
      itk_component add atframe {
         scrolledframe $w_.atframe -width 75 -height 320
      }
      pack $itk_component(atframe) -fill both -expand 1
      set parent [$itk_component(atframe) childsite]

      #  Add headings.
      itk_component add athead1 {
         label $parent.value -text "Level"
      }
      itk_component add athead2 {
         label $parent.colour -text "Colour"
      }
      itk_component add athead3 {
         label $parent.width -text "Width"
      }

      grid $itk_component(athead1) $itk_component(athead2) \
           $itk_component(athead3)


      #  Set up the colour index arrays and default values.
      foreach {index xname} $colourmap_ {
         set colindex_($xname) $index
      }
      for {set i 1} {$i <= $itk_option(-maxcnt)} {incr i} {
         set index [expr int(fmod($i-1,16)*2)+1]
         set coldefault_($i) "[lindex $colourmap_ $index]"
      }

      #  Now add the controls for the actual values.
      for {set i 1} {$i <= $itk_option(-maxcnt)} {incr i} {

         #  Entry widget for the contour values.
         itk_component add value$i {
            LabelEntry $parent.value$i \
               -validate real \
               -text "$i:" \
               -labelwidth 3 \
               -command [code $this draw 0 $i]
         }

         #  Menu for selecting the colour.
         itk_component add colour$i {
            util::LabelMenu $parent.colour$i \
               -relief raised
         }

         #  Now add all the colours to it.
         foreach {index xname} $colourmap_ {
            $itk_component(colour$i) add \
               -label {    } \
               -value $xname \
               -background $xname \
               -command [code $this set_colour_ $i]
         }

         #  Set to next colour in list.
         $itk_component(colour$i) configure -value $coldefault_($i)

         #  Add menu for selecting the width.
         itk_component add width$i {
            util::LabelMenu $parent.width$i \
               -relief raised
         }

         #  Now add the range of widths to it.
         for {set j 1} {$j <= $itk_option(-maxwidth)} {incr j} {
            $itk_component(width$i) add \
               -label $j \
               -value $j \
               -command [code $this set_width_ $i]
         }
         $itk_component(colour$i) configure -value 1

         #  Add these to the grid.
         grid $itk_component(value$i) $itk_component(colour$i) \
              $itk_component(width$i)
      }
      pack $itk_component(atframe) -fill both -expand 1
   }


   #  Update (or initialise) the possible target images.
   protected method update_targets_ {} {

      #  Remove any existing menu items.
      $itk_component(targets) clear

      #  Locate and add all images. The current image is "$target_".
      set images [skycat::SkyCat::get_skycat_images]

      #  Add the local rtdimage, this needs to be selected
      #  first.
      set name [$itk_option(-image) cget -file]
      $itk_component(targets) add \
         -label "$name ($itk_option(-number))" \
         -value "$itk_option(-image)" \
         -command [code $this set_target_ "$itk_option(-image)"]

      #  And add to the menu.
      foreach w $images {
         if { $w != $itk_option(-image) } {
            set name [$w cget -file]
            set clone [[winfo toplevel $w] cget -number]
            $itk_component(targets) add \
               -label "$name ($clone)" \
               -value "$w" \
               -command [code $this set_target_ "$w"]
         }
      }

      #  Contour self first.
      set_target_ $itk_option(-image)
   }

   #  Set the "target" image.
   protected method set_target_ {name} {
      set target_ $name
   }

   #  Draw either all the contours or just one which is identified by
   #  its index.
   public method draw { {all 1} {index 0} args} {
      busy {

         #  Check the image to be contoured.
         set rtdimage [get_rtdimage_]

         #  Clear existing contours.
         if { $all } {
            remove_contours_
            update
         } elseif { ! $all } {
            remove_contour_ $index
            update
         }

         #  Get the levels.
         if { $all } {
            set levels [get_levels_]
         } else {
            set levels [$itk_component(value$index) get]
         }

         #  Get the attributes.
         if { $all } {
            set atts [get_ast_atts_]
         } else {
            set atts [get_ast_att_ $index]
         }

         #  If requested just display over the visible canvas +/- a little.
         set bounds [calc_bounds_]

         #  Draw the contours. Do this one at a time so that we can
         #  update the interface.
         if { $all } {
            set ncont 0
            foreach value "$levels" {
               set att [lindex $atts $ncont]
               incr ncont

               #  Set the tag used to control clear etc.
               $itk_option(-rtdimage) configure -ast_tag \
                  "$itk_option(-contour_tag) $leveltags_($ncont)"

               #  Draw the contour (return value is number of points).
               set drawn_($ncont) \
                  [$itk_option(-rtdimage) contour \
                      $value $rtdimage $careful_ \
                      $att $bounds]

               #  Add/update the key.
               draw_key_
               update idletasks
            }
         } else {
            #  Set the tag used to control clear etc.
            $itk_option(-rtdimage) configure -ast_tag \
               "$itk_option(-contour_tag) $leveltags_($index)"

            #  Draw the contour.
            puts "time = [time {
               set drawn_($index) \
                  [$itk_option(-rtdimage) contour \
                      $levels $rtdimage $careful_ \
                      $atts $bounds] }]"

            #  Add/update the key.
            draw_key_
            update idletasks
         }

      }
   }

   #  Get the contour levels from the appropriate entry fields.
   protected method get_levels_ {} {
      set levels {}
      for {set i 1} {$i <= $itk_option(-maxcnt)} {incr i} {
         set value [$itk_component(value$i) get]
         if { $value != {} } {
            lappend levels $value
         }
      }
      if { $levels != {} } {
         return $levels
      } else {
         info_dialog "You must give some valid contour levels"
         return {}
      }
   }

   #  Get the attributes from the colour and width widgets.
   protected method get_ast_atts_ {} {
      set atts {}
      for {set i 1} {$i <= $itk_option(-maxcnt)} {incr i} {
         set value [$itk_component(value$i) get]
         if { $value != {} } {
            set colour [$itk_component(colour$i) get]
            set colour $colindex_($colour)
            set width [expr [$itk_component(width$i) get]*0.005]
            lappend atts "colour(curve)=$colour,width(curve)=$width"
         }
      }
      return $atts
   }

   #  Get the attributes from the colour and width widgets for a
   #  single contour.
   protected method get_ast_att_ {index} {
      set atts {}
      set value [$itk_component(value$index) get]
      if { $value != {} } {
         set colour [$itk_component(colour$index) get]
         set colour $colindex_($colour)
         set width [expr [$itk_component(width$index) get]*0.005]
         set atts "colour(curve)=$colour,width(curve)=$width"
      }
      return $atts
   }

   #  Get the plain attributes for a contour (without AST formatting).
   protected method get_att_ {index} {
      set atts {}
      set value [$itk_component(value$index) get]
      if { $value != {} } {
         set colour [$itk_component(colour$index) get]
         set width [$itk_component(width$index) get]
         set atts "$colour $width"
      }
      return $atts
   }

   #  Calculate the bounds of the visible image (canvas coordinates).
   protected method calc_bounds_ {} {
      set frac 0.80
      set xf [expr 0.5*(1.0-$frac)]
      set yf [expr 0.5*(1.0-$frac)]
      set w [winfo width $itk_option(-canvas)]
      set h [winfo height $itk_option(-canvas)]
      set x0 [$itk_option(-canvas) canvasx 0]
      set y0 [$itk_option(-canvas) canvasy 0]
      set dw [expr $w*$xf]
      set dh [expr $h*$yf]
      set x1 [expr $x0+$w-$dw]
      set y1 [expr $y0+$h-$dh]
      set x0 [expr $x0+$dw]
      set y0 [expr $y0+$dh]
      return [list $x0 $y0 $x1 $y1]
   }

   #  Clear the contours levels and attributes, or just the levels.
   public method clear_contours { {all 1} } {
      if { $all } {
         for {set i 1} {$i <= $itk_option(-maxcnt)} {incr i} {
            $itk_component(value$i) configure -value {}
            $itk_component(colour$i) configure -value $coldefault_($i)
            $itk_component(width$i) configure -value 1
         }
      } else {
         for {set i 1} {$i <= $itk_option(-maxcnt)} {incr i} {
            $itk_component(value$i) configure -value {}
         }
      }
      remove_contours_
   }

   #  Get the rtdimage that is needed for contouring. This can be the
   #  current image, a one displayed elsewhere or an image in a disk
   #  file. A filename takes preference over a one displayed already.
   protected method get_rtdimage_ {} {
      if { $imagefile_ != {} } {

         #  Displayed on disk, create an rtdimage and return this.
         if { [catch {image create rtdimage -file $imagefile_} rtdimage] != 0} {
            error_dialog "Failed to access image: $imagefile_, for contouring ($rtdimage)"
            set rtdimage {}
         }

      } else {

         #  Name of an rtdimage, just check that this isn't the
         #  current one and that it exists.
         if { [catch {$target_ get_image} rtdimage] != 0 }  {
            error "Failed to locate the displayed image for contouring"
            set rtdimage {}
         } else {
            if { $rtdimage == $itk_option(-rtdimage) } {
               set rtdimage {}
            }
         }
      }
      return $rtdimage
   }

   #  Remove all contours. Do it one-by-one so we don't interfere with
   #  other contour objects.
   protected method remove_contours_ {} {
      for {set i 1} {$i <= $itk_option(-maxcnt)} {incr i} {
         $itk_option(-canvas) delete $leveltags_($i)
         set drawn_($i) 0
      }

      #  Remove the key.
      $itk_option(-canvas) delete $keytag_
   }

   #  Remove a contour by index.
   protected method remove_contour_ {index} {
      $itk_option(-canvas) delete $leveltags_($index)
      set drawn_($index) 0

      #  Delete key and redraw it.
      $itk_option(-canvas) delete $keytag_
      draw_key_
   }

   #  Level generation commands. XXX Just use simple generation commands,
   #  no need to look at image data levels.
   protected method add_gen_controls_ {} {

      #  Add section header and frame to contain generation commands
      #  in a line.
      itk_component add genrule {
         LabelRule $w_.genrule -text "Contour level generation:"
      }
      pack $itk_component(genrule) -side top -fill x

      #  Number of contours to generate.
      itk_component add ncont {
         util::LabelMenu $w_.ncont \
            -relief raised \
            -text "Number:" \
            -labelwidth 14 \
            -valuewidth 20
      }
      pack $itk_component(ncont) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(ncont) \
         {Number of contour levels to generate}
      for {set i 1} {$i <= $itk_option(-maxcnt)} {incr i} {
         $itk_component(ncont) add \
            -label $i \
            -value $i
      }
      $itk_component(ncont) configure -value 5

      #  Starting value.
      itk_component add start {
         LabelEntry $w_.start \
            -validate real \
            -text "Start:" \
            -labelwidth 14 \
            -valuewidth 20 \
      }
      pack $itk_component(start) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(start) \
         {Starting point for level generation}

      #  Increment.
      itk_component add incre {
         LabelEntry $w_.incre \
            -validate real \
            -text "Increment:" \
            -labelwidth 14 \
            -valuewidth 20 \
      }
      pack $itk_component(incre) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(incre) \
         {Increment between generated levels}

      #  Type of generation.
      itk_component add ctype {
         util::LabelMenu $w_.ctype \
            -relief raised \
            -text {Algorithm:} \
            -labelwidth 14 \
            -valuewidth 20 \
      }
      pack $itk_component(ctype) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(ctype) \
         {Algorithm to use for contour generation}
      foreach type {automatic linear magnitude} {
         $itk_component(ctype) add \
            -label $type \
            -value $type
      }
      $itk_component(ctype) configure -value automatic

      #  Button to generate contours.
      itk_component add generate {
         button $w_.gen \
            -text "Generate" \
            -command [code $this generate_contours_]
      }
      pack $itk_component(generate) -side top -expand 1 -ipadx 1m -ipady 1m
      add_short_help $itk_component(generate) \
         {Generate contours}
   }

   #  Generate contours levels.
   protected method generate_contours_ {} {
      set ncont [$itk_component(ncont) get]
      set method [$itk_component(ctype) get]
      set start [$itk_component(start) get]
      set incre [$itk_component(incre) get]
      if { $method != "automatic" && ( $start == {} || $incre == {} ) } {
         info_dialog "Please enter values for all generation fields"
         return
      }
      clear_contours 0
      if { $method == "magnitude" } {
         for {set i 1} {$i <= $ncont} {incr i} {
            $itk_component(value$i) configure -value \
               [expr $start*pow(10.0,-0.4*($i-1)*$incre)]
         }
      } elseif { $method == "linear" } {
         for {set i 1} {$i <= $ncont} {incr i} {
            $itk_component(value$i) configure -value \
               [expr $start+($i-1)*$incre]
         }
      } else {
         set min [$itk_option(-rtdimage) min]
         set max [$itk_option(-rtdimage) max]
         set incre [expr double($max-$min)/double($ncont)]
         set start [expr $min+$incre*0.5]
         for {set i 1} {$i <= $ncont} {incr i} {
            $itk_component(value$i) configure -value \
               [expr $start+($i-1)*$incre]
         }
      }
   }

   #  Set the colour of a contour (if it is drawn).
   protected method set_colour_ {index} {
      set colour [$itk_component(colour$index) get]
      $itk_option(-canvas) itemconfigure $leveltags_($index) -fill $colour
   }

   #  Set the width of a contour (if it is drawn).
   protected method set_width_ {index} {
      set width [$itk_component(width$index) get]
      $itk_option(-canvas) itemconfigure $leveltags_($index) -width $width

      #  Text of key is special case, keep width 0.
      $itk_option(-canvas) itemconfigure $texttag_ -width 0
   }

   #  Add a level key to the image. The key consists of the level and
   #  a coloured line.
   protected method draw_key_ {} {

      #  Delete the current key.
      $itk_option(-canvas) delete $keytag_

      #  Get current levels.
      set levels [get_levels_]

      #  Get the bounds of the displayed contours and work out a
      #  suitable position for the key.
      set bounds [calc_bounds_]
      set x [lindex $bounds 2]
      set y [lindex $bounds 1]
      set dx 15.0
      set dy 15.0

      #  Draw the key.
      
      #  First the title.
      lassign [get_att_ 1] colour width
      $itk_option(-canvas) create text [expr $x+$dx+5] $y \
         -text "Contour key" \
         -anchor c \
         -fill $colour \
         -tags "$keytag_ $texttag_" \
         -width 0
      set y [expr $y+$dy]

      #  Now each line and level.
      for {set i 1} {$i <= $itk_option(-maxcnt)} {incr i} {
         if { $drawn_($i) } {
            set value [lindex $levels [expr $i-1]]
            lassign [get_att_ $i] colour width
            $itk_option(-canvas) create line $x $y [expr $x+$dx] $y \
               -fill $colour \
               -width $width \
               -tags "$keytag_ $leveltags_($i)"
            $itk_option(-canvas) create text [expr $x+$dx+5] $y \
               -text "$value" \
               -anchor w \
               -fill $colour \
               -tags "$keytag_ $leveltags_($i) $texttag_" \
               -width 0
            set y [expr $y+$dy]
         }
      }
      update

      #  Finally add the surround box (also used as control for
      #  repositioning whole of key).
      set bbox [$itk_option(-canvas) bbox $keytag_]
      if { $bbox != {} } {
         set x0 [expr [lindex $bbox 0] -5.0]
         set y0 [expr [lindex $bbox 1] -5.0]
         set x1 [expr [lindex $bbox 2] +5.0]
         set y1 [expr [lindex $bbox 3] +5.0]
         set keyid_ [$itk_option(-canvas) create rectangle $x0 $y0 $x1 $y1\
                        -outline white -tags "$keytag_" -width 1 \
                        -fill {}]
      }
   }

   #  Configuration options: (public variables)
   #  ----------------------
   #  Name of canvas.
   itk_option define -canvas canvas Canvas {} {}

   #  Name of rtdimage widget.
   itk_option define -rtdimage rtdimage RtdImage {} {}

   #  Name of RtdImageCtrl widget or a derived class.
   itk_option define -image image Image {} {}

   #  Name of CanvasDraw widget.
   itk_option define -canvasdraw canvasdraw CanvasDraw {} {}

   #  Identifying number for toolbox (shown in () in window title).
   itk_option define -number number Number 0 {}

   #  Command to execute to create a new instance of this object.
   itk_option define -clone_cmd clone_cmd Clone_Cmd {}

   #  If this is a clone, then it should die rather than be withdrawn.
   itk_option define -really_die really_die Really_Die 0

   #  The filter types of images.
   itk_option define -filter_types filter_types Filter_Types {} {}

   #  Whether contours are plotted carefully (slow, but precise) or not.
   itk_option define -careful careful Careful 0 {
      set careful_ $itk_option(-careful)
   }

   #  Global canvas tag used to control redraws etc. Individual
   #  tags are used within this class.
   itk_option define -contour_tag contour_tag Contour_Tag {} {
      if { $itk_option(-contour_tag) == {} } {
         set itk_option(-contour_tag) "ast_contour"
      }
   }

   #  Maximum number of contours, only works once.
   itk_option define -maxcnt maxcnt Maxcnt 30

   #  Maximum width of contour line (as multiple of 0.005).
   itk_option define -maxwidth maxwidth Maxwidth 4

   #  Protected variables: (available to instance)
   #  --------------------
   #  Whether contours are plotted carefully, used for checkbutton var.
   protected variable careful_ 0

   #  Name of rtdimage that we are contouring or the filename to use.
   protected variable target_ {}
   protected variable imagefile_ {}

   #  Which contours are drawn (needed to keep key free of undrawn
   #  levels).
   protected variable drawn_

   #  Names of the possible colours and their AST index equivalents.
   protected variable colourmap_ {
      0 "#fff" 2 "#f00" 3 "#0f0" 4 "#00f" 5 "#0ff" 6 "#f0f"
      7 "#ff0" 8 "#f80" 9 "#8f0" 10 "#0f8" 11 "#08f" 12 "#80f"
      13 "#f08" 14 "#512751275127" 15 "#a8b4a8b4a8b4" 1 "#000" }

   #  Colours-v-indices (set up from colourmap_) and default colours.
   protected variable colindex_
   protected variable coldefault_

   #  Tags used for configuring each contour levels.
   protected variable leveltags_

   #  Tags for elements of key (needs to be unique for each object).
   #  Text is different as need to disable width attributes.
   protected variable keytag_
   protected variable texttag_

   #  Common variables: (shared by all instances)
   #  -----------------

   #  Number of potential contours drawn.
   common unique_ 0


#  End of class definition.
}

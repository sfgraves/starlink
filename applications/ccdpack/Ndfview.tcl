   class Ndfview {
#+
#  Name:
#     Ndfview
 
#  Type of Module:
#     [incr Tk] Mega-Widget
 
#  Purpose:
#     Provide a window which can display an NDF.
 
#  Description.
#     This class provides a mega-widget which is capable of displaying
#     an NDF, zooming it, changing the colour maps etc. and also 
#     allowing the user to indicate a list of points which can be 
#     marked and retrieved by the caller.

#  Public Methods:
#
#     activate
#        Following a call to this method, the object gets put in the
#        "active" status, and it will allow markers to be put on the
#        image, update the display with respect to user actions, etc.
#        Prior to this call, the visual state of the object will
#        probably be inconsistent with the configuration options which
#        have been passed to it.  This method should normally be called 
#        only after an NDF has been loaded in using loadndf.
#
#     deactivate
#        After a call to this method, the user may no longer interact
#        with the widget to add new points.
#
#     loadndf ndf ?maxcanv?
#        This method loads an NDF into the viewer.
#           - ndf      -- A Tcl ndf object.
#           - maxcanv  -- If given and non-zero, the GWM widget will not be
#                         more than maxcanv screen pixels in either direction.
#
#     Ndfview also inherits all the public methods of Gwmview.

#  Public Variables (Configuration Options):
#
#     info = string
#        Gives a string which will be displayed somewhere in the window
#        near the displayed NDF.  Substitutions will be made as in the
#        title variable.
#
#     percentiles = list
#        A list containing two numbers between 0 and 100.  The user is
#        able to modify these somehow in the GUI.
#
#     title = string
#        This gives a title to show in the title bar which the window
#        manager displays.  The following substitutions will be made
#        before the title is displayed:
#           - %N  -- Full name of the NDF
#           - %n  -- Shortened name of the NDF (e.g. without full path)
#           - %h  -- X dimension of the NDF in pixels
#           - %w  -- Y dimension of the NDF in pixels
#           - %b  -- Pixel bounds of the NDF ([X1:X2,Y1:Y2])
#
#     trackposition = string
#        This gives a string which can display the current position of
#        the cursor over an NDF image.  Before the text is displayed,
#        the following substitutions will be made:
#           - %x  -- X pixel coordinate of the cursor
#           - %y  -- Y pixel coordinate of the cursor
#
#        and the resulting string will be evaluated as a Tcl expression
#        before being printed on the widget.
#
#     Ndfview also inherits all the public variables of Gwmview.
#-

#  Inheritance.
      inherit Gwmview


########################################################################
#  Constructor.
########################################################################
   constructor { args } {
      set canvas [ canvas ]
      itk_component add tracker {
         label [ childsite ].tracker -relief groove
      } {
         rename -font -trackfont trackFont Font
      }

#  Add more control groups.
      addgroup style WCS
      addgroup cutoff Cutoff

#  Construct additional control widgets.
      set panel [ panel ]
      itk_component add dstyle {
         stylecontrol $panel.dstyle \
            -value "drawaxes=0,grid=0,numlab=0" \
            -valuevar displaystyle
      }
      itk_component add wcsframe {
         wcsframecontrol $panel.wcsframe \
            -value CURRENT \
            -valuevar wcsframe
      }
      itk_component add percut {
         percentilecontrol $panel.percut \
            -choices { { 20 80 } { 10 90 } { 5 95 } \
                       { 2 98 } { 1 99 } { 0.5 99.5 } } \
            -allowcustom 1 \
            -value { 6 94 } \
            -valuevar percentiles
      }

#  Add new control widgets to the panel.
      addcontrol $itk_component(wcsframe) style
      addcontrol $itk_component(dstyle) style
      addcontrol $itk_component(percut) cutoff

#  Rearrange the control widget groups into two rows.
      itk_component add row1 { frame [ panel ].row1 }
      itk_component add row2 { frame [ panel ].row2 }
      set row1 $itk_component(row1)
      set row2 $itk_component(row2)
      lower $row1 
      lower $row2
      pack $row1 $row2 -side top -expand 1 -fill x
      foreach grp { zoom cutoff markers } {
         set win [ groupwin $grp ]
         pack $win -in $row1 -side left -fill x -expand 1
      }
      foreach grp { style action } {
         set win [ groupwin $grp ]
         pack $win -in $row2 -side left -fill x -expand 1
      }

#  Do requested configuration.
      eval itk_initialize $args
   }


########################################################################
#  Public methods.
########################################################################

#-----------------------------------------------------------------------
      public method addpoint { vx vy { ipoint "" } } {
#-----------------------------------------------------------------------

#  Invoke inherited addpoint method to add the point to the list and draw it.
         set ipoint [ chain  $vx $vy $ipoint ]
      
#  Set the canvas tag to use for this point.
         set tag mark$ipoint

#  Add a binding to remove the point from the canvas.
         $canvas bind $tag <Button-3> [ code $this removepoint $ipoint ]

#  Return index of added point.
         return $ipoint
      }


#-----------------------------------------------------------------------
      public method loadndf { ndfob { maxcanv 0 } } {
#-----------------------------------------------------------------------

#  Check that we are being asked to load a valid NDF.
         if { [ catch { $ndfob validndf } valid ] } {
            error "ndfview loadndf: \"$ndfob\" is not an ndf object."
         } elseif { ! $valid } {
            error "ndfview loadndf: \"$ndfob\" represents an invalid NDF."
         }

#  Get NDF bounds and ensure it is two-dimensional.
         set bounds [ $ndfob bounds ]
         if { [ llength $bounds ] != 2 } {
            error "NDF should be an image but has $ndim dimensions."
         }

#  Ensure that the GWM item is not currently occupied.
         removegwm

#  Store the ndf object.
         set ndf $ndfob

#  Get the NDF name and make a shortened version.
         set ndfname [ $ndf name ]
         regsub {.*[./]} $ndfname {} ndfshort

#  Configure the WCS frame widget.
         $itk_component(wcsframe) configure -ndf $ndf

#  Set useful geometry values.
         set xbase [ expr [ lindex [ lindex $bounds 0 ] 0 ] - 1 ]
         set ybase [ expr [ lindex [ lindex $bounds 1 ] 0 ] - 1 ]
         set xdim [ expr [ lindex [ lindex $bounds 0 ] 1 ] - $xbase ]
         set ydim [ expr [ lindex [ lindex $bounds 1 ] 1 ] - $ybase ]

#  Set the approximate pixel size of the NDF.
         configure -pixelsize [ $ndf pixelsize Pixel ]

#  Work out the size of the scrolledcanvas widget.
         wm deiconify $itk_interior
         update idletasks
         set canvwin [ $canvas component canvas ]
         set xcanv [ winfo width $canvwin ]
         set ycanv [ winfo height $canvwin ]

#  If the displayed size is smaller than the size of the scrolledcanvas
#  widget (but not necessarily than the canvas itself), enlarge it 
#  until it takes up the available space.
         set enlarge 0
         while { 1 } {
            set z [ zoominc $zoom [ expr $enlarge + 1 ] ]
            set xsize [ expr $xdim * $z * $pixelsize ]
            set ysize [ expr $ydim * $z * $pixelsize ]
            if { $xsize <= $xcanv && $ysize <= $ycanv } {
               incr enlarge 1
               if { [ zoominc $zoom [ expr $enlarge + 1 ] ] <= $z } { break }
            } else {
               break
            }
         }
         set zoom [ zoominc $zoom $enlarge ]

#  If the displayed size is going to exceed the specified maximum canvas
#  size restriction, then iteratively shrink the zoomfactor until it fits.
         set shrink 0
         while { 1 && $enlarge <= 0 } {
            set z [ zoominc $zoom $shrink ]
            set xsize [ expr $xdim * $z * $pixelsize ]
            set ysize [ expr $ydim * $z * $pixelsize ]
            if { $maxcanv > 0 && [ max $xsize $ysize ] > $maxcanv } {
               incr shrink -1
               if { [ zoominc $zoom $shrink ] >= $z } { break }
            } else { 
               break
            }
         }
         configure -zoom [ zoominc $zoom $shrink ]

#  Map the NDF.
         $ndf mapped 1

#  Finally display the NDF.
         display
      }


#-----------------------------------------------------------------------
      public method activate {} {
#-----------------------------------------------------------------------

#  Call the inherited activate method.
         chain

#  Ensure that all aspects of the display are updated.
         display

#  Register the geometry.
         geomset

#  Set key bindings for marking objects.
         $canvas bind all <Button-1> [ code $this newpoint %x %y ]
      }


#-----------------------------------------------------------------------
      public method deactivate {} {
#-----------------------------------------------------------------------

#  Call the inherited deactivate method.
         chain

#  Unset all canvas bindings.
         unbindall
      }


########################################################################
#  Private methods.
########################################################################

#-----------------------------------------------------------------------
      private method display {} {
#-----------------------------------------------------------------------
#  This method ensures, if we are in the active status, that the display
#  is up to date with respect to the various configuration variables etc.

#  Only attempt any display if we are in the active status and have
#  something to display.
         if { $status != "active" || $ndfname == "" } { return }

#  Only attempt display if characteristics have changed from the last
#  time they were displayed.  This is important for efficiency reasons
#  since the method may get called, possibly quite often, just to be
#  sure that the display is up to date.
         if { [ array exists displayed ] && \
              $displayed(ndfname) == $ndfname && \
              $displayed(percentiles) == $percentiles && \
              $displayed(zoomfactor) == $zoomfactor && \
              $displayed(displaystyle) == $displaystyle &&
              $displayed(wcsframe) == $wcsframe } {
            return
         }

#  Post a busy window.
         set waitwin [ waiter $canvas.wait -text "Drawing image $ndfname" ]

#  If the NDF has not been displayed before (but not if only its display
#  attributes have changed) then update the title bar and info panel.
         if { ! [ array exists displayed ] || \
              $displayed(ndfname) != $ndfname } {
            configure -title $title
            configure -info $info
         }

#  Keep a record of the attributes currently being displayed so if we
#  are called upon to do the same again we can skip it.
         set displayed(ndfname) $ndfname
         set displayed(percentiles) $percentiles
         set displayed(zoomfactor) $zoomfactor
         set displayed(displaystyle) $displaystyle
         set displayed(wcsframe) $wcsframe

#  Clear the canvas (it may contain markers as well as the GWM item).
         $canvas delete all

#  Create the GWM viewing item.
         makegwm $xbase $ybase $xdim $ydim

#  Get percentile values for drawing the display (these are cached 
#  efficiently by the NDF object, so there is no need to remember them
#  from last time for ourselves).  It is however better to calculate
#  both of these with a single call rather than with two calls.
         set scalevals [ $ndf percentile [ lindex $percentiles 0 ] \
                                         [ lindex $percentiles 1 ] ]

#  Display the NDF into the GWM item.
         set options {border=1 drawtitle=0 textlab=0 tickall=1 \
                      colour=3 colour(numlab)=5 colour(border)=4}
         lappend options $displaystyle
         $ndf display "[ gwmname ]/GWM" \
                      [ lindex $scalevals 0 ] [ lindex $scalevals 1 ] \
                      $wcsframe [ join $options "," ]
       # taskrun display " \
       #       in=$ndfname \
       #       device=[ devname ] \
       #       scale=true \
       #       mode=scale \
       #       low=[ lindex $scalevals 0 ] \
       #       high=[ lindex $scalevals 1 ] \
       #       margin=0 \
       #       style=\"tickall=1,drawtitle=0,$displaystyle\" \
       #       reset \
       #    "

#  Draw any points which have already been selected onto the new display.
         refreshpoints

#  Call any inherited 'display' method.
         chain

#  Return control to the user.
         destroy $waitwin
      }


#-----------------------------------------------------------------------
      private method newpoint { x y } {
#-----------------------------------------------------------------------
#  Add a point to the list of marked points, and draw it.

#  Get the coordinates of the point in NDF coordinates.
         set viewpos [ canv2view [ $canvas canvasx $x ] \
                                 [ $canvas canvasy $y ] ]
         set vx [ lindex $viewpos 0 ]
         set vy [ lindex $viewpos 1 ]

#  Add the point to the points list and draw it.
         addpoint $vx $vy
      }


#-----------------------------------------------------------------------
      private method trackpos { x y } {
#-----------------------------------------------------------------------
         if { $status == "active" } {
            if { $x == "" || $y == "" } {
               $itk_component(tracker) configure -text ""
            } else {
               set viewpos [ canv2view [ $canvas canvasx $x ] \
                                       [ $canvas canvasy $y ] ]
               set wcspos [ lindex [ $ndf wcstran -format \
                                     pixel $wcsframe $viewpos ] 0 ]
               set text $trackposition
               regsub -all %x $text [ lindex $viewpos 0 ] text
               regsub -all %y $text [ lindex $viewpos 1 ] text
               regsub -all %X $text [ lindex $wcspos 0 ] text
               regsub -all %Y $text [ lindex $wcspos 1 ] text
               $itk_component(tracker) configure -text [ expr \"$text\" ]
            }
         }
      }


#-----------------------------------------------------------------------
      private method infostring { string } {
#-----------------------------------------------------------------------
#  This method is used internally to substitute some information
#  which relates to the current state of the object into a string.
#  It is used to process, e.g., the title and info strings.

         regsub {%N} $string $ndfname string
         regsub {%n} $string $ndfshort string
         regsub {%h} $string $xdim string
         regsub {%w} $string $ydim string
         regsub {%b} $string "[expr $xbase + 1]:[expr $xbase + $xdim],[expr $ybase + 1]:[expr $ybase + $ydim]" string
         return $string
      }


########################################################################
#  Public variables.
########################################################################

#-----------------------------------------------------------------------
      public variable title "Ndfview" {
#-----------------------------------------------------------------------
         if { $status == "active" && $title != "" } {
            wm title $itk_interior [ infostring $title ]
         }
      }


#-----------------------------------------------------------------------
      public variable percentiles { 5 95 } {
#-----------------------------------------------------------------------
         display
      }


#-----------------------------------------------------------------------
      public variable displaystyle {} {
#-----------------------------------------------------------------------
         display
      }


#-----------------------------------------------------------------------
      public variable info "%n (%w x %h)" {
#-----------------------------------------------------------------------
         if { $status == "active" && $info != "" } {
            $itk_component(info) configure -text [ infostring $info ]
         }
      }


#-----------------------------------------------------------------------
      public variable trackposition { [ format "( %-10s, %-10s)" %X %Y ] } {
#-----------------------------------------------------------------------
         if { $trackposition == "" } {
            pack forget $itk_component(tracker)
            $canvas bind all <Motion> ""
            $canvas bind all <Leave> ""
         } else {
            $canvas bind all <Motion> [ code $this trackpos %x %y ]
            $canvas bind all <Leave> [ code $this trackpos "" "" ]
            pack $itk_component(tracker) -fill x -expand 0
         }
      }


#-----------------------------------------------------------------------
      public variable wcsframe "" {
#-----------------------------------------------------------------------
         display
      }



########################################################################
#  Private variables.
########################################################################

      private variable canvas ""       ;# Name of the canvas widget for display
      private variable displayed       ;# Array holding latest state of plot
      private variable ndf ""          ;# Tcl ndf object
      private variable ndfname ""      ;# Full name of NDF
      private variable ndfshort ""     ;# Short name of NDF
      private variable xbase 0         ;# Lower X pixel bound of NDF
      private variable xdim 0          ;# X dimension of NDF in pixels
      private variable ybase 0         ;# Lower Y pixel bound of NDF
      private variable ydim 0          ;# Y dimension of NDF in pixels

   }


########################################################################
#  Widget resource management
########################################################################

   itk::usual Ndfview {
      keep -background -cursor -foreground -geometry -canvasbackground
   }
   option add *Ndfview.trackFont fixed widgetDefault


########################################################################
#  Constructor alias
########################################################################

   proc ndfview { pathname args } {
      uplevel Ndfview $pathname $args
   }



# $Id$

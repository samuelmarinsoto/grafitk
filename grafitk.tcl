#!/usr/bin/env tclsh

package require Tk

# --- Command-line arg parsing ---
if {$argc != 2} {
    puts "Usage: $argv0 <x_column_index> <y_column_index>"
    puts "       (0-based indices)"
    exit 1
}

set xcol [lindex $argv 0]
set ycol [lindex $argv 1]

# --- Canvas setup ---
set width 600
set height 400
set margin 20

canvas .c -width $width -height $height -bg white
pack .c -fill both -expand 1

# --- Data storage ---
set points {}

# --- Scaling helper ---
proc map {val in_min in_max out_min out_max} {
    return [expr {
        $in_max == $in_min ? ($out_min + $out_max) / 2.0 :
        ($val - $in_min) * ($out_max - $out_min) / double($in_max - $in_min) + $out_min
    }]
}

# --- Drawing ---
proc plot_points {} {
    .c delete all
    global points width height margin

    if {[llength $points] < 2} return

    set xvals [lmap p $points {lindex $p 0}]
    set yvals [lmap p $points {lindex $p 1}]
    set xmin [tcl::mathfunc::min {*}$xvals]
    set xmax [tcl::mathfunc::max {*}$xvals]
    set ymin [tcl::mathfunc::min {*}$yvals]
    set ymax [tcl::mathfunc::max {*}$yvals]

    set pxs {}
    foreach point $points {
        set x [map [lindex $point 0] $xmin $xmax $margin [expr {$width - $margin}]]
        set y [map [lindex $point 1] $ymin $ymax [expr {$height - $margin}] $margin]
        lappend pxs $x $y
    }

    .c create line $pxs -fill blue -width 2
}

# --- Read line from stdin ---
proc read_stdin {} {
    global points xcol ycol

    if {[eof stdin]} {
        return
    }

    if {[gets stdin line] >= 0 && [string trim $line] ne ""} {
        set fields [split $line ","]
        if {[llength $fields] > $xcol && [llength $fields] > $ycol} {
            set xraw [string trim [lindex $fields $xcol]]
            set yraw [string trim [lindex $fields $ycol]]

            # Only proceed if both fields are numeric
            if {[string is double -strict $xraw] && [string is double -strict $yraw]} {
                set x [expr {$xraw + 0.0}]
                set y [expr {$yraw + 0.0}]
                lappend points [list $x $y]
                plot_points
            }
        }
    }

    after 50 read_stdin
}


after 50 read_stdin

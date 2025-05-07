#!/usr/bin/env tclsh

package require Tk

# --- Default config ---
set xcol -1
set ycols {}
set sliding 0
set window_size 100
set xlabel ""
set ylabel ""

# --- Parse command-line args ---
for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    switch -- $arg {
        -x {
            incr i
            set xcol [lindex $argv $i]
        }
        -y {
            incr i
            while {$i < $argc} {
                set val [lindex $argv $i]
                if {[string match -* $val]} {
                    incr i -1
                    break
                }
                lappend ycols $val
                incr i
            }
        }
        -s {
            incr i
            set sliding 1
            set window_size [lindex $argv $i]
        }
        -lx {
            incr i
            set xlabel [lindex $argv $i]
        }
        -ly {
            incr i
            set ylabel [lindex $argv $i]
        }
        default {
            puts "Unknown option: $arg"
            exit 1
        }
    }
}

# --- Validate args ---
if {$xcol < 0 || [llength $ycols] == 0} {
    puts "Usage: grafitk.tcl -x <xcol> -y <ycol1> [ycol2 ...] [-s <N>] [-lx <xlabel>] [-ly <ylabel>]"
    exit 1
}

# --- Canvas setup ---
set width 600
set height 400
set margin 40

canvas .c -width $width -height $height -bg white
pack .c -fill both -expand 1

# --- Data storage ---
set points {}

# --- Mapping utility ---
proc map {val in_min in_max out_min out_max} {
    if {$in_max == $in_min} {
        return [expr {($out_min + $out_max) / 2.0}]
    }
    return [expr {
        ($val - $in_min) * ($out_max - $out_min) / double($in_max - $in_min) + $out_min
    }]
}

# --- Math helpers ---
namespace eval ::tcl::mathfunc {
    proc isDouble {s} {
        string is double -strict $s
    }
}

# --- Plotting ---
proc plot_points {} {
    .c delete all
    global points width height margin ycols xlabel ylabel

    if {[llength $points] < 2} return

    set xvals [lmap p $points {lindex $p 0}]
    set yvals_flat {}
    foreach idx $ycols {
        foreach p $points {
            lappend yvals_flat [lindex $p [expr {$idx + 1}]]
        }
    }

    set xmin [tcl::mathfunc::min {*}$xvals]
    set xmax [tcl::mathfunc::max {*}$xvals]
    set ymin [tcl::mathfunc::min {*}$yvals_flat]
    set ymax [tcl::mathfunc::max {*}$yvals_flat]

    if {$xmax == $xmin} { set xmax [expr {$xmin + 1}] }
    if {$ymax == $ymin} { set ymax [expr {$ymin + 1}] }

    if {$xlabel ne ""} {
        .c create text [expr {$width / 2}] [expr {$height - 10}] -text $xlabel -anchor n
    }
    if {$ylabel ne ""} {
        .c create text 10 [expr {$height / 2}] -text $ylabel -anchor c -angle 90
    }

    .c create line $margin $margin $margin [expr {$height - $margin}] -fill gray
    .c create line $margin [expr {$height - $margin}] [expr {$width - $margin}] [expr {$height - $margin}] -fill gray

    set colorlist {blue red green orange purple black}
    set ci 0
    foreach idx $ycols {
        set pxs {}
        foreach p $points {
            set x [map [lindex $p 0] $xmin $xmax $margin [expr {$width - $margin}]]
            set y [map [lindex $p [expr {$idx + 1}]] $ymin $ymax [expr {$height - $margin}] $margin]
            lappend pxs $x $y
        }
        set color [lindex $colorlist [expr {$ci % [llength $colorlist]}]]
        .c create line $pxs -fill $color -width 2
        incr ci
    }
}

# --- Stream input ---
proc read_stdin {} {
    global points xcol ycols sliding window_size

    if {[eof stdin]} {
        return
    }

    if {[gets stdin line] >= 0 && [string trim $line] ne ""} {
        set fields [split $line ","]
        if {[llength $fields] <= $xcol} return
        if {![tcl::mathfunc::isDouble [lindex $fields $xcol]]} return
        set xval [expr {[lindex $fields $xcol] + 0.0}]
        set yvals {}
        foreach idx $ycols {
            if {[llength $fields] <= $idx || ![tcl::mathfunc::isDouble [lindex $fields $idx]]} {
                return
            }
            lappend yvals [expr {[lindex $fields $idx] + 0.0}]
        }
        lappend points [linsert $yvals 0 $xval]
        if {$sliding && [llength $points] > $window_size} {
            set points [lrange $points end-[expr {$window_size - 1}] end]
        }
        plot_points
    }

    after 50 read_stdin
}

# --- Start ---
after 50 read_stdin

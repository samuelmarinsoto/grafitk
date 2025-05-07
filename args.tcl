#!/usr/bin/env tclsh

puts "argc = $argc"
puts "argv = $argv"
puts ""

# Defaults
set xcol ""
set ycols {}
set sliding 0
set window_size ""
set xlabel ""
set ylabel ""

# Argument parser
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

# Output all parsed values
puts "-x: $xcol"
puts "-y: $ycols"
puts "-s: $sliding (size=$window_size)"
puts "-lx: $xlabel"
puts "-ly: $ylabel"

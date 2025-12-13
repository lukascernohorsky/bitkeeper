#!/usr/bin/env tclsh

# Tcl port of the Little Julia set demo.

package require Tk

proc complex_abs {pair} {
    expr {sqrt([lindex $pair 0]*[lindex $pair 0] + [lindex $pair 1]*[lindex $pair 1])}
}

proc complex_add {a b} {
    list [expr {[lindex $a 0] + [lindex $b 0]}] [expr {[lindex $a 1] + [lindex $b 1]}]
}

proc complex_multiply {a b} {
    set ar [lindex $a 0]
    set ai [lindex $a 1]
    set br [lindex $b 0]
    set bi [lindex $b 1]
    list [expr {$ar*$br - $ai*$bi}] [expr {$ar*$bi + $ai*$br}]
}

proc make_color {r g b} {
    format "#%02x%02x%02x" [expr {int($r*255)}] [expr {int($g*255)}] [expr {int($b*255)}]
}

proc julia {size depth zreal zimag} {
    set real_min -1.2
    set real_max 1.2
    set imag_min -1.2
    set delta [expr {($real_max - $real_min) / $size}]

    wm title . "Pretty Julia"
    wm geometry . +1+1
    canvas .c1 -width $size -height $size
    pack .c1
    update

    set z [list $zreal $zimag]
    set xreal $real_min
    for {set i 0} {$i < $size} {incr i} {
        set ximag $imag_min
        for {set j 0} {$j < $size} {incr j} {
            set count 0.0
            set x [list $xreal $ximag]
            while {$count < $depth && [complex_abs $x] < 2.0} {
                incr count
                set x [complex_add [complex_multiply $x $x] $z]
            }
            if {[complex_abs $x] <= 2.0} {
                .c1 create rectangle $i $j $i $j -outline [make_color 0 0 0]
            } else {
                set intensity [expr {$count / $depth}]
                if {$intensity > 0.001} {
                    .c1 create rectangle $i $j $i $j -outline [make_color $intensity $intensity $intensity]
                }
            }
            set ximag [expr {$ximag + $delta}]
        }
        set xreal [expr {$xreal + $delta}]
    }
}

proc main {argv} {
    set size 256
    set depth 100
    set zreal -0.81
    set zimag 0.156
    if {[llength $argv] >= 4} {
        lassign $argv size depth zreal zimag
    }
    julia $size $depth $zreal $zimag
    return 0
}

if {![info exists ::tcl_interactive] || !$::tcl_interactive} {
    set code [catch {main $argv} result]
    if {$code} {
        if {[string length $result]} {puts stderr $result}
        exit 1
    }
    exit $result
}

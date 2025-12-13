#!/usr/bin/env tclsh
#
# Tcl translation of pull-size.l
# Reports size metrics for pending pulls in nested products.

proc usage {prog} {
    puts stderr "usage: $prog [-r<range>]"
    exit 1
}

set dashR 1
set revs ""
set extra {}
set idx 0
while {$idx < [llength $argv]} {
    set arg [lindex $argv $idx]
    if {[string match "-r*" $arg]} {
        set dashR 0
        if {[string length $arg] > 2} {
            set revs "-r[string range $arg 2 end]"
        } else {
            incr idx
            if {$idx >= [llength $argv]} { usage [file tail [info script]] }
            set revs "-r[lindex $argv $idx]"
        }
    } else {
        lappend extra $arg
    }
    incr idx
}

set url ""
if {$dashR} {
    if {[llength $extra] > 0} {
        set url [lindex $extra 0]
    } else {
        if {[catch {exec bk parent -l} parents] || [llength [split [string trim $parents] "\n"]] != 1} {
            usage [file tail [info script]]
        }
        set url [string trim [lindex [split $parents "\n"] 0]]
    }
}

if {[string trim [exec bk -P repotype]] ne "product"} {
    puts stderr "[file tail [info script]]: only works in nested repositories"
    exit 1
}

if {$dashR} {
    set allfiles [split [exec bk changes -vqnd:DPN: -R $url] "\n"]
} else {
    set allfiles [split [exec bk changes -vqnd:DPN: $revs] "\n"]
}

set total_deltas 0
set total_comp_csets 0
set total_prod_csets 0
set comps {}
array set deltas_x_file {}

foreach file $allfiles {
    if {[string trim $file] eq ""} continue
    if {[string match {*ChangeSet} $file]} {
        set cpath [string range $file 0 end-9]
        if {[dict exists $comps $cpath]} {
            dict incr comps $cpath
        } else {
            dict set comps $cpath 0
        }
        if {$file eq "ChangeSet"} { incr total_prod_csets }
        incr total_comp_csets
    } else {
        if {[info exists deltas_x_file($file)]} {
            incr deltas_x_file($file)
        } else {
            set deltas_x_file($file) 0
        }
        incr total_deltas
    }
}

puts -nonewline [format "%d csets, %d file deltas, " $total_prod_csets $total_deltas]
puts [format "%d components, %d files" [dict size $comps] [array size deltas_x_file]]

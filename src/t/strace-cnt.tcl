#!/usr/bin/env tclsh

# Tcl rewrite of src/t/strace-cnt.pl
# Copyright 2008,2015 BitMover, Inc
# Licensed under the Apache License, Version 2.0

proc usage {} {
    puts stderr "usage: strace-cnt <name> <trace-file>"
    exit 1
}

if {[llength $argv] != 2} {
    usage
}

lassign $argv name trace

set baselineDir [string trim [exec bk bin]]
set baseline "$baselineDir/t/strace.$name.ref"

set ntotal 0
array set newCounts {}
set fh [open $trace r]
while {[gets $fh line] >= 0} {
    if {[regexp {^(\w+)\(} $line -> syscall]} {
        if {![info exists newCounts($syscall)]} {
            set newCounts($syscall) 0
        }
        incr newCounts($syscall)
        incr ntotal
    }
}
close $fh

if {[info exists ::env(STRACE_CNT_SAVE)] && $::env(STRACE_CNT_SAVE) ne ""} {
    cd /tmp

    exec bk edit -q $baseline
    set bfh [open $baseline w]
    puts $bfh "# baseline data for t.strace-cnt"
    foreach syscall [lsort -dict [array names newCounts]] {
        puts $bfh "$syscall $newCounts($syscall)"
    }
    close $bfh
    exec bk ci -qa -ynew-baseline $baseline

    set fullBaseline "$baselineDir/t/strace.$name.ref.full"
    exec bk edit -q $fullBaseline
    exec cp $trace $fullBaseline
    exec bk ci -qa -ynew-baseline $fullBaseline
    exit 0
}

exec bk get -qS $baseline
set bfh [open $baseline r]
set btotal 0
array set baseCounts {}
while {[gets $bfh line] >= 0} {
    if {[regexp {^(\w+) (\d+)} $line -> syscall count]} {
        set baseCounts($syscall) $count
        incr btotal $count
    }
}
close $bfh

foreach syscall {read write} {
    if {[info exists baseCounts($syscall)]} {
        incr btotal -$baseCounts($syscall)
        unset baseCounts($syscall)
    }
    if {[info exists newCounts($syscall)]} {
        incr ntotal -$newCounts($syscall)
        unset newCounts($syscall)
    }
}

proc compareNew {a b} {
    global newCounts
    return [expr {$newCounts($b) <=> $newCounts($a)}]
}

set cumm 0
set fail 0
foreach key [lsort -command compareNew [array names newCounts]] {
    if {[info exists baseCounts($key)] && $baseCounts($key) > 0} {
        set diff [expr {abs($newCounts($key) - $baseCounts($key)) / double($baseCounts($key))}]
        if {$diff > 0.10} {
            puts "calls to $key changed, was $baseCounts($key) now $newCounts($key)"
            set fail 1
        }
    }
    set cumm [expr {$cumm + $newCounts($key)}]
    if {$ntotal > 0 && ($cumm / double($ntotal)) > 0.95} {
        break
    }
}

if {$btotal > 0} {
    set totalDiff [expr {abs($ntotal - $btotal) / double($btotal)}]
    if {$totalDiff > 0.10} {
        puts "total syscalls changed, was $btotal now $ntotal"
        set fail 1
    }
}

exit 0

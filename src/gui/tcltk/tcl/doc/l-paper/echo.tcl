#!/usr/bin/env tclsh

# Tcl port of the Little echo sample that prints indexed arguments.

proc main {argv} {
    set i 0
    foreach arg $argv {
        puts [format {[%d] = %s} $i $arg]
        incr i
    }
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

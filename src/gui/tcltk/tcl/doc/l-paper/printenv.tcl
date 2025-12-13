#!/usr/bin/env tclsh

# Tcl port of the Little printenv sample that dumps the process environment.

proc main {argv} {
    foreach key [lsort [array names ::env]] {
        puts [format "env{%s} = %s" $key $::env($key)]
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

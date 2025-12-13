#!/usr/bin/env tclsh

# Tcl port of the Little/Tcl interop demo.

proc set_ref {varName value} {
    upvar 1 $varName out
    set out $value
}

proc L_to_tcl {} {
    set s "Hi there mom"
    set a 1234

    puts $a
    puts $s
    set_ref s "Hi yourself"
    puts $s
    puts -nonewline "Hi "
    puts "there"
}

proc main {argv} {
    L_to_tcl
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

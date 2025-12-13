#!/usr/bin/env tclsh

# Tcl port of the Little sample that concatenates files (or stdin) to stdout.

proc main {argv} {
    if {[llength $argv] == 0} {
        puts -nonewline [read stdin]
        return 0
    }

    foreach path $argv {
        if {[catch {set fh [open $path r]} msg]} {
            puts stderr $msg
            return 1
        }
        fconfigure $fh -translation binary
        puts -nonewline [read $fh]
        close $fh
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

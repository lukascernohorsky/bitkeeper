#!/usr/bin/env tclsh

# Tcl port of the Little grep sample.

proc grepStream {pattern channel} {
    while {[gets $channel line] >= 0} {
        if {[regexp -- $pattern $line]} {
            puts $line
        }
    }
}

proc main {argv} {
    if {[llength $argv] < 1} {
        puts stderr "Not enough arguments."
        return 1
    }

    set pattern [lindex $argv 0]
    set files [lrange $argv 1 end]

    if {[llength $files] == 0} {
        grepStream $pattern stdin
        return 0
    }

    foreach path $files {
        if {[catch {set fh [open $path r]} msg]} {
            puts stderr $msg
            return 1
        }
        grepStream $pattern $fh
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

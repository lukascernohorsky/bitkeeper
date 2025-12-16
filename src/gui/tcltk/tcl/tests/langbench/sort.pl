#!/usr/bin/env tclsh
proc main {} {
    global argv
    set lines {}
    foreach file $argv {
        set f [open $file rb]
        while {[gets $f buf] >= 0} { lappend lines $buf }
        close $f
    }
    foreach buf [lsort $lines] { puts $buf }
}
fconfigure stdout -buffering full -translation binary
main

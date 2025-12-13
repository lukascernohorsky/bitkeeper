#!/usr/bin/env tclsh

foreach path $argv {
    if {[catch {open $path rb} fh]} {
        continue
    }
    fconfigure $fh -translation binary
    while {[gets $fh line] >= 0} {
        if {[regexp {[^A-Za-z]fopen\(.*\)} $line]} {
            puts $line
        }
    }
    close $fh
}

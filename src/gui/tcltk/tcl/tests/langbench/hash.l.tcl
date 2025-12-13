#!/usr/bin/env tclsh

set entries {}
foreach path $argv {
    if {[catch {open $path rb} fh]} {
        continue
    }
    fconfigure $fh -translation binary
    while {[gets $fh line] >= 0} {
        dict set entries $line 1
    }
    close $fh
}

#!/usr/bin/env tclsh

fconfigure stdout -buffering full -translation binary
foreach path $argv {
    if {[catch {open $path rb} fh]} {
        continue
    }
    fconfigure $fh -translation binary
    while {[gets $fh line] >= 0} {
        puts $line
    }
    close $fh
}

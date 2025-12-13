#!/usr/bin/env tclsh

set lines {}
fconfigure stdout -buffering full -translation binary
foreach path $argv {
    if {[catch {open $path rb} fh]} {
        continue
    }
    fconfigure $fh -translation binary
    while {[gets $fh line] >= 0} {
        lappend lines $line
    }
    close $fh
}
foreach line [lsort $lines] {
    puts $line
}

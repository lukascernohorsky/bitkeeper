#!/usr/bin/env tclsh
fconfigure stdout -buffering full -translation binary
proc cat {file} {
    set f [open $file rb]
    while {[gets $f buf] >= 0} { puts $buf }
    close $f
}
foreach file $argv { cat $file }

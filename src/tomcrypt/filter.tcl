#!/usr/bin/env tclsh
# Filter everything between START_INS and END_INS and insert the contents of
# another file at that location, mirroring the original Perl helper.

if {[llength $argv] != 2} {
    puts stderr "usage: tclsh filter.tcl <dst> <ins>"
    exit 1
}

set dst [lindex $argv 0]
set ins [lindex $argv 1]

set srcChan [open $dst r]
set insChan [open $ins r]
set outChan [open "tmp.delme" w]

set inserting 0
while {[gets $srcChan line] >= 0} {
    if {[regexp {START_INS} $line]} {
        puts $outChan $line
        set inserting 1
        while {[gets $insChan insLine] >= 0} {
            puts $outChan $insLine
        }
        close $insChan
    } elseif {[regexp {END_INS} $line]} {
        puts $outChan $line
        set inserting 0
    } elseif {!$inserting} {
        puts $outChan $line
    }
}

close $outChan
close $srcChan

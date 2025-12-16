#!/usr/bin/env tclsh

# Split a concatenated libtommath changelog stream into per-version logs.
# Mirrors the original Perl helper `splitc.ltm`.

set data [read stdin]
set lines [split $data "\n"]
set chunks {}
set current ""
foreach line $lines {
    if {[regexp {^v\d} $line] && $current ne ""} {
        lappend chunks $current
        set current ""
    }
    append current $line "\n"
}
if {$current ne ""} {
    lappend chunks $current
}

foreach chunk $chunks {
    regsub {^\n+} $chunk {} chunk
    if {![string match *\n $chunk]} {
        append chunk "\n"
    }
    if {[regexp {(?m)^v(\d\.\S+)} $chunk -> ver]} {
        set fh [open "libtommath-$ver.log" w]
        puts -nonewline $fh $chunk
        close $fh
    }
}

#!/usr/bin/env tclsh
# Split a space-delimited list of files and emit makefile-friendly lines
# with line continuations, mirroring the original Perl helper.

if {[llength $argv] != 2} {
    puts stderr "usage: tclsh parsenames.tcl <NAME> <space-delimited-list>"
    exit 1
}

set name [lindex $argv 0]
set items [split [lindex $argv 1]]
set output "$name="
set lineLen [string length $output]
puts -nonewline $output

foreach obj $items {
    set clean [string map {* $} $obj]
    set lineLen [expr {$lineLen + [string length $clean]}]
    if {$lineLen > 100} {
        puts "\\"
        set lineLen [string length $clean]
    }
    puts -nonewline "$clean "
}

if {$name eq "HEADERS"} {
    puts -nonewline "testprof/tomcrypt_test.h"
}

puts "\n"

#!/usr/bin/env tclsh
#
# Tcl translation of hello.l
# Prints a hello message, argument count, and the provided arguments.

set argc [llength $argv]
puts "Hello world"
puts "ac = $argc"
for {set i 0} {$i < $argc} {incr i} {
    puts [lindex $argv $i]
}

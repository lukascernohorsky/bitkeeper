#!/usr/bin/env tclsh
# Generates a single aggregated source file (mpi.c) from all bn*.c inputs
# without requiring Perl.

set out [open "mpi.c" w]
foreach filename [lsort [glob -nocomplain "bn*.c"]] {
    set in [open $filename r]
    puts $out "/* Start: $filename */"
    fcopy $in $out
    puts $out "\n/* End: $filename */\n"
    close $in
}
puts $out "\n/* EOF */"
close $out

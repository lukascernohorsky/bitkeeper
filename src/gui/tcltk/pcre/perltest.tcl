#!/usr/bin/env tclsh
# Lightweight Tcl replacement for the original Perl regex tester.
# It exercises Tcl's regexp engine to approximate the Perl checks that
# accompanied PCRE, avoiding a Perl dependency while keeping similar I/O.

package require Tcl 8.6

proc openInOut {argv} {
    set infile stdin
    set outfile stdout
    if {[llength $argv] > 0} {
        set infile [open [lindex $argv 0] r]
    }
    if {[llength $argv] > 1} {
        set outfile [open [lindex $argv 1] w]
    }
    return [list $infile $outfile]
}

proc parsePattern {line} {
    set line [string trim $line]
    set delim [string index $line 0]
    set idx [string last $delim $line]
    set body [string range $line 1 [expr {$idx - 1}]]
    set flags [string range $line [expr {$idx + 1}] end]
    return [list $body $flags]
}

proc applyFlags {flagsVar} {
    upvar 1 $flagsVar flags
    set opts {}
    if {[string first "i" $flags] >= 0} { lappend opts -nocase }
    if {[string first "m" $flags] >= 0} { lappend opts -line }
    if {[string first "s" $flags] >= 0} { lappend opts -lineanchor 0 }
    return $opts
}

proc testPattern {body flags infile outfile} {
    puts $outfile "Pattern: /$body/$flags"
    set switches [applyFlags flags]
    for {set line [gets $infile txt]} {$line >= 0} {set line [gets $infile txt]} {
        if {$txt eq ""} break
        puts $outfile "  > $txt"
        set matched 0
        if {[regexp -inline {*}$switches -- $body $txt] ne {}} {
            set all [regexp -inline -all {*}$switches -- $body $txt]
            set matched 1
            set idx 0
            foreach m $all {
                puts $outfile "    $idx: $m"
                incr idx
            }
        }
        if {!$matched} {
            puts $outfile "    No match"
        }
    }
    puts $outfile ""
}

lassign [openInOut $argv] infile outfile
puts $outfile "Tcl [info patchlevel] Regular Expressions\n"
while {[gets $infile line] >= 0} {
    set line [string trimright $line]
    if {$line eq ""} continue
    if {[catch {lassign [parsePattern $line] body flags} err]} {
        puts $outfile "Error: $err"
        continue
    }
    testPattern $body $flags $infile $outfile
}
if {$outfile ne "stdout"} { close $outfile }
if {$infile ne "stdin"} { close $infile }

#!/usr/bin/env tclsh

set ::env(GROFF_NO_SGR) 1

if {[llength $argv] != 1} {
    puts stderr "usage: help2sum.tcl <helptxt2>"
    exit 1
}

set inputPath [lindex $argv 0]
set in [open $inputPath r]
set all [open "All.summaries" w]
set catHandles [dict create]
proc summary {section} {
    set roff "$section.roff"
    set out [open $roff w]

    set macros [open "../bk-macros" r]
    puts -nonewline $out [read $macros]
    close $macros
<<<<<<< codex/create-migration-plan-from-perl-to-tcl-4b4k6a
    # Ensure the injected macros end with a separator so the following
    # requests always start on a fresh line, even if bk-macros lacks a
    # trailing newline.
    puts $out ""
=======
>>>>>>> master

    puts $out ".pl 1000i"
    puts $out ".TH \"$section\" sum \"\" \"\\*(BC\" \"\\*(UM\""
    puts $out ".SH NAME"
    puts -nonewline $out "$section \\\\- summary of "
    if {[regexp {^[0-9a-zA-Z]$} $section]} {
        puts $out "commands in section $section"
    } elseif {$section eq "All"} {
        puts $out "all commands and topics"
    } else {
        puts $out "the $section category"
    }

    if {[file readable "$section.description"]} {
        set desc [open "$section.description" r]
        puts -nonewline $out [read $desc]
        close $desc
    }

    puts $out ".SH COMMANDS"
    puts $out ".nf"

    set summaries [open "$section.summaries" r]
    puts -nonewline $out [read $summaries]
    close $summaries
    file delete "$section.summaries"
    close $out

    set done [open "$section.done" w]
    puts $done "help://$section"
    puts $done "help://$section.sum"
    if {$section eq "All"} {
        puts $done "help://topics"
        puts $done "help://topic"
        puts $done "help://command"
        puts $done "help://commands"
    }

    set g [open "|groff -rhelpdoc=1 -I.. -P-u -P-b -Tascii < $roff" r]
    set nl 0
    while {[gets $g line] >= 0} {
        if {$line eq ""} {
            set nl 1
            continue
        }
        if {$nl} {
            puts $done ""
        }
        regsub {^\s+} $line "  " line
        puts $done $line
        set nl 0
    }
    puts $done "\\$"
<<<<<<< codex/create-migration-plan-from-perl-to-tcl-4b4k6a
    # The Perl version ignored groff's exit status; mirror that behavior so
    # warnings don't break the build.
    catch { close $g }
=======
    close $g
>>>>>>> master
    close $done
}

set current ""
while {[gets $in line] >= 0} {
    if {[regexp {^NAME\s*$} $line]} {
        set current ""
        if {[gets $in line] < 0} {
            break
        }
        while {$line ne ""} {
            if {$current ne "" && [regexp {^\s*bk } $line]} {
                append current "\n"
            }
            set trimmed [string trim $line]
            regsub -all { \s+} $trimmed " " trimmed
            append current $trimmed " "
            if {[gets $in line] < 0} {
                set line ""
                break
            }
        }
        append current "\n"
        regsub -all {Bit- Keeper} $current {BitKeeper} current
        regsub -all {\s+\n} $current {\n} current
        puts -nonewline $all $current
    }

    if {[regexp {^CATEGORY\s*$} $line]} {
        if {[gets $in line] < 0} {
            break
        }
        while {$line ne ""} {
            set trimmed [string trimleft $line]
            if {![dict exists $catHandles $trimmed]} {
                set handle [open "$trimmed.summaries" a]
                dict set catHandles $trimmed $handle
            }
            puts -nonewline [dict get $catHandles $trimmed] $current
            if {[gets $in line] < 0} {
                set line ""
                break
            }
        }
    }
}

close $in
close $all

summary "All"
foreach section [dict keys $catHandles] {
    close [dict get $catHandles $section]
    summary $section
}

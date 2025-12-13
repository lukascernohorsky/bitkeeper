#!/usr/bin/env tclsh
# Emit version information suitable for inclusion in a Windows resource file.

proc usage {prog err} {
    puts stderr "$prog: $err"
    puts stderr "Usage: $prog UTC [TAG]"
    puts stderr "       TAG is in the form bk-#.#.#suffix"
    exit 1
}

proc parse_version {{tag ""}} {
    if {[regexp {^bk-([0-9]+)\.([0-9]+)(ce)?$} $tag -> a b]} {
        return [list $a $b 0 0]
    }
    if {[regexp {^bk-([0-9]+)\.([0-9]+)\.([0-9]+)(ce)?$} $tag -> a b c]} {
        return [list $a $b $c 0]
    }
    if {[regexp {^bk-([0-9]+)\.([0-9]+)\.([0-9]+)(.*)$} $tag -> a b c suffix]} {
        if {[string length $suffix] == 1} {
            scan [string tolower $suffix] %c code
            set d [expr {$code - 96}]
        } else {
            set sum 0
            foreach ch [split [string tolower $suffix] ""] {
                scan $ch %c code
                set sum [expr {$sum + $code}]
            }
            set d [expr {$sum & 0xffff}]
        }
        return [list $a $b $c $d]
    }
    usage [file tail [info script]] "could not parse tag: $tag"
}

proc utc_to_version {utc} {
    set a [string range $utc 0 3]
    set b [string range $utc 4 5]
    set c [string range $utc 6 7]
    set d [string range $utc 8 11]
    return [list $a $b $c $d]
}

proc print_macros {parts} {
    foreach {a b c d} $parts break
    puts [format "#define\tVER_FILEVERSION\t\t%s,%s,%s,%s" $a $b $c $d]
    puts [format "#define\tVER_FILEVERSION_STR\t\"%s.%s.%s.%s\\0\"\n" $a $b $c $d]
    puts [format "#define\tVER_PRODUCTVERSION\t%s,%s,%s,%s" $a $b $c $d]
    puts [format "#define\tVER_PRODUCTVERSION_STR\t\"%s.%s.%s.%s\\0\"" $a $b $c $d]
}

set prog [file tail [info script]]
set argv0 [info nameofexecutable]
if {[file tail $argv0] eq "tclsh"} {
    set argv0 [expr {[info exists ::env(BK_EXE)] ? $::env(BK_EXE) : "bk"}]
}
if {[catch {exec $argv0 changes -r+ -d":UTC: :TAG:"} changes_line]} {
    usage $prog "could not fetch version info"
}
if {![regexp {^(\S+)\s*(\S*)} $changes_line -> utc tag]} {
    usage $prog "unexpected changes output: $changes_line"
}
if {[string length $tag]} {
    print_macros [parse_version $tag]
} else {
    print_macros [utc_to_version $utc]
}

#!/usr/bin/env tclsh

proc usage {} {
    puts stderr "Usage: man2help.tcl [-debug] macros [prefix] page..."
    exit 1
}

proc readFile {path} {
    if {![file readable $path]} {
        puts stderr "Cannot read $path"
        exit 1
    }
    set fd [open $path r]
    set data [read $fd]
    close $fd
    return $data
}

proc writeBkverMacro {bkver} {
    if {[regexp {\s} $bkver]} {
        puts stderr "Spaces not allowed in BKVER='$bkver'"
        exit 1
    }
    set fd [open "../bkver-macro" w]
    puts $fd ".ds BKVER \\\\s-2$bkver\\\\s0"
    close $fd
}

proc detectBkver {} {
    foreach candidate {../../src/bk ../../src/bk.exe bk} {
        if {[file executable $candidate]} {
            if {![catch {set out [exec $candidate version -s]}]} {
                return [string trim $out]
            }
        }
    }
    puts stderr "Unable to determine bk version"
    exit 1
}

proc normalizeBkver {bkver} {
    if {[regexp {^([0-9]{4})([0-9]{2})([0-9]{2})$} $bkver -> y m d]} {
        return "$y-$m-$d"
    }
    return $bkver
}

proc groffAvailable {} {
    return [expr {![catch {exec sh -c {command -v groff >/dev/null 2>&1}}]}]
}

proc man2help {page macros prefix bkver debug} {
    set basename [file tail $page]
    if {![regexp {^(.*)\.([^.]+)$} $basename -> name section]} {
        puts stderr "Invalid manpage name: $page"
        return
    }
    set output "$name-$section.fmt"
    if {[file exists $output] && [file mtime $output] > [file mtime $page]} {
        return
    }

    if {$debug} {
        puts stderr "Format $page ( $name . $section )"
    }

    set out [open $output w]
    if {$prefix ne "" && [string first $prefix $name] == 0} {
        set tail [string range $name [string length $prefix] end]
        puts $out "help://$tail"
        puts $out "help://$tail.$section"
    }
    puts $out "help://$name"
    puts $out "help://$name.$section"

    set din [open $page r]
    set tmp [open "tmp" w]
    puts $tmp ".pl 10000i"
    puts -nonewline $tmp $macros
    while {[gets $din line] >= 0} {
        if {[string match "*bk-macros*" $line]} {
            continue
        }
        puts $tmp $line
        if {[regexp {^\."\s+help://(.*)} $line -> help]} {
            puts $out "help://$help"
        }
    }
    close $din
    close $tmp

    if {[groffAvailable]} {
        set cmd "groff -I.. -dBKVER=$bkver -rhelpdoc=1 -rNESTED=1 -P-u -P-b -Tascii < tmp"
    } else {
        if {$debug} {
            puts stderr "groff not found, copying man page content for $basename"
        }
        set cmd "cat tmp"
    }

    set g [open "|$cmd" r]
    set nl 0
    set lines 0
    while {[gets $g line] >= 0} {
        if {$line eq ""} {
            set nl 1
            continue
        }
        incr lines
        if {$nl} {
            puts $out ""
        }
        puts $out $line
        set nl 0
    }
    if {$nl} {
        puts $out ""
    }
    puts $out "\\$"

    close $g
    close $out

    if {$lines <= 0} {
        file delete -force $output
    }
}

# --- main ---
set ::env(GROFF_NO_SGR) 1
set debug 0
set args $argv
if {[llength $args] == 0} {
    usage
}
if {[string equal [lindex $args 0] "-debug"]} {
    set debug 1
    set args [lrange $args 1 end]
}
if {[llength $args] < 2} {
    usage
}
set macroFile [lindex $args 0]
set remaining [lrange $args 1 end]
set prefix ""
if {[string first "." [lindex $remaining 0]] == -1} {
    set prefix [lindex $remaining 0]
    set remaining [lrange $remaining 1 end]
}
if {[llength $remaining] == 0} {
    usage
}
set macros [readFile $macroFile]
set bkver [normalizeBkver [detectBkver]]
writeBkverMacro $bkver

foreach page $remaining {
    man2help $page $macros $prefix $bkver $debug
}

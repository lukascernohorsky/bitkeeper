#!/usr/bin/env tclsh

proc wordsplit str {
    set list {}
    set word ""
    foreach c [split $str ""] {
        if {[string is space -strict $c]} {
            if {[string length $word] > 0} {
                lappend list $word
                set word ""
            }
        } else {
            append word $c
        }
    }
    if {[string length $word] > 0} {
        lappend list $word
    }
    return $list
}

proc doit file {
    if {[catch {open $file rb} fh]} {
        return 0
    }
    fconfigure $fh -translation binary
    set n 0
    while {[gets $fh line] >= 0} {
        incr n [llength [wordsplit $line]]
    }
    close $fh
    return $n
}

set total 0
foreach path $argv {
    incr total [doit $path]
}
puts $total

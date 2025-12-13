#!/usr/bin/env tclsh
#
# Tcl translation of describe.l
# Emits a git-describe-style string using BitKeeper tags.

proc usage {} {
    puts stderr "bk release [--brief]"
    exit 1
}

set bk 0
set brief 0
set dirty 0

set idx 0
while {$idx < [llength $argv]} {
    set arg [lindex $argv $idx]
    switch -- $arg {
        --bk { set bk 1 }
        --brief { set brief 1 }
        --dirty { set dirty 1 }
        default { usage }
    }
    incr idx
}

if {[catch {exec bk repotype -q} repotype] || $repotype == 3} {
    exit 1
}

if {$bk} {
    if {[catch {exec bk changes -ar+ -nd:TAG:} tagList] == 0} {
        set firstTag [lindex [split [string trim $tagList]] 0]
        if {$firstTag ne "" && [regexp {^bk-[0-9.]+$} $firstTag]} {
            set brief 1
            set dirty 0
        } else {
            set brief 0
            set dirty 1
        }
    }
}

if {$dirty} {
    if {[catch {exec bk --sigpipe -cpxA} dirtyOut] == 0} {
        set dirty [expr {[string length $dirtyOut] > 0}]
    } else {
        set dirty 0
    }
}

set tagOutput [string trim [exec bk changes -t -1 -nd:TAG:]]
set tag [lindex [split $tagOutput] 0]
if {$tag ne ""} {
    set revLines [split [exec bk changes -er${tag}.. -nd:REV:] "\n"]
    set csets 0
    foreach line $revLines {
        if {[string trim $line] ne ""} { incr csets }
    }
} else {
    set tag "1.0"
    set revLines [split [exec bk changes -er.. -nd:REV:] "\n"]
    set csets 0
    foreach line $revLines {
        if {[string trim $line] ne ""} { incr csets }
    }
}

if {$csets > 0} {
    set tip [string trim [exec bk changes -r+ -nd:TIME_T:]]
    if {[info exists ::env(_BK_TIME_T)]} {
        set tip $::env(_BK_TIME_T)
    }
    puts -nonewline [format "%s+%d" $tag $csets]
    if {!$brief} {
        puts -nonewline [format "@0x%x" $tip]
    }
    puts [expr {$dirty ? "-dirty" : ""}]
} else {
    puts [format "%s%s" $tag [expr {$dirty ? "-dirty" : ""}]]
}

exit 0

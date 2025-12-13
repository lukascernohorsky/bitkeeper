#!/usr/bin/env tclsh

proc main {argv} {
    array set words {}
    foreach file $argv {
        if {[catch {open $file r} f]} continue
        while {[gets $f line] >= 0} {
            foreach token [regexp -all -inline {\S+} $line] {
                set words($token,$file) 1
            }
        }
        close $f
    }

    set tokens [lsort [unique_tokens [array names words]]]
    foreach tok $tokens {
        puts -nonewline $tok
        set files [lsort [files_for_token $tok [array names words]]]
        foreach f $files {
            set name $f
            regsub {^bk-} $name {} name
            regsub {-1\.fmt$} $name {} name
            puts -nonewline " $name"
        }
        puts ""
    }
}

proc unique_tokens {names} {
    array set seen {}
    set out {}
    foreach name $names {
        set tok [lindex [split $name ,] 0]
        if {[info exists seen($tok)]} continue
        set seen($tok) 1
        lappend out $tok
    }
    return $out
}

proc files_for_token {token names} {
    set out {}
    foreach name $names {
        if {![string match "${token},*" $name]} continue
        lappend out [lindex [split $name ,] 1]
    }
    return $out
}

main $argv

#!/usr/bin/env tclsh

proc main {} {
    if {[file executable "../src/bk"] || [file executable "../src/bk.exe"]} {
        set bkver [string trim [exec ../src/bk version -s]]
    } else {
        set bkver [string trim [exec bk version -s]]
    }

    if {[regexp {^(\d\d\d\d)(\d\d)(\d\d)} $bkver -> y m d]} {
        set bkver "$y-$m-$d"
    }

    puts $bkver
}

main

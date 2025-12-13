#!/usr/bin/env tclsh
#
# Tcl translation of check_comments.l
# Compares changeset comments between two repositories.

proc usage {prog} {
    puts stderr "usage: $prog repo [repo2]"
    exit 1
}

proc changeset_hashes {repo} {
    set mapping {}
    set output [split [exec bk changes -nd':MD5KEY: :CHASH:' $repo] "\n"]
    foreach line $output {
        if {[string trim $line] eq ""} continue
        set fields [split $line]
        if {[llength $fields] < 2} continue
        dict set mapping [lindex $fields 0] [lindex $fields 1]
    }
    return $mapping
}

if {[llength $argv] < 1} {
    usage [file tail [info script]]
}

set url1 [lindex $argv 0]
set url2 ""

set hashes [changeset_hashes $url1]

if {[llength $argv] > 1} {
    set url2 [lindex $argv 1]
} else {
    if {[catch {exec bk repotype -q} rtype] == 0} {
        switch -- $rtype {
            0 - 1 - 2 {
                catch {cd [exec bk root]}
            }
            default {
                usage [file tail [info script]]
            }
        }
    } else {
        usage [file tail [info script]]
    }
    set url2 "."
}

set bad {}
set output [split [exec bk changes -nd':MD5KEY: :CHASH:' $url2] "\n"]
foreach line $output {
    if {[string trim $line] eq ""} continue
    set fields [split $line]
    if {[llength $fields] < 2} continue
    set key [lindex $fields 0]
    set val [lindex $fields 1]
    if {[dict exists $hashes $key] && [dict get $hashes $key] ne $val} {
        lappend bad $key
    }
}

if {![llength $bad]} {
    exit 0
}

puts [format "Found %d non matching comments:" [llength $bad]]
foreach cs $bad {
    puts [format "Changeset %s" $cs]
    catch {exec bk changes -r$cs $url1}
    catch {exec bk changes -r$cs $url2}
}
exit 1

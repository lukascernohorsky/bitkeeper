#!/usr/bin/env tclsh
# Tcl replacement for build_upgrade_index.pl
# Generates upgrade INDEX entries from installer binaries and bk metadata

# platform alias mapping
set aliases {
    {x86-freebsd6 x86-freebsd6.0}
    {x86-sco x86-sco3 x86-sco3.2v5.0.7}
    {mips-glibc22-linux mips-glibc23-linux}
}

array set aliasmap {}
foreach lst $aliases {
    foreach arch $lst {
        set peers {}
        foreach peer $lst {
            if {$peer ne $arch} {
                lappend peers $peer
            }
        }
        set aliasmap($arch) $peers
    }
}

if {[llength $argv] < 2} {
    puts stderr "Usage: build_upgrade_index.tcl <version> <files...>"
    exit 1
}

set version [lindex $argv 0]
set files [lrange $argv 1 end]
set bkdir [file normalize [file join [file dirname [info script]] ..]]

if {[catch {exec bk prs -hd:UTC: -r$version [file join $bkdir ChangeSet]} utc]} {
    set utc ""
}
set utc [string trim $utc]
if {$utc eq ""} {
    puts stderr "Can't find version $version in $bkdir"
    exit 1
}

if {[catch {set out [open "INDEX" w]} err]} {
    puts stderr "Can't open INDEX file: $err"
    exit 1
}
set index $out
puts $index "# file,md5sum,ver,utc,platform,unused"

foreach file $files {
    set base [file tail $file]
    if {[catch {set md5sum [string trim [exec sh -c [format {bk crypto -h - < "%s"} $file]]]} err]} {
        puts stderr $err
        close $index
        exit 1
    }
    if {![regexp "^$version-([^\\.]+)" $base -> platform]} {
        puts stderr "Can't include $base, all images must be from $version"
        close $index
        exit 1
    }
    regsub {-setup$} $platform "" platform

    puts $index [join [list $base $md5sum $version $utc $platform bk] ","]
    if {[info exists aliasmap($platform)]} {
        foreach alt $aliasmap($platform) {
            puts $index [join [list $base $md5sum $version $utc $alt bk] ","]
        }
    }
}

set olddir [pwd]
if {[catch {cd $bkdir} err]} {
    puts stderr "Can't chdir to $bkdir: $err"
    close $index
    exit 1
}

if {[catch {set base [string trim [exec sh -c "bk r2c -r1.1 src/upgrade.c 2> /dev/null"]]}]} {
    puts stderr "Failed to determine base upgrade revision"
    cd $olddir
    close $index
    exit 1
}

if {[catch {set setout [exec sh -c [format {bk set -d -r%s -r%s -tt 2> /dev/null} $base $version]]} setout]} {
    set setout ""
}
if {$setout eq ""} {
    puts stderr "Failed to evaluate obsolete releases"
    cd $olddir
    close $index
    exit 1
}
array set obsoletes {}
foreach line [split $setout "\n"] {
    if {[string match "bk-*" $line]} {
        set obsoletes($line) 1
    }
}
cd $olddir

foreach tag [lsort [array names obsoletes]] {
    puts $index "old $tag"
}
puts $index "\n# checksum"
close $index

if {[catch {set sum [string trim [exec bk crypto -h - < INDEX]]} err]} {
    puts stderr $err
    exit 1
}
if {[catch {set out [open "INDEX" a]} err]} {
    puts stderr "Can't append to INDEX: $err"
    exit 1
}
puts $out $sum
close $out

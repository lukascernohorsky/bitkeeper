#!/usr/bin/env tclsh

if {[llength $argv] != 1} {
    puts stderr "usage: verify-dspecs.tcl <bk-log.1>"
    exit 1
}

set inFile [lindex $argv 0]
set tmpDir "/tmp"
if {[info exists ::env(TMP)] && $::env(TMP) ne ""} {
    set tmpDir $::env(TMP)
}
set pid [pid]
set definitive [file join $tmpDir "definitive_dspecs_${pid}"]
set links [file join $tmpDir "help_links_${pid}"]
set diffs [file join $tmpDir "diffs_${pid}"]

set inChan [open $inFile r]
set defChan [open $definitive w]
set linkChan [open $links w]

while {[gets $inChan line] >= 0} {
    if {[regexp {^\.xx} $line]} {
        if {[gets $inChan line2] < 0} {
            break
        }
        set line2 [string trimright $line2 "\r\n"]
        regsub {[ \t].*} $line2 {} line2
        puts $defChan $line2
    } elseif {[string match "*BEGIN dspecs help links*" $line]} {
        while {[gets $inChan linkLine] >= 0} {
            if {[string match "*END dspecs help links*" $linkLine]} {
                break
            }
            set linkLine [string trimright $linkLine "\r\n"]
            regsub {^.*help://} $linkLine {} linkLine
            puts $linkChan $linkLine
        }
    }
}

close $inChan
close $defChan
close $linkChan

set diffStatus 0
set diffOutput ""
if {[catch {exec diff $definitive $links > $diffs 2>@1} err]} {
    set diffStatus [lindex $::errorCode 2]
    if {$diffStatus eq ""} {
        # Non-childstatus error; rethrow for visibility.
        return -options $::errorOptions $err
    }
}

if {$diffStatus != 0} {
    set msg "KEYWORDS list and help:// links differ in bk-log.1:"\n
    append msg "diff $definitive $links"\n
    if {[file exists $diffs]} {
        set diffChan [open $diffs r]
        append msg [read $diffChan]
        close $diffChan
    }
    puts stderr $msg
    set exitCode 1
} else {
    set exitCode 0
}

foreach f [list $definitive $links $diffs] {
    if {[file exists $f]} {
        catch {file delete $f}
    }
}
exit $exitCode

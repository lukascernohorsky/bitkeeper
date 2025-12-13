#!/usr/bin/env tclsh
#
# Tcl translation of repocheck.l
# Runs repository checks (optionally in parallel) without Little.

set error 0
set verbose 1
set done 0
set total 0

proc usage {} {
    catch {exec bk help -s repocheck}
    exit 1
}

chan configure stdout -translation lf
chan configure stderr -translation lf

set checkopts [list -aBc]
set cold "--cold"
set parallel ""
set force 0
set standalone 0

set idx 0
while {$idx < [llength $argv]} {
    set arg [lindex $argv $idx]
    switch -glob -- $arg {
        --hot {
            set cold ""
        }
        -j - -j* {
            set val [string range $arg 2 end]
            if {$val eq ""} {
                incr idx
                if {$idx < [llength $argv]} { set val [lindex $argv $idx] }
            }
            if {$val ne ""} {
                set parallel $val
                set force 1
            }
        }
        --parallel {
            incr idx
            if {$idx < [llength $argv]} {
                set parallel [lindex $argv $idx]
                set force 1
            }
        }
        --parallel=* {
            set parallel [string range $arg 11 end]
            set force 1
        }
        -q {
            set verbose 0
        }
        -S {
            set standalone 1
        }
        --check-opts=* {
            set extra [string range $arg 13 end]
            foreach opt [split $extra] { lappend checkopts $opt }
        }
        default {
            if {[string match -* $arg]} {
                usage
            } else {
                set pathArg $arg
            }
        }
    }
    incr idx
}

if {[info exists pathArg]} {
    if {[catch {cd $pathArg}]} { puts stderr $pathArg; exit 1 }
}

catch {exec bk _feature_test}

if {[catch {exec bk repotype -q} rtype]} {
    puts stderr "repocheck: not in a repository"
    exit 1
}

switch -- $rtype {
    0 {
        catch {cd [exec bk root]}
    }
    1 {
        if {!$standalone} { catch {cd [exec bk root]} }
    }
    2 {
        set standalone 1
    }
    default {
        puts stderr "repocheck: not in a repository"
        exit 1
    }
}

if {$standalone} {
    set cmd [list bk]
    if {$cold ne ""} { lappend cmd $cold }
    lappend cmd -r check
    foreach opt $checkopts { lappend cmd $opt }
    if {$verbose} { lappend cmd -v }
    set status [catch {exec {*}$cmd} msg optsDict]
    if {$status} {
        puts stderr $msg
        if {[dict exists $optsDict -errorcode]} {
            set ec [dict get $optsDict -errorcode]
            if {[llength $ec] >= 3} { set error [lindex $ec 2] }
        }
    }
    exit $error
}

if {!$force} {
    set parallel [string trim [exec bk _parallel]]
}
if {$parallel eq ""} { set parallel 0 }

if {$parallel <= 1} {
    set cmd [list bk]
    if {$cold ne ""} { lappend cmd $cold }
    lappend cmd --each-repo -r check
    foreach opt $checkopts { lappend cmd $opt }
    if {$verbose} { lappend cmd -v }
    set status [catch {exec {*}$cmd} msg optsDict]
    if {$status} {
        puts stderr $msg
        if {[dict exists $optsDict -errorcode]} {
            set ec [dict get $optsDict -errorcode]
            if {[llength $ec] >= 3} { set error [lindex $ec 2] }
        }
    }
    exit $error
}

set comps [split [string trim [exec bk comps -h]] "\n"]
set ::env(BK_SFILES_WILLNEED) 1
set comps [linsert $comps 0 "."]
set total [llength $comps]

foreach comp $comps {
    if {$comp eq ""} continue
    set entry [launch_check $comp $cold $checkopts]
    process_entry $entry
}
exit $error

proc launch_check {comp cold checkopts} {
    set buf $comp
    set buf [string map {"/" "."} $buf]
    set errout "BitKeeper/tmp/${buf}.errors"
    set cmd [list bk --cd=$comp]
    if {$cold ne ""} { lappend cmd $cold }
    lappend cmd -r check --parallel
    foreach opt $checkopts { lappend cmd $opt }
    set status [catch {exec {*}$cmd 2>$errout} msg opts]
    return [list $comp $errout $status $msg $opts]
}

proc process_entry {entry} {
    lassign $entry comp errout status msg opts
    incr ::done
    if {$status} {
        handle_failure $comp $errout $msg $opts
    } else {
        report_success $comp $errout
    }
}

proc handle_failure {comp errout msg opts} {
    global error verbose done total
    set code 0
    if {[dict exists $opts -errorcode]} {
        set ec [dict get $opts -errorcode]
        if {[llength $ec] >= 3 && [lindex $ec 0] eq "CHILDKILLED"} {
            set code 250
            puts stderr [format "check in %s killed with signal %s" $comp [lindex $ec 2]]
        } elseif {[llength $ec] >= 3 && [lindex $ec 0] eq "CHILDSTATUS"} {
            set code [lindex $ec 2]
            puts stderr [format "check in '%s' exited %d, error output:" $comp $code]
        }
    }
    if {$code > 0} { set error $code }
    if {[file exists $errout]} {
        set f [open $errout r]
        puts -nonewline stderr [read $f]
        close $f
        file delete -force $errout
    }
    if {$verbose} { puts stderr [format "%4d/%d %-60s OK" $done $total $comp] }
}

proc report_success {comp errout} {
    global verbose done total
    if {[file exists $errout]} { file delete -force $errout }
    if {$verbose} { puts stderr [format "%4d/%d %-60s OK" $done $total $comp] }
}

#!/usr/bin/env tclsh
# Tcl rewrite of synth.l: generate a synthetic sfile graph
# preserving CLI and output formatting for regression tests.

proc usage {} {
    puts stderr "usage: synth.l [-q][-s<size>] file"
    exit 1
}

proc squaredist {lower upper} {
    set span [expr {$upper + 1 - $lower}]
    set span [expr {$span * $span}]
    set x [expr {int(sqrt(rand() * $span))}]
    return [expr {$x + $lower}]
}

proc graph_get {table idx key} {
    dict get [dict get $table $idx] $key
}

proc graph_set {table idx key value} {
    set graph [dict get $table $idx]
    dict set graph $key $value
    dict set table $idx $graph
    return $table
}

proc closedsize {table parent merge} {
    if {$parent == $merge} {
        return [list [graph_get $table $parent size] $table]
    }

    if {$parent > $merge} {
        set start $parent
        set table [graph_set $table $merge blue 1]
        set size [graph_get $table $merge size]
        set lowest [graph_get $table $merge serial]
    } else {
        set start $merge
        set table [graph_set $table $parent blue 1]
        set size [graph_get $table $parent size]
        set lowest [graph_get $table $parent serial]
    }
    set table [graph_set $table $start red 1]
    set marked 1

    while {$start && $marked} {
        set graph [dict get $table $start]
        set red [dict get $graph red]
        set blue [dict get $graph blue]
        if {!$red && !$blue} {
            incr start -1
            continue
        }
        if {$red && !$blue} {
            incr size
            incr marked -1
        }
        if {[dict get $graph parent]} {
            set pIdx [dict get $graph parent]
            set pGraph [dict get $table $pIdx]
            set pRed [dict get $pGraph red]
            set pBlue [dict get $pGraph blue]
            if {$pRed && !$pBlue} { incr marked -1 }
            if {$red} { set pRed 1 }
            if {$blue} { set pBlue 1 }
            if {$pRed && !$pBlue} { incr marked }
            if {[dict get $pGraph serial] < $lowest} {
                set lowest [dict get $pGraph serial]
            }
            dict set pGraph red $pRed
            dict set pGraph blue $pBlue
            dict set table $pIdx $pGraph
        }
        if {[dict get $graph merge]} {
            set mIdx [dict get $graph merge]
            set mGraph [dict get $table $mIdx]
            set mRed [dict get $mGraph red]
            set mBlue [dict get $mGraph blue]
            if {$mRed && !$mBlue} { incr marked -1 }
            if {$red} { set mRed 1 }
            if {$blue} { set mBlue 1 }
            if {$mRed && !$mBlue} { incr marked }
            if {[dict get $mGraph serial] < $lowest} {
                set lowest [dict get $mGraph serial]
            }
            dict set mGraph red $mRed
            dict set mGraph blue $mBlue
            dict set table $mIdx $mGraph
        }
        dict set graph red 0
        dict set graph blue 0
        dict set table $start $graph
        incr start -1
    }

    while {$start >= $lowest} {
        set graph [dict get $table $start]
        dict set graph red 0
        dict set graph blue 0
        dict set table $start $graph
        incr start -1
    }
    return [list $size $table]
}

proc mkGraph {size} {
    set table [dict create]
    if {$size == 0} {
        return $table
    }

    dict set table 1 [dict create serial 1 size 1 parent 0 merge 0 include {} exclude {} red 0 blue 0]
    set tips [dict create 1 1]
    set numtips 1

    for {set i 2} {$i <= $size} {incr i} {
        set graph [dict create serial $i size 0 parent 0 merge 0 include {} exclude {} red 0 blue 0]
        if {$size - $i + 2 <= $numtips} {
            foreach x [dict keys $tips] {
                if {[dict get $tips $x]} {
                    dict set graph parent $x
                    dict unset tips $x
                    incr numtips -1
                    break
                }
            }
        } else {
            dict set graph parent [squaredist 1 [expr {$i - 1}]]
        }

        if {$size - $i + 1 == $numtips} {
            foreach x [dict keys $tips] {
                if {[dict get $tips $x]} {
                    dict set graph merge $x
                    dict unset tips $x
                    incr numtips -1
                    break
                }
            }
        } else {
            if {[expr {rand()}] > 0.5} {
                dict set graph merge [squaredist 1 [expr {$i - 1}]]
            } else {
                dict set graph merge 0
            }
        }

        set parent [dict get $graph parent]
        if {[dict exists $tips $parent]} {
            dict unset tips $parent
            incr numtips -1
        }
        set merge [dict get $graph merge]
        if {$merge} {
            if {[dict exists $tips $merge]} {
                dict unset tips $merge
                incr numtips -1
            }
            lassign [closedsize $table $parent $merge] closed table
            dict set graph size [expr {1 + $closed}]
        } else {
            dict set graph size [expr {[graph_get $table $parent size] + 1}]
        }

        set count [expr {int(rand() * 10 + 1)}]
        set include {}
        for {set n 0} {$n < $count} {incr n} {
            lappend include [squaredist 1 [expr {$i - 1}]]
        }
        set count [expr {int(rand() * 10 + 1)}]
        set exclude {}
        for {set n 0} {$n < $count} {incr n} {
            lappend exclude [squaredist 1 [expr {$i - 1}]]
        }

        dict set graph include $include
        dict set graph exclude $exclude

        dict set tips $i 1
        incr numtips

        dict set table $i $graph
    }
    return $table
}

proc bkify {table size} {
    for {set i 2} {$i <= $size} {incr i} {
        set graph [dict get $table $i]
        set parent [dict get $graph parent]
        set merge [dict get $graph merge]
        set gsize [dict get $graph size]

        if {$parent == $merge} {
            set merge 0
        }
        if {$merge} {
            if {$parent > $merge} {
                if {$gsize == ([dict get $table $parent size] + 1)} {
                    # size equals parent closure+1 implies merge not needed
                    set merge 0
                }
            } else {
                if {$gsize == ([dict get $table $merge size] + 1)} {
                    set parent $merge
                    set merge 0
                }
            }
        }

        if {$merge} {
            set p $parent
            set m $merge
            while {$p != $m} {
                if {$p > $m} {
                    set p [dict get $table $p parent]
                } else {
                    set m [dict get $table $m parent]
                    if {$p == $m} {
                        set swap $parent
                        set parent $merge
                        set merge $swap
                    }
                }
            }
        }

        set include [lsort -integer -decreasing [dict get $graph include]]
        set seen {}
        foreach x $include { dict set seen $x 1 }
        set filtered {}
        foreach x [lsort -integer -decreasing [dict get $graph exclude]] {
            if {![dict exists $seen $x]} {
                lappend filtered $x
            }
        }

        dict set graph parent $parent
        dict set graph merge $merge
        dict set graph include $include
        dict set graph exclude $filtered
        dict set table $i $graph
    }
    return $table
}

proc mkSfile {table size file} {
    set base 1330218616
    set format "%Y%m%d%H%M%S %y/%m/%d %H:%M:%S"
    set ctrl [format "%c" 1]

    puts -nonewline stdout [format "%sH12345\n" $ctrl]

    for {set d $size} {$d >= 1} {incr d -1} {
        set graph [dict get $table $d]
        puts -nonewline stdout [format "%ss 1/0/1\n" $ctrl]
        set time [expr {$base + $d}]
        set date [clock format $time -format $format]
        set parts [split $date " "]
        set kd [lindex $parts 0]
        set hd [lindex $parts 1]
        puts -nonewline stdout [format "%sd D %s %s bk %d %d\n" $ctrl "1.2" $hd $d [dict get $graph parent]]
        if {[llength [dict get $graph include]]} {
            puts -nonewline stdout [format "%si %s\n" $ctrl [join [dict get $graph include] " "]]
        }
        if {[llength [dict get $graph exclude]]} {
            puts -nonewline stdout [format "%sx %s\n" $ctrl [join [dict get $graph exclude] " "]]
        }
        puts -nonewline stdout [format "%sK00000\n" $ctrl]
        if {[dict get $graph merge]} {
            puts -nonewline stdout [format "%sM%d\n" $ctrl [dict get $graph merge]]
        }
        puts -nonewline stdout [format "%se\n" $ctrl]
    }

    puts -nonewline stdout [format "%ss 1/0/0\n" $ctrl]
    puts -nonewline stdout [format "%sd D 1.1 04/06/27 16:07:39 bk 2 1\n" $ctrl]
    puts -nonewline stdout [format "%sc Initial repository create\n" $ctrl]
    puts -nonewline stdout [format "%sF1\n" $ctrl]
    puts -nonewline stdout [format "%sK00000\n" $ctrl]
    puts -nonewline stdout [format "%se\n" $ctrl]
    puts -nonewline stdout [format "%ss 0/0/0\n" $ctrl]
    puts -nonewline stdout [format "%sd D 1.0 04/06/27 16:07:39 bk 1 0\n" $ctrl]
    puts -nonewline stdout [format "%sc BitKeeper file /home/bk/stubrepo/ChangeSet\n" $ctrl]
    puts -nonewline stdout [format "%sBbk@bitkeeper.com|ChangeSet|20040627230739|04490|80744df6d363a810\n" $ctrl]
    puts -nonewline stdout [format "%sHbitkeeper.com\n" $ctrl]
    puts -nonewline stdout [format "%sK04490\n" $ctrl]
    puts -nonewline stdout [format "%sP%s\n" $ctrl $file]
    puts -nonewline stdout [format "%sR80744df6d363a810\n" $ctrl]
    puts -nonewline stdout [format "%sV4\n" $ctrl]
    puts -nonewline stdout [format "%sX0x21\n" $ctrl]
    puts -nonewline stdout [format "%sZ-07:00\n" $ctrl]
    puts -nonewline stdout [format "%se\n" $ctrl]

    puts -nonewline stdout [format "%su\n" $ctrl]
    puts -nonewline stdout [format "%sU\n" $ctrl]
    puts -nonewline stdout [format "%sf e %u\n" $ctrl 64]
    puts -nonewline stdout [format "%sf x 0x21\n" $ctrl]
    puts -nonewline stdout [format "%st\n" $ctrl]
    puts -nonewline stdout [format "%sT\n" $ctrl]
    for {set d $size} {$d > 2} {incr d -1} {
        puts -nonewline stdout [format "%sI %d\n" $ctrl $d]
        puts -nonewline stdout [format "%d\n" $d]
        puts -nonewline stdout [format "%sE %d\n" $ctrl $d]
    }
    puts -nonewline stdout [format "%sI 1\n" $ctrl]
    puts -nonewline stdout [format "%sE 1\n" $ctrl]
}

proc main {argv} {
    set quiet 0
    set size 100
    set file ""

    while {[llength $argv]} {
        set arg [lindex $argv 0]
        set argv [lrange $argv 1 end]
        switch -glob -- $arg {
            -q {
                set quiet 1
            }
            -s {
                if {![llength $argv]} { usage }
                set size [lindex $argv 0]
                set argv [lrange $argv 1 end]
            }
            -s* {
                set size [string range $arg 2 end]
                if {$size eq ""} { usage }
            }
            -* {
                usage
            }
            default {
                set file $arg
                break
            }
        }
    }

    if {$file eq ""} { usage }
    if {[catch {set size [expr {int($size)}]}]} { usage }

    set table [mkGraph $size]
    set table [bkify $table $size]
    mkSfile $table $size $file
    if {$quiet} {
        # Quiet flag retained for compatibility; no extra chatter in Tcl.
    }
}

main $argv

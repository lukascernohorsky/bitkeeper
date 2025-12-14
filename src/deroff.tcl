#!/usr/bin/env tclsh
# Tcl rewrite of deroff.pl

set ignore 0
set sa ""
set format 1
set formatcountdown -1
set lineList {}

set outFile "/tmp/deroff_[pid]"
set outChan [open $outFile w]

proc getargs {str} {
    set chars [split $str {}]
    set args {}
    set arg ""
    set quote 0
    set bs 0
    foreach c $chars {
        if {$bs} {
            set bs 0
            if {[regexp {\s} $c]} {
                append arg $c
                continue
            } else {
                append arg "\\"
            }
        }
        if {$c eq {"}} {
            if {$quote} {
                lappend args $arg
                set arg ""
                set quote 0
            } else {
                set quote 1
            }
            continue
        } elseif {$quote} {
            append arg $c
        } elseif {[regexp {\s} $c]} {
            if {$arg ne ""} {
                lappend args $arg
                set arg ""
            }
        } elseif {$c eq "\\"} {
            set bs 1
        } else {
            append arg $c
        }
    }
    if {$arg ne ""} {
        lappend args $arg
    }
    return $args
}

proc shouldBreak {w} {
    if {[regexp {^.\.$} $w]} { return 0 }
    if {[regexp {^\.\.\.$} $w]} { return 0 }
    if {[regexp -nocase {^mr\.$} $w]} { return 0 }
    if {[regexp -nocase {^ms\.$} $w]} { return 0 }
    return 1
}

proc flush {} {
    global lineList outChan
    if {[llength $lineList] == 0} {
        return
    }
    set len 0
    set cont 0
    foreach w $lineList {
        if {$len > 0 && $len + [string length $w] > 65} {
            puts $outChan ""
            set len 0
        }
        if {$len} {
            if {!$cont} {
                puts -nonewline $outChan " "
                incr len
            } else {
                set cont 0
            }
        }
        if {[string match {*\\c} $w]} {
            set w [string range $w 0 end-2]
            set cont 1
        }
        puts -nonewline $outChan $w
        incr len [string length $w]
    }
    if {$len} {
        puts $outChan ""
    }
    set lineList {}
}

proc fmt {str} {
    global lineList outChan
    if {$str eq ""} {
        flush
        puts $outChan ""
        return
    }
    set words [split $str]
    set count [llength $words]
    for {set i 0} {$i < $count} {incr i} {
        set w [lindex $words $i]
        lappend lineList $w
        if {[regexp {[.!?]$} $w] && [shouldBreak $w]} {
            flush
            continue
        }
        if {[string match {*;} $w]} {
            if {!(($i < ($count - 1)) && ([lindex $words [expr {$i + 1}]] in {or and}))} {
                flush
            }
        }
    }
}

set files [expr {[llength $argv] ? $argv : {"-"}}]
foreach f $files {
    if {$f eq "-"} {
        set chan stdin
    } else {
        set chan [open $f r]
    }
    while {[gets $chan line] >= 0} {
        set line [string trimright $line "\n"]

        if {[regexp {^\.\s*\.} $line]} {
            set ignore 0
            continue
        } elseif {$ignore} {
            continue
        } elseif {[regexp {^\.\s*(ig|de)} $line]} {
            set ignore 1
            continue
        }

        if {[regexp {^\.\s*SA\s*} $line]} {
            set line [regsub {^\.\s*SA\s*} $line ""]
            set line [string trim $line]
            if {$sa ne ""} {
                append sa ", bk $line"
            } else {
                set sa "bk $line"
            }
            continue
        } else {
            if {$sa ne ""} {
                fmt "$sa."
                set sa ""
            }
        }

        regsub -all {\\\|} $line "" line
        regsub -all {\\-} $line "-" line
        regsub -all {\\<} $line "<" line
        regsub -all {\\>} $line ">" line
        regsub -all {\\\*<} $line "<" line
        regsub -all {\\\*>} $line ">" line
        regsub -all {\\\*\[<]} $line "<" line
        regsub -all {\\\*\[>]} $line ">" line
        regsub -all {\\er} $line {\r} line
        regsub -all {\\en} $line {\n} line
        regsub -all {\\\*\(lq} $line {"} line
        regsub -all {\\\*\(rq} $line {"} line
        regsub -all {\\fB} $line "" line
        regsub -all {\\fI} $line "" line
        regsub -all {\\fP} $line "" line
        regsub -all {\\fR} $line "" line
        regsub -all {\\f\(CB} $line "" line
        regsub -all {\\f\[CB]} $line "" line
        regsub -all {\\f\(CW} $line "" line
        regsub -all {\\f\[CW]} $line "" line
        regsub -all {\\s+[0-9]} $line "" line
        regsub -all {\\s-[0-9]} $line "" line
        regsub -all {\\s0} $line "" line
        regsub -all {\\\(em} $line {--} line
        regsub -all {\\\*\(BK} $line {BitKeeper} line
        regsub -all {\\\*\[BK]} $line {BitKeeper} line
        regsub -all {\\\*\(BM} $line {BitMover} line
        regsub -all {\\\*\[BM]} $line {BitMover} line
        regsub -all {\\\*\[ATT]} $line {AT&T SCCS} line
        regsub -all {\\\*\(UN} $line {UNIX} line
        regsub -all {\\\*\[UN]} $line {UNIX} line
        regsub -all {\\\*\[UNIX]} $line {UNIX} line
        regsub -all {\\\*\(R} $line {RCS} line
        regsub -all {\\\*\[R]} $line {RCS} line
        regsub -all {\\\*\(SC} $line {SCCS} line
        regsub -all {\\\*\[SC]} $line {SCCS} line
        regsub -all {\\\*\(CV} $line {CVS} line
        regsub -all {\\\*\[CV]} $line {CVS} line

        if {[regexp {^\.\s*(?:\\"|Id|TH|\}|_SA|ad|box|ce|ds|fi|ft|hy|if|in|ne|nh|nr|ns|so|sp|ta|ti|xx)} $line]} {
            continue
        }

        if {[regexp {^\.\s*(LP|PP|RS|RE|SP|Sp|br|head)} $line]} {
            set line ""
            flush
        }

        if {[regexp {^\.\s*(CS|DS|FS|GS|TS|WS|nf)} $line]} {
            set line "\n"
            set format 0
            flush
        }

        if {[regexp {^\.\s*(CE|DE|FE|GE|TE|WE|fi)} $line]} {
            set line ""
            set format 1
        }

        set matched 0
        if {[regexp {^\.\s*Bc\s*} $line]} {
            set line [regsub {^\.\s*Bc\s*} $line ""]
            set args [getargs $line]
            set line "[lindex $args 0][lindex $args 1]\\c"
            set matched 1
        }
        if {!$matched && [regexp {^\.\s*Ic\s*} $line]} {
            set line [regsub {^\.\s*Ic\s*} $line ""]
            set args [getargs $line]
            set line "[lindex $args 0][lindex $args 1]\\c"
        }

        if {[regexp {^\.\s*ARGc\s*} $line]} {
            set line [regsub {^\.\s*ARGc\s*} $line ""]
            set args [getargs $line]
            set line "<[lindex $args 0]>[lindex $args 1]\\c"
        }

        if {[regexp {^\.\s*(BI|BR|IB|IP|IR|CR|RB|RI|V)\s*} $line]} {
            set line [regsub {^\.\s*(BI|BR|IB|IP|IR|CR|RB|RI|V)\s*} $line ""]
            set args [getargs $line]
            set line "[lindex $args 0][lindex $args 1]\n"
        }

        if {[regexp {^\.\s*ARG\s*} $line]} {
            set line [regsub {^\.\s*ARG\s*} $line ""]
            set args [getargs $line]
            set line "<[lindex $args 0]>[lindex $args 1]\n"
        }

        if {[regexp {^\.\s*(QI|QR)\s*} $line]} {
            set line [regsub {^\.\s*(QI|QR)\s*} $line ""]
            set args [getargs $line]
            set line "\"[lindex $args 0]\"[lindex $args 1]\n"
        }

        if {[regexp {^\.\s*Qreq\s*} $line]} {
            set line [regsub {^\.\s*Qreq\s*} $line ""]
            set args [getargs $line]
            set line "\"[lindex $args 0]<[lindex $args 1]>\"\n"
        }

        if {[regexp {^\.\s*OPTequal\s*} $line]} {
            set line [regsub {^\.\s*OPTequal\s*} $line ""]
            set args [getargs $line]
            set line "[lindex $args 0]<[lindex $args 1]>=<[lindex $args 2]>\n"
        }
        if {[regexp {^\.\s*OPTopt\s*} $line]} {
            set line [regsub {^\.\s*OPTopt\s*} $line ""]
            set args [getargs $line]
            set line "[lindex $args 0]\[<[lindex $args 1>]\]\n"
        }
        if {[regexp {^\.\s*OPTreq\s*} $line]} {
            set line [regsub {^\.\s*OPTreq\s*} $line ""]
            set args [getargs $line]
            set line "[lindex $args 0]<[lindex $args 1]>[lindex $args 2]\n"
        }

        if {[regexp {^\.\s*\[ARGc]\s*} $line]} {
            set line [regsub {^\.\s*\[ARGc]\s*} $line ""]
            set args [getargs $line]
            set line "\[<[lindex $args 0]>[lindex $args 1]]\\c"
        }

        if {[regexp {^\.\s*\[ARG]\s*} $line]} {
            set line [regsub {^\.\s*\[ARG]\s*} $line ""]
            set args [getargs $line]
            set line "\[<[lindex $args 0]>[lindex $args 1]]\n"
        }
        regsub {^\.\s*\[B]\s*(.*)} $line {[\1]} line

        if {[regexp {^\.\s*\[OPTequal]\s*} $line]} {
            set line [regsub {^\.\s*\[OPTequal]\s*} $line ""]
            set args [getargs $line]
            set line "\[[lindex $args 0]<[lindex $args 1]>=<[lindex $args 2>]]\n"
        }
        if {[regexp {^\.\s*\[OPTopt]\s*} $line]} {
            set line [regsub {^\.\s*\[OPTopt]\s*} $line ""]
            set args [getargs $line]
            set line "\[[lindex $args 0]\[<[lindex $args 1>]]]\n"
        }
        if {[regexp {^\.\s*\[OPTreq]\s*} $line]} {
            set line [regsub {^\.\s*\[OPTreq]\s*} $line ""]
            set args [getargs $line]
            set line "\[[lindex $args 0]<[lindex $args 1]>[lindex $args 2]]\n"
        }

        regsub {^\.\s*BKARGS\s*} $line {[file ... | -]} line
        regsub {^\.\s*FILESreq\s*} $line {file [file ...]} line
        regsub {^\.\s*FILES\s*} $line {[file ...]} line

        if {[regexp {^\.\s*LI\s*} $line]} {
            set line "=>  "
            flush
            puts $outChan ""
        }

        if {[regexp {^\.\s*li\s*} $line]} {
            set line "=>  "
            flush
        }

        if {[regexp {^\.\s*(TP|tp)} $line]} {
            set line "\n"
            set format 0
            set formatcountdown 1
            flush
        }

        if {[regexp {^\.\s*EV\s*} $line]} {
            set line [regsub {^\.\s*EV\s*} $line ""]
            set line "\n$line"
            set format 0
            set formatcountdown 0
            flush
        }

        regsub {^\.\s*B\s*} $line "" line
        regsub {^\.\s*C\s*} $line "" line
        regsub {^\.\s*I\s*} $line "" line
        regsub {^\.\s*SB\s*} $line "" line
        regsub {^\.\s*SM\s*} $line "" line

        regsub {^\.\s*Q\s*(.*)} $line {"\1"} line

        if {[regexp {^\.\s*(SH|SS)\s*} $line]} {
            regsub -all {\"} $line "" line
            set line "\n$line"
            set format 0
            set formatcountdown 0
            flush
        }

        regsub -all {\\ } $line { } line

        if {$format} {
            fmt $line
        } else {
            puts -nonewline $outChan "$line\n"
            if {$formatcountdown == 0} {
                set format 1
                set formatcountdown -1
            } elseif {$formatcountdown > 0} {
                incr formatcountdown -1
            }
        }
    }
    if {$chan ne "stdin"} {
        close $chan
    }
}

flush
close $outChan

set inChan [open $outFile r]
set blank 0
while {[gets $inChan l] >= 0} {
    if {![regexp {^$} $l]} {
        if {$blank} { set blank 0 }
    } elseif {$blank} {
        continue
    } else {
        set blank 1
    }
    puts $l
}
close $inChan
file delete $outFile

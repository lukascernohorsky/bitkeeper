#!/usr/bin/env tclsh

# Tcl rewrite of outputtool.l

proc usage {} {
    puts stderr "usage: outputtool [-t title|--title title] [-w|--wait] command..."
    exit 1
}

if {[catch {package require Tk} err]} {
    puts stderr $err
    exit 1
}

proc read_output {wait} {
    global fp

    if {[eof $fp]} {
        close $fp
        unset fp
        .close configure -state normal
        after 20000 [list quit $wait]
        return
    }

    set output ""
    read $fp output

    set y [lindex [.text yview] 1]
    .text insert end $output
    if {$y == 1.0} {
        .text yview moveto 1.0
    }
    update idletasks
}

proc quit {wait} {
    global fp

    if {[info exists fp] && $wait} {
        tk_messageBox -title "Still Running" -parent . \
            -message "Cannot cancel command while running"
        return
    }
    exit
}

proc main {argv} {
    set wait 0
    set title ""
    set cmd {}

    set idx 0
    while {$idx < [llength $argv]} {
        set arg [lindex $argv $idx]
        switch -- $arg {
            -t --title {
                incr idx
                if {$idx >= [llength $argv]} { usage }
                set title [lindex $argv $idx]
            }
            -w --wait {
                set wait 1
            }
            -- {
                set cmd [lrange $argv [expr {$idx + 1}] end]
                break
            }
            default {
                if {[string match -* $arg]} {
                    usage
                }
                set cmd [lrange $argv $idx end]
                break
            }
        }
        incr idx
    }

    if {[llength $cmd] == 0} { exit }
    if {$title eq ""} {
        set title [join $cmd " "]
    }

    wm title . $title
    wm protocol . WM_DELETE_WINDOW [list quit $wait]
    if {[tk windowingsystem] eq "aqua"} {
        . configure -background systemSheetBackground
    }

    text .text -xscrollcommand {.hs set} -yscrollcommand {.vs set}
    bindtags .text {.text all}
    grid .text -row 0 -column 0 -sticky nesw

    ttk::scrollbar .vs -orient vertical -command {.text yview}
    grid .vs -row 0 -column 1 -sticky ns

    ttk::scrollbar .hs -orient horizontal -command {.text xview}
    grid .hs -row 1 -column 0 -sticky ew

    ttk::button .close -text "Done" -command [list quit $wait] \
        -state [expr {$wait ? "disabled" : "normal"}]
    grid .close -row 2 -column 0 -columnspan 2 -sticky se -padx 5 -pady {5 10}

    wm deiconify .
    update

    set cmdline [join [concat $cmd {2>@1}] " "]
    if {[catch {open "|$cmdline" r} fp]} {
        puts stderr $fp
        exit 1
    }
    fconfigure $fp -buffering none -blocking 0
    fileevent $fp readable [list read_output $wait]
}

main $argv

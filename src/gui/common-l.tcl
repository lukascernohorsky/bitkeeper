#!/usr/bin/env tclsh
# Tcl translation of common.l

# Global state mirroring the original L struct
array set _bk {
    wm ""
    tool ""
    cmd_quit exit
    cmd_next ""
    cmd_prev ""
    w_top ""
    w_main ""
    w_search ""
    w_searchBar ""
    search_case 0
    search_idx {1.0 1.0}
    search_highlight 0
    w_scrollbars {}
}

set _bk(wm) [tk windowingsystem]

proc bgExecInfo {opt} {
    if {[info exists ::bgExec($opt)]} {
        return [set ::bgExec($opt)]
    }
    return ""
}

proc bk_init {} {
    global _bk
    if {$::_bk(tool) eq ""} {
        bk_dieError "_bk.tool must be set before bk_init()" 1
    }
    if {$::_bk(w_top) eq ""} {
        bk_dieError "_bk.w_top must be set before bk_init()" 1
    }
    bk_initPlatform
    bk_initTheme
    loadState $::_bk(tool)
    getConfig $::_bk(tool)
}

proc bk_initGui {} {
    global _bk
    restoreGeometry $::_bk(tool) $::_bk(w_top)
    wm protocol $::_bk(w_top) WM_DELETE_WINDOW $::_bk(cmd_quit)
    wm deiconify $::_bk(w_top)
    bk_initSearch
    bk_initBindings
}

proc bk_initBindings {} {
    global _bk
    set quit [gc quit]
    foreach w [getAllWidgets $::_bk(w_top)] {
        set tags [bindtags $w]
        bindtags $w [linsert $tags 0 BK]
    }
    if {$::_bk(wm) eq "aqua"} {
        bind BK <Control-p> "$::_bk(cmd_prev); break"
        bind BK <Control-n> "$::_bk(cmd_next); break"
        bind BK <Command-q> "$::_bk(cmd_quit); break"
        bind BK <Command-w> "$::_bk(cmd_quit); break"
        Event_add <<Redo>> <Command-Shift-z> <Command-Shift-Z>
    } else {
        bind BK <Control-p> "$::_bk(cmd_prev); break"
        bind BK <Control-n> "$::_bk(cmd_next); break"
        bind BK <Control-q> "$::_bk(cmd_quit); break"
    }
    set w $::_bk(w_main)
    bind BK <Control-b> "$w yview scroll -1 pages; break"
    bind BK <Control-e> "$w yview scroll 1 units; break"
    bind BK <Control-f> "$w yview scroll 1 pages; break"
    bind BK <Control-y> "$w yview scroll -1 units; break"
    bind BK <${quit}> $::_bk(cmd_quit)
    if {$::_bk(wm) eq "x11"} {
        bind BK <4> {scrollMouseWheel %W y %X %Y -1; break}
        bind BK <5> {scrollMouseWheel %W y %X %Y 1; break}
        bind BK <Shift-4> {scrollMouseWheel %W x %X %Y -1; break}
        bind BK <Shift-5> {scrollMouseWheel %W x %X %Y 1; break}
    } else {
        bind BK <MouseWheel> {scrollMouseWheel %W y %X %Y %D; break}
        bind BK <Shift-MouseWheel> {scrollMouseWheel %W x %X %Y %D; break}
    }
    if {$::_bk(wm) eq "aqua"} {
        eval {proc ::tk::mac::Quit {} {{$::_bk(cmd_quit)}}}
    }
}

proc bk_exit {args} {
    global _bk
    saveState $::_bk(tool)
    set exitCode 0
    if {[llength $args] == 1} {
        set exitCode [lindex $args 0]
    } elseif {[llength $args] == 2} {
        set exitCode [lindex $args 1]
        if {$exitCode == 0} {
            bk_die [lindex $args 0] $exitCode
        } else {
            bk_dieError [lindex $args 0] $exitCode
        }
    }
    exit $exitCode
}

set _lockurl ""

proc bk_lock {} {
    global _bk _lockurl
    if {$::_lockurl ne ""} {return 1}
    set out ""
    set err ""
    set rc [catch {bk_system "bk lock -r -t --name=${::_bk(tool)}tool"} out]
    if {$rc} {return 0}
    if {$out eq ""} {return 0}
    set ::_lockurl [string trim $out]
    return 1
}

proc bk_unlock {} {
    global _lockurl
    if {$::_lockurl ne ""} {
        catch {bk_system "bk _kill '${::_lockurl}'"}
    }
    set ::_lockurl ""
}

proc bk_locklist {} {
    set err ""
    catch {exec bk lock -l} err
    return $err
}

proc unlockOnExit {args} {
    bk_unlock
}
trace add execution exit enter unlockOnExit

proc getAllWidgets {top} {
    set list {}
    foreach w [winfo children $top] {
        lappend list $w
        foreach child [getAllWidgets $w] {
            lappend list $child
        }
    }
    return $list
}

proc attachScrollbar {sb args} {
    global _bk
    set orient [Scrollbar_cget $sb orient:]
    set widgets $args
    if {$orient eq "horizontal"} {
        Scrollbar_configure $sb command: "[lindex $widgets 0] xview"
        foreach widg $widgets {
            set _bk(w_scrollbars) [dict set _bk(w_scrollbars) $widg $widgets]
            Widget_configure $widg xscrollcommand: "setScrollbar ${sb} ${widg}"
        }
    } else {
        Scrollbar_configure $sb command: "[lindex $widgets 0] yview"
        foreach widg $widgets {
            set _bk(w_scrollbars) [dict set _bk(w_scrollbars) $widg $widgets]
            Widget_configure $widg yscrollcommand: "setScrollbar ${sb} ${widg}"
        }
    }
}

proc setScrollbar {sb w first last} {
    global _bk
    Scrollbar_set $sb $first $last
    if {![dict exists $::_bk(w_scrollbars) $w]} {return}
    set widgets [dict get $::_bk(w_scrollbars) $w]
    set xview [Widget_xview $w]
    set yview [Widget_yview $w]
    set x [lindex $xview 0]
    set y [lindex $yview 0]
    foreach widg $widgets {
        if {$widg eq $w} {continue}
        Widget_xview $widg moveto $x
        Widget_yview $widg moveto $y
    }
}

proc scrollMouseWheel {w dir x y delta} {
    global _bk
    set d $delta
    set widg [Winfo_containing $x $y]
    if {$widg eq ""} {set widg $w}
    if {$::_bk(wm) eq "aqua"} {
        set d [expr {-$delta}]
    } elseif {$::_bk(wm) eq "x11"} {
        set d [expr {$delta * 3}]
    } elseif {$::_bk(wm) eq "win32"} {
        set d [expr {($delta / 120) * -3}]
    }
    if {[catch {
        if {$dir eq "x"} {
            Widget_xviewScroll $widg $d units
        } else {
            Widget_yviewScroll $widg $d units
        }
    }]} {
        catch {
            if {$dir eq "x"} {
                Widget_xviewScroll $w $d units
            } else {
                Widget_yviewScroll $w $d units
            }
        }
    }
}

proc scrollTextY {w i what} {
    if {$i != -1 && $i != 1 && ($what eq "page" || $what eq "pages")} {
        set wh [expr {[Winfo_height $w]
            - ([Text_cget $w pady:] * 2)
            - ([Text_cget $w highlightthickness:] * 2)}]
        set lh [Font_metrics [Text_cget $w font:] linespace:]
        set i [expr {($wh / $lh) * $i}]
        set what units
    }
    if {$what eq "top"} {
        Text_yviewMoveto $w 0.0
    } elseif {$what eq "bottom"} {
        Text_yviewMoveto $w 1.0
    } else {
        Text_yviewScroll $w [expr {int($i)}] $what
    }
}

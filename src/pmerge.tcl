#!/usr/bin/env tclsh
# Copyright 1999-2000,2016 BitMover, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This Program performs 3 way merge on files
# It output "diff3 -E -ma" like merge file, also add additional marker
# that shows changes relative to gca
# >	text from left
# <	text from right
# =	text from gca
# -	text deleted from gca

# Global variables
set debug 0
set quiet 0
set hideMarker 0
set wantGca 0
set wantAllMarker 0
set wantBigBlock 0
set um "="
set ENOENT 2
set EEXIST 17
set OK 1
set ERROR 0
set chgCount 0
set conflicts 0
set tmp "/tmp/"

# Main procedure
proc main {} {
    global left gca right debug
    
    init
    doMerge $left $gca $right
}

proc doMerge {lfile gca rfile} {
    global debug
    
    set opt ""
    if {$debug} {
        set opt "-d"
    }
    
    set cmd "bk fdiff -s $opt $lfile $gca $rfile"
    if {[catch {set pipe [open "|$cmd" r]} error]} {
        puts stderr "cannot popen fdiff: $error"
        exit 1
    }
    
    set flist [getdiff $pipe]
    close $pipe
    mkMerge {*}$flist
    
    foreach f $flist {
        force_unlink $f
    }
    
    return 1
}

proc mkMerge {lmarker ldata rmarker rdata} {
    global conflicts um wantGca debug quiet
    
    set lm_fh [open $lmarker r]
    set ld_fh [open $ldata r]
    set rm_fh [open $rmarker r]
    set rd_fh [open $rdata r]
    
    fconfigure stdout -translation binary
    
    set conflicts 0
    set OverlapCount ""
    
    while {[gets $lm_fh lm] >= 0} {
        set lm [string trimright $lm]
        set ld [gets $ld_fh]
        set rm [string trimright [gets $rm_fh]]
        set rd [gets $rd_fh]
        set markers "$lm$rm"
        
        if {$debug} {
            puts "MARKERS $markers"
        }
        
        if {$markers eq "uu"} {
            # no change on both side
            doPrint $markers $ld
        } elseif {$markers eq "is"} {
            # left side inserted a line
            doPrint $markers $ld
        } elseif {$markers eq "si"} {
            # right side insert a line
            doPrint $markers $rd
        } elseif {$markers eq "du"} {
            # left side deleted a line
            if {$wantGca} {
                doPrint $markers $rd
            }
            if {$debug} {
                puts stderr "left delete: $ld"
            }
        } elseif {$markers eq "ud"} {
            # right side deleted a line
            if {$wantGca} {
                doPrint $markers $ld
            }
            if {$debug} {
                puts stderr "right delete: $rd"
            }
        } elseif {$markers eq "dd"} {
            # both side deleted the same line
            if {$wantGca} {
                doPrint $markers $rd
            }
            if {$debug} {
                puts stderr "both delete: $rd"
            }
        } elseif {$markers eq "<<"} {
            # i.e. We have a overlap.
            # This is where most of the real work is done.
            set conflicts [expr {$conflicts + [chkOverlap]}]
        } else {
            puts stderr "unexpected case: $markers"
            puts stderr "L: $lm $ld"
            puts stderr "R: $rm $rd"
            break
        }
    }
    
    close $lm_fh
    close $ld_fh
    close $rm_fh
    close $rd_fh
    
    if {$conflicts} {
        set OverlapCount ", $conflicts conflicting"
    }
    
    if {!$quiet} {
        puts stderr "Diff blocks: $chgCount$OverlapCount"
    }
}

# This is the "main" function
# This function process a overlap block:
# We run a unified diff inside the overlap block, which break the
# overlap block into smaller blocks, e.g.common block, left block and
# right block. The left and right block are also called the conflict block.
# This can either be a soft conflict or a hard conflict. If it is a soft
# conflict, we resolve it automatically and convert it into a common block.
# If it is a hard conflict, we show the conflict as a "arrow" block.
proc chkOverlap {} {
    global ldata rdata lmarker rmarker debug
    global ldata1 rdata1 cdata1l cdata1r cdata2l cdata2r
    global wantGca tmp
    
    # Reset global variables, just in case
    set len 0
    set conflicts 0
    set ldata [list]
    set rdata [list]
    set lmarker [list]
    set rmarker [list]
    set ldata1 [list]
    set rdata1 [list]
    set cdata1l [list]
    set cdata1r [list]
    set cdata2l [list]
    set cdata2r [list]
    
    set lm1 ""
    set rm1 ""
    set cml ""
    set cmr ""
    
    # Make temp files so we can run diff on it
    set tmpfiles [mkdfile]
    set ltmp [lindex $tmpfiles 0]
    set rtmp [lindex $tmpfiles 1]
    
    set cmd "diff -u -U $len $ltmp $rtmp"
    if {[catch {set diff_fh [open "|$cmd" r]} error]} {
        puts stderr "cannot popen diff: $error"
        exit 1
    }
    
    # This is the main loop, all the interesting work is done here !!
    # We proccess all the unified diffs in this loop.
    set mode ""
    set ln ""
    
    # Get first unified diff
    set result [getUdiff $diff_fh mode ln]
    if {$result eq "EOF"} {
        close $diff_fh
        force_unlink $ltmp
        force_unlink $rtmp
        return 0
    }
    
    if {$debug > 4} {
        puts "##getcommon 1"
    }
    getCommon cdata1l cdata1r
    
    if {$debug > 4} {
        puts "##get left right"
    }
    set lrc [getLeft]
    set rrc [getRight]
    
    while {1} {
        # If left/right block have no hard conflict, resolve it,
        # push winning block back into the common block and re-start
        # from top-of-loop.
        # resolve into common1
        if {[resolveConflict {*}$lrc {*}$rrc cdata1l cdata1r] && $mode ne "EOF"} {
            getCommon cdata1l cdata1r
            set lrc [getLeft]
            set rrc [getRight]
            continue
        }
        
        if {$debug > 4} {
            puts "##getcommon2"
        }
        getCommon cdata2l cdata2r
        
        # If leading common block is too "trivial", split & *insert*
        # into the left right block.
        splitCommon_i
        
        # When we get here:
        # If cdata2l is non-empty, then either ldata1 or rdata1
        # must be non-empty. This is important because we don't
        # want to split a common block into a empty conflict block.
        # i.e Create a conflict block from nothing = bad idea!!
        if {[llength $cdata2l] > 0 && [llength $ldata1] == 0 && [llength $rdata1] == 0} {
            error "pmerge: internal error: creating empty conflict block"
        }
        
        # If trailing common block is too "trivial", split & *append*
        # into the left right block, repeat until we get a real conflict
        if {[splitCommon_a] && $mode ne "EOF"} {
            if {$debug > 4} {
                puts "##get left right"
            }
            set lrc [getLeft]
            set rrc [getRight]
            if {![hasConflict {*}$lrc {*}$rrc]} {
                # resolve into common2
                resolveConflict {*}$lrc {*}$rrc cdata2l cdata2r
                getCommon cdata2l cdata2r
                continue
            }
        }
        
        # The tough part is done, now print the block !!
        # XXX If the left right list is non-empy it must be
        # a hard conflict
        
        if {[isCommon]} {
            # No hard conflict, print the common block
            ejectMerge
        } else {
            # It is a hard conflict, print the arrow block
            incr conflicts
            ejectMerge
            puts "!<<<<<<< $::left"
            ejectList 0 [expr {!$::wantGca}] "<" $ldata1
            puts "!======="
            ejectList 0 [expr {!$::wantGca}] ">" $rdata1
            puts "!>>>>>>> $::right"
            set ldata1 [list]
            set rdata1 [list]
        }
        
        # Before we enter top of loop again,
        # turn the trailing common block
        # into leading common block.
        if {[llength $ldata1_t] == 0 && [llength $rdata1_t] == 0} {
            if {$debug > 4} {
                puts "##common2->common1"
            }
            set cdata1l $cdata2l
            set cdata1r $cdata2r
            set cdata2l [list]
            set cdata2r [list]
            
            if {$debug > 4} {
                puts "##get left right"
            }
            set lrc [getLeft]
            set rrc [getRight]
        } else {
            if {[llength $cdata2l] > 0 || [llength $cdata2r] > 0} {
                error "pmerge: internal error: cdata2 non-empty"
            }
        }
        
        if {$mode eq "EOF" && [llength $cdata1l] == 0 && [llength $ldata1_t] == 0 && [llength $rdata1_t] == 0} {
            break
        }
    }
    
    close $diff_fh
    
    # If diff tell us that both side are identical, just print it
    # This happen when both sides added identical lines.
    if {[exitStatus $?]} {
        set cdata1l $ldata
        set cdata1r $rdata
        ejectMerge
    }
    
    # clean up
    force_unlink $ltmp
    force_unlink $rtmp
    set ldata [list]
    set rdata [list]
    set lmarker [list]
    set rmarker [list]
    set ldata1 [list]
    set rdata1 [list]
    set cdata1l [list]
    set cdata1r [list]
    set cdata2l [list]
    set cdata2r [list]
    
    return $conflicts
}

proc getdiff {pipe_fh} {
    global chgCount
    
    set chgCount [string trim [gets $pipe_fh]]
    set lmarker [string trim [gets $pipe_fh]]
    set ldata [string trim [gets $pipe_fh]]
    set rmarker [string trim [gets $pipe_fh]]
    set rdata [string trim [gets $pipe_fh]]
    
    return [list $lmarker $ldata $rmarker $rdata]
}

proc doPrint {markers ln} {
    global um wantAllMarker
    
    if {$wantAllMarker} {
        if {$markers eq "uu"} {
            puts "$um$ln"
        } elseif {$markers eq "is"} {
            puts "<$ln"
        } elseif {$markers eq "si"} {
            puts ">$ln"
        } elseif {$markers eq "dd"} {
            puts "-$ln"
        } elseif {$markers eq "ud"} {
            puts "}$ln"
        } elseif {$markers eq "du"} {
            puts "{$ln"
        } else {
            error "unexpected markers: $markers"
        }
    } else {
        puts "$ln"
    }
}

# get unified diff
proc getUdiff {diff_fh mode_var ln_var} {
    upvar $mode_var mode $ln_var ln
    
    while {[gets $diff_fh line] >= 0} {
        if {$::debug > 2} {
            puts "##Udiff# $line"
        }
        
        if {[string match "--- *" $line]} {continue}
        if {[string match "+++ *" $line]} {continue}
        if {[string match "@@ *" $line]} {continue}
        
        if {[regexp {^-.(.*)} $line -> match]} {
            set mode "<"
            set ln $match
            return "OK"
        } elseif {[regexp {^\+.(.*)} $line -> match]} {
            set mode ">"
            set ln $match
            return "OK"
        } elseif {[regexp {^ (.*)} $line -> match]} {
            set mode " "
            set ln $match
            return "OK"
        } else {
            error "Bad u diff: $line"
        }
    }
    
    set mode "EOF"
    set ln ""
    return "EOF"
}

proc ejectList {stripmarker skipGca mrk mylist} {
    global hideMarker um
    
    if {$mrk eq "<"} {
        set del "{"n    } else {
        set del "}"
    }
    
    foreach ln $mylist {
        if {[string match "s*" $ln]} {continue}
        if {$skipGca && [string match "d*" $ln]} {continue}
        
        if {$stripmarker || $hideMarker} {
            set ln [string range $ln 1 end]
            puts "$ln"
            continue
        }
        
        set mrk1 [string index $ln 0]
        if {$mrk1 eq "d"} {
            set ln "$del[string range $ln 1 end]"
        } elseif {$mrk1 eq "i"} {
            set ln "$mrk[string range $ln 1 end]"
        } elseif {$mrk1 eq "u"} {
            set ln "$um[string range $ln 1 end]"
        } else {
            error "unexpect marker: $ln"
        }
        puts "$ln"
    }
}

proc ejectMerge {} {
    global cdata1l cdata1r um wantAllMarker wantGca
    
    foreach ln $cdata1l {
        set rn [lindex $cdata1r 0]
        set cdata1r [lrange $cdata1r 1 end]
        
        # Show deleted line only if user ask for it
        if {[string match "d*" $ln] && (!$wantGca || !$wantAllMarker)} {continue}
        
        if {!$wantAllMarker} {
            set ln [string range $ln 1 end]
            puts "$ln"
        } else {
            set lm [string index $ln 0]
            set rm [string index $rn 0]
            set ln [string range $ln 1 end]
            
            if {"$lm$rm" eq "uu"} {
                # This is a unchanged line
                puts "$um$ln"
            } elseif {"$lm$rm" eq "ii"} {
                # Both left & right added identical line
                puts "+$ln"
            } elseif {"$lm$rm" eq "ui"} {
                # This line is unchanged by the left,
                # but is inserted on by the right
                # This happen when diff re-align the lines
                puts "+$ln"
            } elseif {"$lm$rm" eq "iu"} {
                # This line is unchanged by the right,
                # but is inserted on by the left
                # This happen when diff re-align the lines
                puts "+$ln"
            } elseif {"$lm$rm" eq "is"} {
                # This happen when we merge left into common
                puts "<$ln"
            } elseif {"$lm$rm" eq "si"} {
                # This happen when we merge right into common
                puts ">$ln"
            } elseif {"$lm$rm" eq "dd"} {
                # Both left & right delete this line
                puts "-$ln"
            } else {
                error "Unexpected markers $lm$rm: $ln"
            }
        }
    }
    
    set cdata1l [list]
    set cdata1r [list]
}

proc countChar_ui {mylist} {
    set l_count 0
    set c_count 0
    
    # exclude deleted line from the count
    foreach item $mylist {
        if {[string index $item 0] ne "d"} {
            incr c_count [string length $item]
            incr l_count
        }
    }
    
    return [list $l_count $c_count]
}

proc needCommon {mylist} {
    set ln_threshold 3
    set ch_threshold 10
    
    set counts [countChar_ui $mylist]
    set ln_count [lindex $counts 0]
    set ch_count [lindex $counts 1]
    
    if {$ln_count >= $ln_threshold} {return 1}
    if {!$::wantBigBlock && $ch_count >= $ch_threshold} {return 1}
    return 0
}

proc isPrintable {marker} {
    if {$marker eq "s"} {return 0}
    if {$marker eq "d" && !$::wantGca} {return 0}
    return 1
}

proc isCommon {} {
    global ldata1 rdata1
    
    if {[llength $ldata1] > 0 || [llength $rdata1] > 0} {return 0}
    return 1
}

proc hasConflict {l_all_i l_no_chg r_all_i r_no_chg} {
    if {$l_all_i && $r_no_chg} {return 0}
    if {$r_all_i && $l_no_chg} {return 0}
    return 1
}

# If the conflict is resolvable, do it, then return 1
# else return 0;
proc resolveConflict {l_all_i l_no_chg r_all_i r_no_chg cdatal_var cdatar_var} {
    upvar $cdatal_var cdatal $cdatar_var cdatar
    global ldata1_t rdata1_t ldata1 rdata1
    
    # We empty the "unchanged" block
    # becuase the other side must have applied a "delete"
    # to all the lines on the unchanged side.
    # We know this becuase the winning side has all 'i'.
    # Otherwise, some 'u' markers would have shown up
    # on the winning side.
    if {$l_all_i && $r_no_chg} {
        foreach item $ldata1_t {
            if {$::debug > 3} {
                puts "##resolveConflict_i-L: $item"
            }
            lappend cdatal $item
            lappend cdatar "s"
        }
        set ldata1_t [list]
        set rdata1_t [list]
        set ldata1 [list]
        set rdata1 [list]
        return 1
    }
    
    if {$r_all_i && $l_no_chg} {
        foreach item $rdata1_t {
            # text data is always stored on cdata1l
            # see ejectMerge();
            if {$::debug > 3} {
                puts "##resolveConflict_i-R-C1: $item"
            }
            lappend cdatar [string index $item 0]
            set item "s[string range $item 1 end]"
            lappend cdatal $item
        }
        set ldata1_t [list]
        set rdata1_t [list]
        set ldata1 [list]
        set rdata1 [list]
        return 1
    }
    
    foreach item $ldata1_t {lappend ldata1 $item}
    foreach item $rdata1_t {lappend rdata1 $item}
    set ldata1_t [list]
    set rdata1_t [list]
    return 0
}

# Make temp files from the left and right block
# so we can run a unified diff against them.
# Also poupulate the ldata, lmaker, rdata, rmarker list.
proc mkdfile {} {
    global lmarker ldata rmarker rdata tmp
    
    set ltmp "${tmp}pmerge_l[pid]"
    set rtmp "${tmp}pmerge_r[pid]"
    
    set TMPL [open $ltmp w]
    set TMPR [open $rtmp w]
    
    set len 0
    while {1} {
        set lm [string trim [gets $::LM]]
        set rm [string trim [gets $::RM]]
        set ld [gets $::LD]
        set rd [gets $::RD]
        
        if {$lm eq ">"} {
            if {$rm ne ">"} {
                error "Lost alignment"
            }
            break
        }
        
        incr len
        
        if {[isPrintable $lm]} {
            lappend lmarker $lm
            lappend ldata "$lm$ld"
            puts $TMPL "$lm$ld"
        }
        
        if {[isPrintable $rm]} {
            lappend rmarker $rm
            lappend rdata "$rm$rd"
            puts $TMPR "$rm$rd"
        }
    }
    
    close $TMPL
    close $TMPR
    
    if {$::debug > 1} {
        foreach item $ldata {
            puts "#L# $item"
        }
        foreach item $rdata {
            puts "#R# $item"
        }
    }
    
    return [list $ltmp $rtmp]
}

proc getCommon {llist_var rlist_var} {
    upvar $llist_var llist $rlist_var rlist
    global mode ln lmarker rmarker
    
    while {$mode eq " "} {
        set cml [lindex $lmarker 0]
        set lmarker [lrange $lmarker 1 end]
        set cmr [lindex $rmarker 0]
        set rmarker [lrange $rmarker 1 end]
        
        lappend llist "$cml$ln"
        lappend rlist "$cmr$ln"
        
        set result [getUdiff $::DIFF mode ln]
        if {$result eq "EOF"} {break}
    }
}

proc getLeft {} {
    global mode ln lmarker
    
    set all_i 1
    set no_chg 1
    set ldata1_t [list]
    
    while {$mode eq "<"} {
        set lm1 [lindex $lmarker 0]
        set lmarker [lrange $lmarker 1 end]
        
        if {$lm1 ne "i"} {set all_i 0}
        if {$lm1 ne "u"} {set no_chg 0}
        
        lappend ldata1_t "$lm1$ln"
        
        set result [getUdiff $::DIFF mode ln]
        if {$result eq "EOF"} {break}
    }
    
    return [list $all_i $no_chg]
}

proc getRight {} {
    global mode ln rmarker
    
    set all_i 1
    set no_chg 1
    set rdata1_t [list]
    
    while {$mode eq ">"} {
        set rm1 [lindex $rmarker 0]
        set rmarker [lrange $rmarker 1 end]
        
        if {$rm1 ne "i"} {set all_i 0}
        if {$rm1 ne "u"} {set no_chg 0}
        
        lappend rdata1_t "$rm1$ln"
        
        set result [getUdiff $::DIFF mode ln]
        if {$result eq "EOF"} {break}
    }
    
    return [list $all_i $no_chg]
}

proc splitCommon_i {} {
    global cdata1l cdata1r ldata1 rdata1 debug
    
    if {[needCommon $cdata1l]} {
        foreach item [lreverse $cdata1l] {
            if {$debug > 3} {
                puts "##splitCommom_i-L: $item"
            }
            set ldata1 [linsert $ldata1 0 $item]
        }
        foreach item [lreverse $cdata1r] {
            if {$debug > 3} {
                puts "##splitCommom_i-R: $item"
            }
            set rdata1 [linsert $rdata1 0 $item]
        }
        set cdata1l [list]
        set cdata1r [list]
    }
}

proc splitCommon_a {} {
    global cdata2l cdata2r ldata1 rdata1 debug
    
    if {[needCommon $cdata2l]} {
        foreach item $cdata2l {
            if {$debug > 3} {
                puts "##splitCommom_a-L: $item"
            }
            lappend ldata1 $item
        }
        foreach item $cdata2r {
            if {$debug > 3} {
                puts "##splitCommom_a-R: $item"
            }
            lappend rdata1 $item
        }
        set cdata2l [list]
        set cdata2r [list]
        return 1
    }
    return 0
}

proc empty {mylist} {
    return [expr {[llength $mylist] == 0}]
}

proc force_unlink {file} {
    if {[catch {file delete $file}]} {
        # for Unix w/ Samba or NT
        # must have write access to perform ulink
        file attributes $file -permissions 0660
        file delete $file
    }
}

proc force_rename {from to} {
    if {[catch {file rename $from $to}]} {
        # for Unix w/ Samba or NT
        # must have write access to perform rename
        if {[file exists $to]} {
            force_unlink $to
        }
        set stat [file stat $from]
        set mode [expr {$stat(mode) & 0777 | 0400}]
        file attributes $from -permissions $mode
        set mode [expr {$stat(mode) & 0777}]
        
        if {[catch {file rename $from $to}]} {
            file attributes $to -permissions $mode
            return $::ERROR
        }
        
        file attributes $to -permissions $mode
        return $::OK
    }
    return $::OK
}

# mv(1).
proc mv {from to} {
    global doNothing verbose debug
    
    if {![file exists $from]} {
        puts "mv: no such file $from"
        return $::ERROR
    }
    
    if {$debug || $verbose} {
        puts "mv $from $to"
    }
    
    if {$doNothing} {return $::OK}
    
    if {[force_rename $from $to] == $::OK} {
        if {$debug} {
            puts "rename($from,$to) worked"
        }
        return $::OK
    }
    
    # No?  Create the dir and try again.
    set dir [file dirname $to]
    if {$dir ne $to} {
        mkdirp $dir 0775
        if {[force_rename $from $to] == $::OK} {
            if {$debug} {
                puts "rename($from,$to) worked"
            }
            return $::OK
        }
    }
    
    # Still didn't work?  Try copying it.
    force_unlink $to
    if {[cp $from $to] == $::ERROR} {return $::ERROR}
    
    set stat [file stat $from]
    file attributes $to -permissions $stat(mode)
    file mtime $to $stat(mtime) $stat(mtime)
    force_unlink $from
    return $::OK
}

proc cp {from to} {
    global doNothing verbose debug
    
    if {![file exists $from]} {
        puts "cp: no such file $from"
        return $::ERROR
    }
    
    if {$debug || $verbose} {
        puts "cp $from $to"
    }
    
    if {$doNothing} {return $::OK}
    
    force_unlink $to
    
    set dir [file dirname $to]
    if {$dir ne $to && ![file exists $dir]} {
        if {[mkdirp $dir 0775] == $::ERROR} {return $::ERROR}
    }
    
    if {[catch {set in_fh [open $from r]}]} {
        puts "can't read $from"
        return $::ERROR
    }
    
    if {[catch {set out_fh [open $to w]}]} {
        puts "can't create $to"
        close $in_fh
        return $::ERROR
    }
    
    fconfigure $in_fh -translation binary
    fconfigure $out_fh -translation binary
    
    set buf ""
    while {[set len [read $in_fh 262144]] > 0} {
        puts -nonewline $out_fh $buf
    }
    
    close $in_fh
    close $out_fh
    
    if {$debug} {
        puts "cp wrote [string length $buf] bytes into $to"
    }
    
    return $::OK
}

# mkdir -p
proc mkdirp {path mode} {
    global doNothing debug
    
    if {$debug} {
        puts "mkdirp $path $mode"
    }
    
    if {$doNothing} {return $::OK}
    
    if {[catch {file mkdir $path}]} {
        if {[file exists $path]} {return $::OK}
        set chopped [file dirname $path]
        if {$chopped eq $path} {return $::ERROR}
        if {[mkdirp $chopped $mode] == $::ERROR} {return $::ERROR}
        file mkdir $path
        return $::OK
    }
    
    return $::OK
}

proc usage {} {
    puts {
usage: pmerge [-abegmq] [-d<N>] left gca right

    -a		show all markers
    -b		show conflict in bigger block
    -e		hide equal ("=") markers
    -g  	show gca text in conflict block (marked as '-)
    -m  	turn off markers
    -q  	quiet mode.
    -d<level>	debugging. (level can be 0-5, e.g -d2)

	Pmerge performs a 3 way merge on text files.
	The result of the merge is send to stdout.
}
    exit 0
}

proc init {} {
    global argv debug quiet hideMarker wantGca
    global wantAllMarker wantBigBlock um doNothing verbose
    
    set doNothing 0
    set verbose 0
    
    while {[llength $argv] > 0 && [string match "-*" [lindex $argv 0]]} {
        set x [string range [lindex $argv 0] 1 end]
        
        if {$x eq "help" || $x eq "-help" || $x eq "--help"} {
            usage
        }
        
        if {[regexp {^d([0-9])} $x -> level]} {
            set debug $level
        } elseif {$x eq "q"} {
            set quiet 1
        } elseif {$x eq "m"} {
            set hideMarker 1
        } elseif {$x eq "e"} {
            set um ""
        } elseif {$x eq "b"} {
            set wantBigBlock 1
        } elseif {$x eq "g"} {
            set wantGca 1
        } elseif {$x eq "a"} {
            set wantAllMarker 1
        } else {
            error "unknown option: -$x"
        }
        
        set argv [lrange $argv 1 end]
    }
    
    if {[llength $argv] != 3} {
        usage
    }
    
    global left gca right
    set left [lindex $argv 0]
    set gca [lindex $argv 1]
    set right [lindex $argv 2]
    
    if {$debug > 0} {
        # disable the "=" marker
        # this maks it easier to run diffs
        # again diff3 output.
        set um ""
    }
}

proc exitStatus {status} {
    return [expr {$status == 0}]
}

# Main execution
if {"$::argv0" eq [info script]} {
    main
}
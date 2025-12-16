#!/usr/bin/env tclsh
# Copyright 2001,2016 BitMover, Inc
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
# Program to create graphs for displaying on bkweb.
# This program emits a DOT graph for consumption by Graphviz `dot`.
#
# Example:
#   ./viz_gen.tcl | dot -Tgif > /tmp/z2.gif
#
# If invoked with an argument, it is treated as the file passed to
# `bk _lines -u -t`. Otherwise, a subset of the main ChangeSet is used
# via `bk -R _lines -R-1M -n50 -u -t ChangeSet`.

proc header {file} {
    puts "digraph \"$file\" {"
    puts "\trankdir=LR"
    puts "\tranksep=.25"
    puts "\tnode [height=.3,width=.3,shape=box,style=filled,regular=1,color=\".7 .3 1.0\"];"
}

proc footer {} {
    variable label
    puts "\n\t// Do labels\n"
    foreach lbl [lsort [array names label]] {
        puts [format "\t%s [fontsize=10,label=\"%s\"];" $lbl $label($lbl)]
    }
    puts "}"
}

proc genGraph {chan file} {
    variable label
    variable mn
    header $file
    set lineNum 1
    while {[gets $chan line] >= 0} {
        puts "\n\t//================="
        set fields [split $line]
        puts -nonewline "\t"
        set len [expr {[llength $fields] - 1}]
        set i 0
        set mark no
        foreach node $fields {
            incr i
            if {[string first "|" $node] != -1} {
                set parts [split $node |]
                set node [lindex $parts 0]
                set merge [lindex $parts 1]
                set g [split $node -]
                set m [split $merge -]
                set mn([lindex $m 2]) [lindex $g 2]
            } else {
                set g [split $node -]
            }
            set n [lindex $g 2]
            set label($n) "[lindex $g 0]\\n[lindex $g 1]"
            if {$lineNum == 1} {
                puts -nonewline "$n "
                if {$i <= $len} {
                    puts -nonewline "-> "
                }
            } else {
                if {$mark eq "no"} {
                    puts -nonewline "$n  "
                    set mark yes
                } elseif {$mark eq "yes"} {
                    puts -nonewline "-> $n "
                }
            }
        }
        incr lineNum
    }

    puts "\n\t//===== Merges ========="
    foreach n [lsort [array names mn]] {
        puts [format "\t%s -> %s" $n $mn($n)]
    }
    footer
}

set argvCount [llength $argv]
if {$argvCount > 0} {
    set file [lindex $argv 0]
    set cmd [list | bk _lines -u -t $file]
} else {
    set file "ChangeSet"
    set cmd [list | bk -R _lines -R-1M -n50 -u -t $file]
}

set chan [open $cmd r]
if {$chan eq ""} {
    puts stderr "Unable to open bk _lines"
    exit 1
}

# Ensure arrays are defined for graph construction.
array set label {}
array set mn {}

catch {genGraph $chan $file} err
close $chan
if {[info exists err] && $err ne ""} {
    puts stderr $err
    exit 1
}

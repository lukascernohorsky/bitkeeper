#!/usr/bin/env tclsh
# Copyright 2016 BitMover, Inc
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

proc dateRange {file} {
    set cmd [list bk prs -fhnd:Dy: -- $file]
    if {[catch {set fh [open "|[join $cmd { }]" r]} msg]} {
        puts stderr "failed to run bk prs for $file: $msg"
        exit 1
    }

    set s 0
    set e 0
    set ret ""
    while {[gets $fh line] >= 0} {
        set line [string trim $line]
        if {$line eq ""} {
            continue
        }
        if {!$s} {
            set s $line
        }
        if {!$e} {
            set e $line
        }
        if {$line > [expr {$e + 1}]} {
            if {$ret ne ""} {
                append ret ","
            }
            append ret $s
            if {$e != $s} {
                append ret "-$e"
            }
            set s 0
            set e 0
        } else {
            set e $line
        }
    }
    if {[catch {close $fh} msg]} {
        puts stderr "bk prs failed for $file: $msg"
        exit 1
    }

    if {$s} {
        if {$ret ne ""} {
            append ret ","
        }
        append ret $s
        if {$e != $s} {
            append ret "-$e"
        }
    }
    return $ret
}

if {[catch {set fh [open "|bk -U grep 'Copyright [0-9,-]+ BitMover, Inc'" r]} msg]} {
    puts stderr "failed to search repository: $msg"
    exit 1
}

while {[gets $fh line] >= 0} {
    set line [string trim $line]
    if {![regexp {^(.*):.*Copyright ([0-9,-]+)} $line -> file oldrange]} {
        continue
    }

    set r [dateRange $file]
    if {$r eq $oldrange} {
        continue
    }
    puts "$file: $r"
    if {[catch {exec bk edit -qS -- $file} msg]} {
        puts stderr "bk edit failed for $file: $msg"
        exit 1
    }

    set pattern "s/Copyright [0-9,-]\\+ BitMover, Inc/Copyright $r BitMover, Inc/"
    if {[catch {exec sed -i $pattern -- $file} msg]} {
        puts stderr "sed update failed for $file: $msg"
        exit 1
    }
}
if {[catch {close $fh} msg]} {
    puts stderr "grep pipeline failed: $msg"
    exit 1
}

#!/usr/bin/env tclsh
# Copyright 2010 BitMover, Inc
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
# Filter failed bk tests: ./build t | bk tclsh t/failed.tcl 2>&1 | tee BUGS
#
# This will filter all the failed tests out of the regressions, keeping
# the title and subtitle of test the failure happened.  This is
# to be able to quickly triage and go fix bugs.
#
# alg by rick, code by damon

set title {}
set subtitle {}

while {[gets stdin line] >= 0} {
    if {[regexp {^===} $line]} {
        set title $line
        set subtitle {}
    } elseif {[regexp {^---} $line]} {
        set subtitle $line
    } elseif {[regexp {\.\.failed \(bug} $line]} {
        if {[string length $title]} {
            puts ""
            puts $title
        }
        if {[string length $subtitle]} {
            puts $subtitle
        }
        puts $line
        set title {}
        set subtitle {}
    }
}

#!/usr/bin/env tclsh
# Copyright 2005,2016 BitMover, Inc
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

# Onetime script to turn a secret key into code to embed in bk

set W 60
if {[llength $argv] != 1} {
    puts stderr "usage: key2code.tcl <keyfile>"
    exit 1
}

set path [lindex $argv 0]
if {[catch {set fh [open $path r]} msg]} {
    puts stderr "cannot open $path: $msg"
    exit 1
}
# Read raw bytes so binary keys are handled correctly.
fconfigure $fh -translation binary -encoding binary
set data [read $fh]
close $fh

set count [string length $data]
set key ""
foreach ch [split $data ""] {
    # scan %c returns signed; normalize to 0-255 for formatting
    set byte [scan $ch %c]
    if {$byte < 0} {
        set byte [expr {256 + $byte}]
    }
    append key [format "0x%02x, " $byte]
}

puts -nonewline "private const u8\tmagickey[$count] = {\n"
set first 1
while {[string length $key] > 0} {
    set chunk [string range $key 0 [expr {$W - 1}]]
    set key [string range $key $W end]
    if {[string length $chunk] >= 2} {
        set chunk [string range $chunk 0 end-2]
    }
    if {$first} {
        set first 0
    } else {
        puts -nonewline ",\n"
    }
    puts -nonewline "\t$chunk"
}
puts "\n};"

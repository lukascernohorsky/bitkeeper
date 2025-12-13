#!/usr/bin/env wish
# Copyright 2015-2016 BitMover, Inc
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
# Post-install Tcl script for BitKeeper's OS X package installer.
# This script is invoked by the shell wrapper "postinstall" in the
# same directory.

package require Tk

wm withdraw .

set noprompt [file exists "/tmp/_bk_install_no_prompt"]
set rc 0
set err ""
set logf ""

proc logmsg {fmt args} {
    global logf

    set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    if {$logf eq ""} {
        if {[catch {set logf [open "/tmp/bk-install-log.txt" w]}]} {
            return
        }
    }
    puts $logf [format "%s: $fmt" $ts {*}$args]
    flush $logf
}

proc runit {cmd} {
    global rc err

    set err ""
    set rc 0
    set out ""
    set options {}
    if {[catch {set out [exec /bin/sh -c $cmd]} err options]} {
        if {[dict exists $options -errorcode]
            && [lindex [dict get $options -errorcode] 0] eq "CHILDSTATUS"} {
            set rc [lindex [dict get $options -errorcode] 2]
        } else {
            set rc 1
        }
    }
    logmsg "%s: %d '%s' '%s'" $cmd $rc $out $err
    return $out
}

proc rm_oldbk {path} {
    global noprompt rc err

    if {!$noprompt} {
        set msg "An old version of BitKeeper was found in\n${path}\nWould you like to remove it?"
        set ans [tk_messageBox -default yes -icon info -type yesno \
            -title "Old version of BitKeeper found" -message $msg]
        if {$ans ne "yes"} {
            return
        }
    }
    runit "/bin/rm -rf '${path}'"
    if {$rc != 0 && !$noprompt} {
        set msg [format "Error %s occurred: %s" $rc $err]
        tk_messageBox -default ok -icon error -type ok \
            -title "Error" -message $msg
    }
}

proc create_bklink {newbk} {
    global noprompt rc err

    set msg ""
    if {[file writable "/usr/bin"]} {
        runit "'${newbk}' links /usr/bin"
        if {$rc != 0} {
            set msg "Unable to create symbolic link /usr/bin/bk. You will need to add [file dirname $newbk] to your PATH manually."
        }
    } else {
        if {![catch {set f [open "/etc/paths.d/10-BitKeeper" w]}]} {
            puts $f [file dirname $newbk]
            close $f
        } else {
            set msg "Unable to write into /etc/paths.d. You will need to add [file dirname $newbk] to your PATH manually."
        }
    }
    if {$msg ne "" && !$noprompt} {
        tk_messageBox -default ok -icon error -type ok \
            -title "Error" -message $msg
    }
}

# Main
set dstroot ""
if {[info exists env(DSTROOT)]} {
    set dstroot $env(DSTROOT)
}
if {$dstroot eq ""} {
    exit 1
}

set home ""
if {[info exists env(HOME)]} {
    set home $env(HOME)
}
set user ""
if {[info exists env(USER)]} {
    set user $env(USER)
}
logmsg "bk installer: user ${user} home ${home} dstroot ${dstroot} noprompt ${noprompt}"

if {$user ne ""} {
    runit "/usr/sbin/chown -R '${user}' '${dstroot}/BitKeeper.app'"
}

set newbk "${dstroot}/BitKeeper.app/Contents/Resources/bitkeeper/bk"
set dotbk [string trim [runit "sudo -u '${user}' '${newbk}' dotbk"]]

# For the install log.
runit "sudo -u '${user}' '${newbk}' version"

set tmp ""
if {[info exists env(INSTALLER_TEMP)]} {
    set tmp $env(INSTALLER_TEMP)
}

# Attempt to collect an email address.
set instOut ""
set instErr ""
set instRc 0
if {[catch {set instOut [exec /bin/sh -c "sudo -u '${user}' '${newbk}' installtool --installed"]} instErr instOpts]} {
    if {[dict exists $instOpts -errorcode]
        && [lindex [dict get $instOpts -errorcode] 0] eq "CHILDSTATUS"} {
        set instRc [lindex [dict get $instOpts -errorcode] 2]
    } else {
        set instRc 1
    }
}
logmsg "bk installtool: %d '%s' '%s'" $instRc $instOut $instErr

if {$tmp ne "" && [file exists "${tmp}/config"]} {
    set buf ""
    if {![catch {set f [open "${tmp}/config" r]}]} {
        set buf [read $f]
        close $f
    }
    set c ""
    if {$dotbk ne "" && [file exists "${dotbk}/config"]} {
        if {![catch {set f [open "${dotbk}/config" r]}]} {
            set c [read $f]
            close $f
        }
    }
    if {[string length $buf] > 0} {
        file mkdir $dotbk
        append c "\n# Next section copied from `bk bin`/config\n" $buf
        if {![catch {set f [open "${dotbk}/config" w]}]} {
            puts -nonewline $f $c
            close $f
            runit "chown -R '${user}' '${dotbk}/config'"
        }
    }
}

foreach path { /usr/libexec/bitkeeper /usr/local/bitkeeper } {
    if {[file isdirectory $path]} {
        rm_oldbk $path
    }
}

set oldbk [string trim [runit "/usr/bin/readlink -n /usr/bin/bk"]]
if {$oldbk ne $newbk} {
    create_bklink $newbk
}

exit 0

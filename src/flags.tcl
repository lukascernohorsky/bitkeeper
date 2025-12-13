#!/usr/bin/env tclsh
#
# Tcl translation of flags.l
# Verify, in a trigger, that sccs.h doesn't have duplicate flag defines.
# Usage: tclsh flags.tcl < sccs.h

set plist {INIT GET CLEAN DELTA ADMIN PRS}
set reserved {1 2 4 8}
set prefix {}
foreach pre $plist {
    dict set prefix $pre 1
}

set used {}
set errors 0

while {[gets stdin line] >= 0} {
    if {![regexp {^#define\s+(([^_]+)_[A-Z0-9_]+)\s+(0x[0-8]+)} $line -> symbol group value]} {
        continue
    }
    if {![dict exists $prefix $group]} {
        continue
    }
    if {[scan $value "0x%x" num] != 1} {
        continue
    }

    foreach r $reserved {
        if {$num == $r} {
            puts stderr [format "%s may not use %d" $symbol $r]
            incr errors
        }
    }

    set key "$group $num"
    if {[dict exists $used $key]} {
        puts stderr [format "0x%x used by %s and %s" $num $symbol [dict get $used $key]]
        incr errors
    }
    dict set used $key $symbol
}

exit $errors

#!/usr/bin/env tclsh
# Tcl replacement for helpcheck.pl
# Validates that bk help references and command table entries map to documented topics.

set undoc {adler32 config fdiff g2bk gethelp getuser graft helpaliases lines log mtime names rcsparse rev2cset sids smoosh unlink zone}
array set topics {}
array set aliases {}
foreach u $undoc {
    set topics($u) 1
}

if {[catch {set fh [open "|bk helptopics" r]} err]} {
    puts stderr "ERROR: unable to run 'bk helptopics': $err"
    exit 1
}
set inAliases 0
while {[gets $fh line] >= 0} {
    if {!$inAliases} {
        if {[regexp {^Aliases} $line]} {
            set inAliases 1
            continue
        }
        if {![regexp {^  } $line]} {
            continue
        }
        regsub {^  } $line {} name
        set topics($name) 1
        continue
    }
    if {[regexp {^([^\t]+)\t(.*)} $line -> alias target]} {
        set aliases($alias) $target
    }
}
close $fh

if {[catch {set help [open "bkhelp.txt" r]} err]} {
    puts stderr "ERROR: unable to open bkhelp.txt: $err"
    exit 1
}
set lineNo 0
set errors 0
while {[gets $help line] >= 0} {
    incr lineNo
    if {![regexp {bk help\W(\w+)} $line -> topic]} {
        continue
    }
    if {[info exists topics($topic)]} {
        continue
    }
    if {[info exists aliases($topic)] && [info exists topics($aliases($topic))]} {
        continue
    }
    puts stderr "ERROR: $topic not found in topics list at line $lineNo"
    set errors 1
}
close $help

if {[catch {set bkfile [open "bk.c" r]} err]} {
    puts stderr "ERROR: unable to open bk.c: $err"
    exit 1
}
set inCmd 0
while {[gets $bkfile line] >= 0} {
    if {!$inCmd} {
        if {[regexp {^struct command cmdtbl\[\] = \{} $line]} {
            set inCmd 1
        }
        continue
    }
    if {[regexp {^\s*$} $line]} {
        break
    }
    if {![regexp {.*\{"([^"\s]+)} $line -> name]} {
        continue
    }
    if {[string match "_*" $name]} {
        continue
    }
    if {[info exists topics($name)]} {
        continue
    }
    if {[info exists aliases($name)] && [info exists topics($aliases($name))]} {
        continue
    }
    puts stderr "ERROR: $name in bk.c but not found in topics list"
    set errors 1
}
close $bkfile

exit $errors

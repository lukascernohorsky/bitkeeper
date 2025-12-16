#!/usr/bin/env tclsh

proc fail {msg} {
    puts stderr $msg
    exit 1
}

proc timeCompare {a b} {
    set ta [dict get $a TIME]
    set tb [dict get $b TIME]
    if {$ta < $tb} {return -1}
    if {$ta > $tb} {return 1}
    return 0
}

set bkdir "bk.tomcrypt"
if {[catch {string trim [exec bk changes -r+ -qnd:TAG: $bkdir]} bktag] || $bktag eq ""} {
    fail "Unable to determine bk tag"
}

set ::env(BK_USER) "tomstdenis"
set ::env(BK_HOST) "libtomcrypt.com"
set ::env(BK_NO_TRIGGERS) 1

set releases {}
foreach file [glob -nocomplain libtom*.log] {
    if {![regexp {(.*?-(.*))\.log$} $file _ base ver]} {
        fail "Unrecognized log filename: $file"
    }
    if {![file isdirectory $base]} {
        fail "Missing directory for $base"
    }

    set fh [open $file r]
    set dateLine [string trim [gets $fh]]
    set dateLine [string map {Sept Sep} $dateLine]
    regsub -all {,(?=\S)} $dateLine {, } dateLine
    regsub -all {(st|nd|rd|th)(?=\b)} $dateLine {} dateLine
    if {[catch {clock scan $dateLine} parsedTime]} {
        close $fh
        fail "Can't parse \"$dateLine\" in $file"
    }

    set cmt ""
    while {[gets $fh line] >= 0} {
        if {[regexp {^v(\S+)} $line _ found] && $found ne $ver} {
            close $fh
            fail "Version mismatch in $file"
        }
        append cmt $line \n
    }
    close $fh

    if {[string match *libtomcrypt* $file]} {
        set lib "tomcrypt"
    } else {
        set lib "tommath"
    }
    lappend releases [dict create VER $ver TIME $parsedTime CMT $cmt LIB $lib]
}

set releases [lsort -command timeCompare $releases]
if {![regexp {(.*)_(.*)} $bktag _ baseLib baseVer]} {
    fail "Unexpected tag format: $bktag"
}
set baseVer [string map {_ .} $baseVer]
set last {}
set startIdx -1
for {set i 0} {$i < [llength $releases]} {incr i} {
    set rel [lindex $releases $i]
    dict set last [dict get $rel LIB] $rel
    if {[dict get $rel LIB] eq $baseLib && [dict get $rel VER] eq $baseVer} {
        set startIdx [expr {$i + 1}]
        break
    }
}
if {$startIdx < 0 || $startIdx >= [llength $releases]} {
    fail "Base tag $bktag not found in logs"
}

for {set i $startIdx} {$i < [llength $releases]} {incr i} {
    set rel [lindex $releases $i]
    set lib [dict get $rel LIB]
    set ver [dict get $rel VER]
    set bkTime [clock format [dict get $rel TIME] -format "%Y-%m-%d %H:%M:%S-00:00"]

    puts "TIME: [dict get $rel TIME] $bkTime"
    puts "LIB: $lib"
    puts "VER: $ver"
    puts "CMT:\n[dict get $rel CMT]---"

    set ::env(BK_DATE_TIME_ZONE) $bkTime

    set prevVer [dict get [dict get $last $lib] VER]
    set cmd [format {diff -Nur lib%s-%s lib%s-%s | filterdiff --strip=1 --addprefix=src/%s/ > import.diffs} \
        $lib $prevVer $lib $ver $lib]
    if {[catch {exec /bin/sh -c $cmd} err]} {
        fail $err
    }

    if {[catch {exec bk import -tpatch -p0 -fF -y"import $lib v$ver" import.diffs $bkdir} err]} {
        fail $err
    }

    set cmts [open import.cmts w]
    puts -nonewline $cmts [dict get $rel CMT]
    close $cmts

    if {[catch {exec /bin/sh -c "cd $bkdir; bk comments -r+ -Y../import.cmts ChangeSet"} err]} {
        fail $err
    }

    set tag [string map {. _} ${lib}_${ver}]
    if {[catch {exec /bin/sh -c "cd $bkdir; bk tag $tag"} err]} {
        fail $err
    }

    file delete -force test.dir
    if {[catch {exec bk export -tplain -r$tag -i"src/$lib/*" $bkdir test.dir} err]} {
        fail $err
    }

    if {[catch {exec /bin/sh -c "diff -ur -x README.BK lib$lib-$ver test.dir/src/$lib"} err]} {
        fail "$lib-$ver mismatch, $err"
    }

    dict set last $lib $rel
}

exit 1

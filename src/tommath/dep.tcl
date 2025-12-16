#!/usr/bin/env tclsh
# Walk through source, add labels and make classes (Tcl rewrite)

proc uppercase_define {filename} {
    set define [string toupper $filename]
    return [string map {. _} $define]
}

set deplist {}
set class [open "tommath_class.h" w]
puts $class "#if !(defined(LTM1) && defined(LTM2) && defined(LTM3))\n#if defined(LTM2)\n#define LTM3\n#endif\n#if defined(LTM1)\n#define LTM2\n#endif\n#define LTM1\n\n#if defined(LTM_ALL)";

# first pass: wrap bn*.c files with conditional includes and collect defines
foreach filename [lsort [glob -nocomplain "bn*.c"]] {
    set define [uppercase_define $filename]
    puts "Processing $filename"
    puts $class "#define $define"

    set apply 0
    set src [open $filename r]
    set out [open "tmp" w]

    set firstLine ""
    if {[gets $src firstLine] >= 0} {
        if {[regexp {include} $firstLine]} {
            puts $out $firstLine
        } else {
            puts $out "#include <tommath.h>"
            puts $out "#ifdef $define"
            puts $out $firstLine
            set apply 1
        }
    }

    while {[gets $src line] >= 0} {
        if {![regexp {tommath\.h} $line]} {
            puts $out $line
        }
    }
    if {$apply} {
        puts $out "#endif"
    }
    close $src
    close $out

    file delete $filename
    file rename tmp $filename
}
puts $class "#endif\n"

# second pass: build classes and dependency list
foreach filename [lsort [glob -nocomplain "bn*.c"]] {
    set define [uppercase_define $filename]
    puts $class "#if defined($define)"
    set list $define

    set src [open $filename r]
    while {[gets $src line] >= 0} {
        set search $line
        while {[regexp -indices {(fast_)*(s_)*mp_[a-z_0-9]*} $search match]} {
            set matchStr [string range $search [lindex $match 0] [lindex $match 1]]
            set search [string range $search [expr {[lindex $match 1] + 1}] end]
            if {$matchStr in {mp_digit mp_word mp_int}} {
                continue
            }
            set macro "BN_[string toupper $matchStr]_C"
            if {[string first $macro $list] < 0} {
                puts $class "   #define $macro"
                append list ",$macro"
            }
        }
    }
    close $src

    dict set deplist $define $list
    puts $class "#endif\n"
}
puts $class "#ifdef LTM3\n#define LTM_LAST\n#endif\n#include <tommath_superclass.h>\n#include <tommath_class.h>\n#else\n#define LTM_LAST\n#endif"
close $class

# call graph generation
set out [open "callgraph.txt" w]
set indent 0

proc draw_func {deplist key out} {
    upvar 1 indent indent path path
    set funcs [split [dict get $deplist $key] ,]
    if {[lsearch -exact $path [lindex $funcs 0]] >= 0} {
        return
    }
    lappend path [lindex $funcs 0]

    if {$indent == 0} {
        # root line, no prefix
    } elseif {$indent >= 1} {
        puts -nonewline $out [string repeat "|   " [expr {$indent - 1}]]
        puts -nonewline $out "+--->"
    }
    puts $out [lindex $funcs 0]

    set temp $path
    foreach func [lrange $funcs 1 end] {
        incr indent
        draw_func $deplist $func $out
        incr indent -1
    }
    set path $temp
}

foreach key [lsort [dict keys $deplist]] {
    set path {}
    draw_func $deplist $key $out
    puts $out "\n"
    puts $out ""
}
close $out

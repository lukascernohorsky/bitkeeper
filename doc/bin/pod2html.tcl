#!/usr/bin/env tclsh

proc usage {prog msg} {
    if {$msg ne ""} {
        puts stderr $msg
    }
    puts stderr "usage: $prog <filename>"
    exit 1
}

proc die {msg} {
    puts stderr $msg
    exit 1
}

proc output {s} {
    global template body
    if {$template eq ""} {
        puts $s
    } else {
        lappend body $s
    }
}

proc header {title} {
    set head [join {
<html>
<head>
<title>%s</title>
<style>
pre {
        background: #eeeedd;
        border-width: 1px;
        border-style: solid solid solid solid;
        border-color: #ccc;
        padding: 5px 5px 5px 5px;
        font-family: monospace;
        font-weight: bolder;
}
</style>
</head>
<body>
} "\n"]
    puts [format $head $title]
}

proc inline {buf} {
    # sleazy fixes that sort of work
    regsub -all {<<} $buf {&lt;&lt;} buf
    if {![regexp {[BCFILS]<.+>} $buf]} {
        regsub -all {<} $buf {&lt;} buf
        regsub -all {>} $buf {&gt;} buf
        return $buf
    }

    set prev ""
    set result ""
    set link ""
    set stack {}
    set B 0
    set C 0
    set I 0
    set L 0
    set S 0

    foreach c [split $buf ""] {
        if {$c eq "<" && $prev ne ""} {
            switch -- $prev {
                B {
                    if {$B > 0} { die "Nested B<> unsupported: $buf" }
                    incr B
                    if {[string length $result] > 0} {
                        set result [string range $result 0 end-1]
                    }
                    append result "<b>"
                    lappend stack "B"
                }
                C {
                    if {$C > 0} { die "Nested C<> unsupported: $buf" }
                    incr C
                    if {[string length $result] > 0} {
                        set result [string range $result 0 end-1]
                    }
                    append result "<code>"
                    lappend stack "CODE"
                }
                I -
                F {
                    if {$I > 0} { die "Nested I<> unsupported: $buf" }
                    incr I
                    if {[string length $result] > 0} {
                        set result [string range $result 0 end-1]
                    }
                    append result "<i>"
                    lappend stack "I"
                }
                L {
                    if {$L > 0} { die "Nested L<> unsupported: $buf" }
                    incr L
                    if {[string length $result] > 0} {
                        set result [string range $result 0 end-1]
                    }
                    append result "<a href=\""
                    set link ""
                    lappend stack "L"
                }
                S {
                    if {$S > 0} { die "Nested S<> unsupported: $buf" }
                    incr S
                    if {[string length $result] > 0} {
                        set result [string range $result 0 end-1]
                    }
                    lappend stack "S"
                }
                default {
                    append result $c
                    set prev $c
                }
            }
        } elseif {$c eq ">" && [llength $stack]} {
            set token [lindex $stack end]
            set stack [lrange $stack 0 end-1]
            switch -- $token {
                B { incr B -1 }
                CODE { incr C -1 }
                I { incr I -1 }
                L {
                    incr L -1
                    append result "\">$link</a>"
                    set token ""
                }
                S {
                    incr S -1
                    set token ""
                }
            }
            if {$token ne ""} {
                append result "</[string tolower $token]>"
            }
            set prev ""
        } else {
            if {$S && [string is space -strict $c]} {
                append result "&nbsp;"
            } else {
                append result $c
            }
            if {$L} { append link $c }
            set prev $c
        }
    }
    return $result
}

# --- main ---
set body {}
set template ""
set title ""
set TOC 0

set argvCopy $argv
set idx 0
while {$idx < [llength $argvCopy]} {
    set arg [lindex $argvCopy $idx]

    # End-of-options marker (common POSIX/GNU convention).
    # Example from make:
    #   pod2html.tcl --title="..." --template=... -- nested.doc
    if {$arg eq "--"} {
        incr idx
        break
    }

    if {$arg eq "--TOC"} {
        set TOC 1
        incr idx
        continue
    }
    if {[regexp {^--title=(.*)} $arg -> val]} {
        set title $val
        incr idx
        continue
    }
    if {$arg eq "--title"} {
        if {$idx + 1 >= [llength $argvCopy]} { usage [file tail [info script]] "" }
        set title [lindex $argvCopy [expr {$idx + 1}]]
        incr idx 2
        continue
    }
    if {[regexp {^-t(.*)} $arg -> val]} {
        if {$val eq ""} {
            if {$idx + 1 >= [llength $argvCopy]} { usage [file tail [info script]] "" }
            set title [lindex $argvCopy [expr {$idx + 1}]]
            incr idx 2
        } else {
            set title $val
            incr idx
        }
        continue
    }
    if {[regexp {^--template=(.*)} $arg -> val]} {
        set template $val
        incr idx
        continue
    }
    if {$arg eq "--template"} {
        if {$idx + 1 >= [llength $argvCopy]} { usage [file tail [info script]] "" }
        set template [lindex $argvCopy [expr {$idx + 1}]]
        incr idx 2
        continue
    }
    break
}

set filename [lindex $argvCopy $idx]
if {$filename eq ""} {
    usage [file tail [info script]] ""
}
if {[catch {open $filename r} f err]} {
    die "cannot open input file '$filename': $err"
}
if {$title eq ""} {
    set title $filename
}

if {$template eq ""} {
    header $title
}

set all {}
set toc {"<ul id=\"toc\">"}
set contents {}
set ul 1
while {[gets $f buf] >= 0} {
    if {[regexp {^#} $buf]} { continue }
    lappend all $buf
    if {[regexp {^=head(\d+)\s+(.*)} $buf -> level heading]} {
        set indent ""
        for {set i 1} {$i < $level} {incr i} { append indent "    " }
        lappend contents "$indent$heading"

        while {$ul > $level} {
            lappend toc "</ul>"
            incr ul -1
        }
        while {$level > $ul} {
            lappend toc "<ul>"
            incr ul
        }

        set tmp $heading
        regsub -all {\s+} $tmp {_} tmp
        set label $buf
        regsub {^=head\d+\s+} $label {} label
        lappend toc "<li class=\"tocitem\"><a href=\"#$tmp\">$label</a></li>"
    }
}
while {$ul > 0} {
    lappend toc "</ul>"
    incr ul -1
}
close $f

if {$TOC} {
    foreach buf $contents { puts $buf }
    exit 0
}

set space 0
set dd 0
set p 0
set pre 0
set tr 0
set trim ""
for {set i 0} {$i <= [llength $all]} {incr i} {
    set raw [lindex $all $i]
    set buf [inline $raw]
    if {[regexp {^=toc} $buf]} {
        output [join $toc "\n"]
    } elseif {[regexp {^=head(\d+)\s+(.*)} $buf -> level heading]} {
        if {$level == 1} { output "<hr>" }
        set tmp $heading
        regsub -all {\s+} $tmp {_} tmp
        set line [format "<h%d><a name=\"%s\">%s</a></h%d>\n" $level $tmp $heading $level]
        output $line
    } elseif {[regexp {^=over} $buf]} {
        output "<dl>"
    } elseif {[regexp {^=item\s+(.*)} $buf -> item]} {
        if {$dd} {
            output "</dd>"
            incr dd -1
        }
        output "<dt><strong>${item}</strong></dt><dd>"
        incr dd
    } elseif {[regexp {^=options$} $buf]} {
        output "<table>"
    } elseif {[regexp {^=option\s+(.*)} $buf -> item]} {
        if {$tr} {
            output "</td>"
            output "</tr>"
            incr tr -1
        }
        output "<tr>"
        output "<td><strong>${item}</strong></td>"
        output "<td>"
        incr tr
    } elseif {[regexp {^=options_end$} $buf]} {
        if {$tr} {
            output "</td>"
            output "</tr>"
            incr tr -1
        }
        output "</table>"
    } elseif {[regexp {^=proto\s+([^ \t]+)\s+(.*)} $buf -> ret proto]} {
        if {$dd} {
            output "</dd>"
            incr dd -1
        }
        output "<dt><b>${ret} ${proto}</b></dt><dd>"
        incr dd
    } elseif {[regexp {^=back} $buf]} {
        if {$dd} {
            output "</dd>"
            incr dd -1
        }
        output "</dl>"
    } elseif {[regexp {^=include\s+(.*)} $buf -> file]} {
        if {![file exists $file]} {
            puts stderr "file not found: ${file}"
            exit 1
        }
        set f [open $file r]
        set tmp [read $f]
        close $f
        output $tmp
    } elseif {[regexp {^\s*$} $buf]} {
        if {$p} {
            output "</p>"
            set p 0
        }
        if {$pre} {
            set next [lindex $all [expr {$i + 1}]]
            if {$next ne "" && [regexp {^\s} $next]} {
                output ""
                continue
            }
            output "</pre>"
            set pre 0
            set trim ""
        }
        set space 1
    } else {
        if {$space} {
            if {[regexp {^(\s+)[^ \t]+} $buf -> indent]} {
                set trim $indent
                output "<pre class=\"code\">"
                set pre 1
            } else {
                output "<p>"
                set p 1
            }
            set space 0
        }
        if {$trim ne ""} {
            regsub "^${trim}" $buf {} buf
        }
        output $buf
    }
}

if {$template eq ""} {
    output "</body></html>"
} else {
    if {[catch {open $template r} tf]} {
        die "cannot open template: $template"
    }
    set t [read $tf]
    close $tf

    set map [list \
        %TITLE% $title \
        %TOC% [join $toc "\n"] \
        %BODY% [join $body "\n"]]
    puts [string map $map $t]
}

exit 0

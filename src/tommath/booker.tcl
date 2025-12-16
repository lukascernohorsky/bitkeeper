#!/usr/bin/env tclsh
# Tcl rewrite of booker.pl
# Preprocess tommath.src into tommath.tex by expanding code examples, figures,
# and index markers without relying on Perl.

proc usage {} {
    puts "Usage: booker.tcl [PDF]"
    exit 1
}

# Determine graphics extension based on first argument (PDF -> none, else .ps)
set graph ".ps"
if {[llength $argv] > 0 && [string match *PDF* [lindex $argv 0]]} {
    set graph ""
}

set srcFile "tommath.src"
set outFile "tommath.tex"

if {[catch {set in [open $srcFile r]}]} {
    puts stderr "Can't open source file"
    exit 1
}
puts "Scanning for sections"
set chapter 0
set section 0
set subsection 0
array set index1 {}
array set index2 {}
array set index3 {}
set x 0
while {[gets $in line] >= 0} {
    puts -nonewline "."
    incr x
    if {($x % 80) == 0} {puts ""}
    if {[regexp {\\chapter{.+}} $line]} {
        incr chapter
        set section 0
        set subsection 0
    } elseif {[regexp {\\section{.+}} $line]} {
        incr section
        set subsection 0
    } elseif {[regexp {\\subsection{.+}} $line]} {
        incr subsection
    }
    if {[string match *MARK* $line]} {
        set m [split $line ,]
        set tag [string trim [lindex $m 1]]
        set index1($tag) $chapter
        set index2($tag) $section
        set index3($tag) $subsection
    }
}
close $in
puts ""

if {[catch {set in [open $srcFile r]}]} {
    puts stderr "Can't open source file"
    exit 1
}
if {[catch {set out [open $outFile w]}]} {
    puts stderr "Can't open destination file"
    exit 1
}

set readline 0
set wroteline 0
set srcline 0
set text {}
set totlines 0

proc emitWrapped {out prefix textVar wlineVar} {
    upvar 1 $textVar textLine $wlineVar wlines
    set col 0
    puts -nonewline $out $prefix
    foreach ch [split $textLine {}] {
        puts -nonewline $out $ch
        incr col
        if {$col == 76} {
            puts $out ""
            puts -nonewline $out "      "
            incr wlines
            set col 0
        }
    }
    puts $out ""
    incr wlines
}

while {[gets $in line] >= 0} {
    incr readline
    incr srcline
    if {[string match *MARK* $line]} {
        continue
    } elseif {[string match *EXAM* $line] || [string match *LIST* $line]} {
        set skipheader [expr {[string match *EXAM* $line] ? 1 : 0}]
        set parts [split [string trim $line] ,]
        set fileName [lindex $parts 1]
        if {[catch {set src [open $fileName r]}]} {
            puts stderr "Error:$srcline:Can't open source file $fileName"
            exit 1
        }
        puts "$srcline:Inserting $fileName:"
        set text {}
        set lineNo 0
        set inline 0
        set tmp $fileName
        regsub -all {_} $tmp {\\_} tmp
        puts $out "\\vspace{+3mm}\\begin{small}\n\\hspace{-5.1mm}{\\bf File}: $tmp\n\\vspace{-3mm}\n\\begin{alltt}\n"
        incr wroteline 5

        if {$skipheader} {
            while {[gets $src sline] >= 0} {
                lappend text $sline
                incr lineNo
                if {[string match *math.libtomcrypt.com* $sline]} {break}
            }
            gets $src
        }

        while {[gets $src sline] >= 0} {
            if {[string match *\$Source* $sline] || [string match *\$Revision* $sline] || [string match *\$Date* $sline]} {
                continue
            }
            lappend text $sline
            incr lineNo
            incr inline
            set mod $sline
            regsub -all {\t} $mod {    } mod
            regsub -all {\{} $mod {^{ } mod
            regsub -all {\}} $mod {^}} mod
            regsub -all {\\} $mod {'\symbol{92}'} mod
            regsub -all {\^} $mod {\\} mod
            set prefix [format "%03d   " $lineNo]
            emitWrapped $out $prefix mod wroteline
        }
        set totlines $lineNo
        puts $out "\\end{alltt}\n\\end{small}\n"
        close $src
        puts "$inline lines"
        incr wroteline 2
    } elseif {[regexp {@\d+,.+@} $line]} {
        set txt $line
        while {[regexp {@\d+,.+@} $txt]} {
            set m [split $txt @]
            set parms [split [lindex $m 1] ,]
            set ref [lindex $parms 0]
            set needle [lindex $parms 1]
            set foundline1 0
            set foundline2 0
            for {set i $ref} {$i < $totlines && !$foundline1} {incr i} {
                if {[string match *$needle* [lindex $text $i]]} {
                    set foundline1 [expr {$i + 1}]
                }
            }
            for {set i [expr {$ref - 1}]} {$i >= 0 && !$foundline2} {incr i -1} {
                if {[string match *$needle* [lindex $text $i]]} {
                    set foundline2 [expr {$i + 1}]
                }
            }
            set foundline 0
            if {$foundline1 && !$foundline2} {
                set foundline $foundline1
            } elseif {!$foundline1 && $foundline2} {
                set foundline $foundline2
            } elseif {$foundline1 && $foundline2} {
                if {($foundline1 - $ref) <= ($ref - $foundline2)} {
                    set foundline $foundline1
                } else {
                    set foundline $foundline2
                }
            }
            if {$foundline} {
                set delta [expr {$ref - $foundline}]
                puts "Found replacement tag for \"$needle\" on line $srcline which refers to line $foundline (delta $delta)"
                set needleEsc $needle
                regsub -all {([][$.^*+?{}()|\\])} $needleEsc {\\\1} needleEsc
                set pattern [format {@%s,%s@} $ref $needleEsc]
                regsub -- $pattern $line $foundline line
            } else {
                puts "ERROR:  The tag \"$needle\" on line $srcline was not found in the most recently parsed source!"
            }
            set txt [join [lrange $m 2 end] @]
        }
        puts $out $line
        incr wroteline
    } elseif {[regexp {~.+~} $line]} {
        set txt $line
        while {[regexp {~.+~} $txt]} {
            set m [split $txt ~]
            set word [lindex $m 1]
            set a [expr {[info exists index1($word)] ? $index1($word) : 0}]
            set b [expr {[info exists index2($word)] ? $index2($word) : 0}]
            set c [expr {[info exists index3($word)] ? $index3($word) : 0}]
            if {$a == 0} {
                puts "ERROR: the tag \"$word\" on line $srcline was not found previously marked."
            } else {
                set str $a
                if {$b != 0} {append str ".$b"}
                if {$c != 0} {append str ".$c"}
                if {$b == 0 && $c == 0} {
                    if {$a <= 10} {
                        set names [list "chapter one" "chapter two" "chapter three" "chapter four" "chapter five" "chapter six" "chapter seven" "chapter eight" "chapter nine" "chapter ten"]
                        set str [lindex $names [expr {$a - 1}]]
                    } else {
                        set str "chapter $str"
                    }
                } else {
                    if {$b != 0 && $c == 0} {set str "section $str"}
                    if {$b != 0 && $c != 0} {set str "sub-section $str"}
                }
                regsub ~${word}~ $line $str line
                puts "Found replacement tag for marker \"$word\" on line $srcline which refers to $str"
            }
            set txt [join [lrange $m 2 end] ~]
        }
        puts $out $line
        incr wroteline
    } elseif {[string match *FIGU* $line]} {
        set parts [split [string trim $line] ,]
        set figHeader [format {\\begin{center}
\\begin{figure}[here]
\\includegraphics{pics/%s%s}
} [lindex $parts 1] $graph]
        puts $out $figHeader
        set figFooter [format {\\caption{%s}
\\label{pic:%s}
\\end{figure}
\\end{center}
} [lindex $parts 2] [lindex $parts 1]]
        puts $out $figFooter
        incr wroteline 4
    } else {
        puts $out $line
        incr wroteline
    }
}
puts "Read $readline lines, wrote $wroteline lines"
close $out
close $in

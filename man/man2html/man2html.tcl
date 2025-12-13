#!/usr/bin/env tclsh

proc warn {msg args} {
    if {[llength $args]} {
        puts stderr [format $msg {*}$args]
    } else {
        puts stderr $msg
    }
}

proc die {msg} {
    warn $msg
    exit 1
}

proc slurp {path} {
    if {[catch {open $path r} f]} {
        die "cannot open $path"
    }
    set data [read $f]
    close $f
    return $data
}

proc build_nav_cache {} {
    global toplevels topics sections
    foreach toplevel $toplevels {
        set file "../man2help/${toplevel}.done"
        if {[catch {open $file r} fp]} {
            continue
        }
        while {[gets $fp line] >= 0} {
            if {![regexp {\s+bk(.*?) -} $line -> topic]} continue
            set topic [string trim $topic]
            if {$topic eq ""} { set topic "bk" }
            dict lappend topics $topic $toplevel
            dict lappend sections $toplevel $topic
        }
        close $fp
    }
}

proc nav {out topic} {
    global toplevels topics sections
    set section ""
    set items {}
    if {[lsearch -exact $toplevels $topic] > -1} {
        set section $topic
        if {[dict exists $sections $topic]} {
            set items [dict get $sections $topic]
        }
    } elseif {[dict exists $topics $topic]} {
        set section [lindex [dict get $topics $topic] end]
        if {$section ne "" && [dict exists $sections $section]} {
            set items [dict get $sections $section]
        }
    }
    if {$section eq ""} return

    puts $out "<div id='sidebar'>"
    puts $out "<a href='index.html' border='0'>" \
        "<img src='BitKeeper_SN_Blue.png' width='50'>" \
        "</a>"
    puts $out "<div><strong>${section}</strong></div>"
    puts $out "<ul>"
    foreach t $items {
        puts $out "<li>"
        puts $out "<a class='async' href='${t}.html'>${t}</a>"
        puts $out "</li>"
    }
    puts $out "</ul>"
    puts $out "</div>"
}

proc fixup {bufVar} {
    upvar 1 $bufVar buf
    regsub -all {popu-late} $buf {populate} buf
    regsub -all {unpopulate} $buf {here} buf
    regsub -all {populate} $buf {here} buf
    regsub -all {tags} $buf {changes} buf

    switch -regexp -- $buf {
        {make\(1\)} -
        {diff\(1\)} -
        {diff3\(1\)} -
        {notes/rfc934\.txt} { return 1 }
    }
    return 0
}

proc page {out buf} {
    global references
    set indent ""
    if {[regexp {^(\s+)} $buf -> ind]} {
        set indent $ind
    }
    regsub -all { \s+} $buf { } buf

    set help {}
    if {[regexp {bk\s+-\s+BitKeeper\s+configuration\s+management} $buf]} {
        set help {bk}
    } else {
        set re {bk help ([A-Za-z0-9\-]+)}
        set start 0
        while {[regexp -indices -start $start $re $buf matchIdx capIdx]} {
            set start [expr {[lindex $matchIdx 1] + 1}]
            set name [string range $buf [lindex $capIdx 0] [lindex $capIdx 1]]
            lappend help $name
        }
    }

    foreach h $help {
        if {[regexp {^\s*$} $h]} continue
        regsub -all {\s+} $h {} h
        regsub -all {,} $h {} h

        if {[fixup h]} continue
        puts $out [format "%s<a class='async' href=\"%s.html\">bk %s</a>\n" \
            $indent $h $h]
        lappend references "$h.html"
    }
    puts $out ""
}

proc category {out buf} {
    global references
    if {![regexp {(\s+)(.*)} $buf -> spaces topic]} {
        return
    }
    if {[fixup topic]} return
    puts $out [format "%s<a href=\"%s.html\">%s</a>\n" $spaces $topic $topic]
    lappend references "$topic.html"
}

proc section {out buf} {
    global references
    if {[regexp {^\s+bk\s+([a-zA-Z0-9\-]+)( \- .*)} $buf -> name rest]} {
        if {[fixup name]} return
        puts $out [format "  <a class='async' href=\"%s.html\">bk %s</a>%s\n" \
            $name $name $rest]
        lappend references "$name.html"
    } elseif {[regexp {^\s+bk( \- .*)} $buf -> rest]} {
        puts $out [format "  <a class='async' href=\"bk.html\">bk</a>%s\n" $rest]
    } else {
        warn $buf
        die "unexpected section format"
    }
}

proc html {file} {
    global index references
    set style [slurp "style.css"]

    if {[catch {open $file r} in]} {
        die "cannot open $file"
    }

    set topic [file tail $file]
    regsub {^bk-} $topic {} topic
    regsub {-1\.fmt$} $topic {} topic

    set done 0
    set desc ""
    if {[regexp {\.done$} $topic]} {
        set done 1
        regsub {\.done$} $topic {} topic
        set desc [slurp "../man2help/${topic}.description"]
        regsub {^.SH DESCRIPTION\n} $desc {} desc
        regsub {\\\*\(BK} $desc {BitKeeper} desc
    }

    set outPath "www/${topic}.html"
    set bodyPath "www/${topic}_body.html"
    if {[catch {open $outPath w} out] || [catch {open $bodyPath w} body]} {
        die "cannot open output paths"
    }

    warn "Htmlify %s\n" $outPath

    if {$done} {
        puts $index "<tr><td>"
        puts $index [format "<a href=\"%s.html\">%s</a><br>" $topic $topic]
        puts $index "</td><td>"
        puts $index "$desc\n"
        puts $index "</td></tr>"
    }

    set head [join {
            <!DOCTYPE html>
            <html>
            <head>
            <title>%s | BitKeeper Documentation</title>
            <style>%s</style>
            </head>
            <body>
        } "\n"]
    puts $out [format $head $topic $style]

    nav $out $topic

    puts $out "<div id='content'>"
    puts $out "<pre>"
    puts $body "<pre>"

    set see_also 0
    while {[gets $in buf] >= 0} {
        set reprocess 1
        while {$reprocess} {
            set reprocess 0
            regsub -all {<} $buf {\&lt;} buf
            regsub -all {>} $buf {\&gt;} buf
            if {[regexp {^\$$} $buf]} {
                break
            } elseif {[regexp {^help://} $buf]} {
                break
            } elseif {[regexp {(.*)(BitKeeper\s+User's\s+Manual)(.*)} $buf]} {
                puts $out "<b>${buf}</b>\n\n"
                puts $body "<b>${buf}</b>\n\n"
                while {[gets $in buf] >= 0} {
                    if {![regexp {^\s*$} $buf]} {
                        set reprocess 1
                        break
                    }
                }
                if {!$reprocess} {
                    set buf ""
                }
            } elseif {[regexp {^[a-zA-Z]+.*} $buf]} {
                puts $out "<strong>${buf}</strong>"
                puts $body "<strong>${buf}</strong>"
            } elseif {[regexp {bk help ([a-zA-Z0-9]+)} $buf]} {
                if {$see_also} {
                    set p ""
                    while {[gets $in p] >= 0} {
                        if {[regexp {^\s*$} $p]} break
                        append buf " $p"
                    }
                    page $out $buf
                    page $body $buf
                }
            } elseif {[regexp {^  bk [a-zA-Z0-9\-]+ - } $buf]} {
                section $out $buf
                section $body $buf
            } elseif {[regexp {^  bk - } $buf]} {
                section $out $buf
                section $body $buf
            } else {
                puts $out "${buf}\n"
                puts $body "${buf}\n"
            }
            if {$reprocess} {
                continue
            }
        }

        if {[regexp {SEE ALSO} $buf]} { incr see_also }
        if {[regexp {^CATEGORY} $buf]} {
            while {[gets $in buf] >= 0} {
                if {[regexp {^\s*$} $buf]} break
                category $out $buf
                category $body $buf
            }
            puts $out ""
            puts $body ""
        }
    }

    close $in

    puts $body "</pre>"
    close $body

    set js [slurp "manpages.js"]

    puts $out "</pre>"
    puts $out $js
    puts $out "</div></body>\n</html>"
    close $out
}

# --- main ---
set index [open "www/index.html" w]
puts $index "<html>"
puts $index "<body bgcolor=white>"
set buf ""
for {set i 0} {$i < 20} {incr i} { append buf "&nbsp;" }
puts $index "<table>"
puts $index "<table><tr><td style='width:6em;'><a href=index.html border=0><img src=BitKeeper_SN_Blue.png width=50></a></td><td><b>BitKeeper Documentation</b></td></tr>"

set topics [dict create]
set sections [dict create]
set references {}
set first {All Overview Common}
set toplevels {All Overview Common Admin Compat File GUI-tools Nested Repository Utility}

build_nav_cache

set files [lsort [glob -nocomplain ../man2help/*.fmt]]
foreach file $files { html $file }

foreach file $first {
    html "../man2help/${file}.done"
}

foreach file [lsort [glob -nocomplain ../man2help/*.done]] {
    set skip 0
    foreach entry $first {
        if {$file eq "../man2help/${entry}.done"} {
            set skip 1
        }
    }
    if {!$skip} { html $file }
}

puts $index "</table>"
puts $index "<p align=center><img src=BitKeeper_SN_SVC_Blue.png width=150>"
puts $index "</p></body>\n</html>"
close $index

set firstWarn 1
foreach ref $references {
    if {![file exists "www/${ref}"]} {
        if {$firstWarn} {
            warn "\nWARNING some links are bad:\n"
            set firstWarn 0
        }
        warn $ref
    }
}

exit 0

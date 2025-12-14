#!/usr/bin/env tclsh

if {$argc == 0} {
    puts stderr "usage: [file tail $argv0] files..."
    exit 1
}

puts {<!DOCTYPE html>
<html>
<head>
<script type="text/javascript" src="http://code.jquery.com/jquery-1.11.2.min.js"></script>
<script type="text/javascript" src="http://cdn.ucb.org.br/Scripts/tablesorter/jquery.tablesorter.min.js"></script>
</head>
<body>
<table id="myTable" class="tablesorter">
<thead>
<tr>
    <th>Name</th>
    <th>Description</th>
    <th>Last Modified</th>
</tr>
</thead>
<tbody>
}

foreach f $argv {
    set name $f
    regsub -nocase {\.adoc$} $name "" name

    puts "<tr>"
    puts "\t<td><A href=\"$name.html\">$name</A></td>"

    if {[catch {open $f r} fh]} {
        puts stderr "unable to open $f: $fh"
        exit 1
    }
    set desc ""
    if {[gets $fh line] >= 0} {
        set desc $line
    }
    close $fh

    puts "\t<td>$desc</td>"

    set stamp [string trimright [exec bk prs -hnd':D: :T:' $f] "\n"]
    puts "\t<td>$stamp</td>"
    puts "</tr>"
}

puts {</tbody>
</table>
<script>
$(document).ready(function()
    {
        $("#myTable").tablesorter();
    }
);
</script>
</body>
</html>}

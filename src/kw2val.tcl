#!/usr/bin/env tclsh
# Tcl replacement for kw2val.pl
# Parses slib.c to extract kw2val() keywords and generates kw2val_lookup.c

set gperf "/usr/local/bin/gperf"
if {![file executable $gperf]} {
    set gperf "gperf"
}

set use_sizet 1
set gperf_ok 0
if {![catch {set ver [exec $gperf --version]}]} {
    if {[regexp {^GNU gperf 3} $ver]} {
        set gperf_ok 1
        if {[regexp {^GNU gperf 3\.[1-9]} $ver]} {
            set use_sizet 1
        }
    }
}

set c [open "kw2val_lookup.c" w]
if {$use_sizet} {
    puts $c "struct kwval *kw2val_lookup(const char *str, size_t len);"
} else {
    puts $c "struct kwval *kw2val_lookup(const char *str, unsigned int len);"
}
close $c

set in 0
set keywords {}
set fh stdin
if {[llength $argv] > 0} {
    set fh [open [lindex $argv 0] r]
}

while {[gets $fh line] >= 0} {
    if {!$in && ![regexp {^kw2val} $line]} {
        continue
    }
    if {[regexp {^\}} $line]} {
        set in 0
        continue
    }
    set in 1
    if {[regexp {^\tcase KW_([A-Za-z0-9_]+): /\* ([^*]*) \*/} $line -> enum kw]} {
        lappend keywords [list $enum [string trim $kw]]
    }
}
if {$fh ne "stdin"} {
    close $fh
}

set c [open "kw2val_lookup.c" a]
puts $c "/* !!! automatically generated file !!! Do not edit. */"
puts $c "#include \"system.h\""
puts $c "struct kwval { char *name; int kwnum; };"
puts $c "enum {"
foreach pair $keywords {
    puts $c "    KW_[lindex $pair 0],"
}
puts $c "};\n"
puts $c "static struct kwval kw_table\[\] = {"
foreach pair $keywords {
    puts $c "    { \"[lindex $pair 1]\", KW_[lindex $pair 0] },"
}
puts $c "};\n"
set len_type [expr {$use_sizet ? "size_t" : "unsigned int"}]
set hash_line [format {    for (%s i = 0; i < len; i++) h = (h * 33) + (unsigned char)str[i];} $len_type]
set size_line [format {    size_t n = sizeof(kw_table)/sizeof(kw_table[%s]);} 0]
set loop_line "    for (size_t i = 0; i < n; i++) {"
set cmp_line [format {        if (strlen(kw_table[%s].name) == len && !memcmp(kw_table[%s].name, str, len)) return &kw_table[%s];} i i i]

puts $c [format "static unsigned int kw2val_hash(const char *str, %s len) {" $len_type]
puts $c "    unsigned int h = 0;"
puts $c $hash_line
puts $c "    return h;"
puts $c "}\n"
puts $c [format "struct kwval *kw2val_lookup(const char *str, %s len) {" $len_type]
puts $c $size_line
puts $c $loop_line
puts $c $cmp_line
puts $c "    }"
puts $c {    return 0;}
puts $c "}"
close $c

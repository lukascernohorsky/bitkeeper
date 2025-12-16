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

if {$gperf_ok} {
    set c [open "|$gperf -c >> kw2val_lookup.c" w]
    puts $c "%{"
    puts $c "enum {"
    foreach pair $keywords {
        set enum [lindex $pair 0]
        puts $c "\tKW_$enum,"
    }
    puts $c "};"
    puts $c "%}"
    puts $c "%struct-type"
    puts $c "%language=ANSI-C"
    puts $c "%define lookup-function-name kw2val_lookup"
    puts $c "%define hash-function-name kw2val_hash"
    puts $c ""
    puts $c "struct kwval { char *name; int kwnum; };"
    puts $c "%%"
    foreach pair $keywords {
        puts $c "[lindex $pair 1],\tKW_[lindex $pair 0]"
    }
    close $c
} else {
    set c [open "kw2val_lookup.c" a]
    puts $c "/* !!! automatically generated file !!! Do not edit. */"
    puts $c "#include \"system.h\""
    puts $c "struct kwval { char *name; int kwnum; };"
    puts $c "enum {"
    foreach pair $keywords {
        puts $c "    KW_[lindex $pair 0],"
    }
    puts $c "};\n"
    puts $c "static struct kwval kw_table[] = {"
    foreach pair $keywords {
        puts $c "    { \"[lindex $pair 1]\", KW_[lindex $pair 0] },"
    }
    puts $c "};\n"
    set len_type [expr {$use_sizet ? "size_t" : "unsigned int"}]
    puts $c "static unsigned int kw2val_hash(const char *str, $len_type len) {"
    puts $c "    unsigned int h = 0;"
    puts $c "    for ($len_type i = 0; i < len; i++) h = (h * 33) + (unsigned char)str[i];"
    puts $c "    return h;"
    puts $c "}\n"
    puts $c "struct kwval *kw2val_lookup(const char *str, $len_type len) {"
    puts $c "    size_t n = sizeof(kw_table)/sizeof(kw_table[0]);"
    puts $c "    for (size_t i = 0; i < n; i++) {"
    puts $c "        if (strlen(kw_table[i].name) == len && !memcmp(kw_table[i].name, str, len)) return &kw_table[i];"
    puts $c "    }"
    puts $c "    return 0;"
    puts $c "}"
    close $c
}

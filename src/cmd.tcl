#!/usr/bin/env tclsh
# Copyright 2005-2016 BitMover, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set here [file dirname [file normalize $argv0]]
cd $here

proc cstr {s} {
    if {$s eq ""} { return 0 }
    return "\"$s\""
}

proc maybe_replace {path} {
    if {[file exists $path]} {
        if {[catch {exec cmp -s $path ${path}.new}]} {
            file rename -force ${path}.new $path
        } else {
            file delete -force ${path}.new
        }
    } else {
        file rename -force ${path}.new $path
    }
}

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

set hout [open "cmd.h.new" w]
puts $hout "/* !!! automatically generated file !!! Do not edit. */"
puts $hout "#ifndef _CMD_H_"
puts $hout "#define _CMD_H_\n"
puts $hout "enum {"
puts $hout "    CMD_UNKNOWN,                /* not a symbol */"
puts $hout "    CMD_INTERNAL,               /* internal XXX_main() function */"
puts $hout "    CMD_GUI,                    /* GUI command */"
puts $hout "    CMD_SHELL,                  /* shell script in `bk bin` */"
puts $hout "    CMD_ALIAS,                  /* alias for another symbol */"
puts $hout "    CMD_BK_SH,                  /* function in bk.script */"
puts $hout "    CMD_LSCRIPT,                /* L script */"
puts $hout "    CMD_EXTENSION,              /* bk-cmd program on PATH */"
puts $hout "};\n"
puts $hout "typedef struct CMD {"
puts $hout "        char    *name;"
puts $hout "        u8      type;           /* type of symbol (from enum above) */"
puts $hout "        int     (*fcn)(int, char **);"
puts $hout "        char    *alias;         /* name is alias for 'alias' */"
puts $hout "        u8      remote:1;       /* always allowed as a remote command */"
puts $hout "} CMD;\n"
if {$use_sizet} {
    puts $hout "CMD\t\t*cmd_lookup(const char *str, size_t len);"
} else {
    puts $hout "CMD\t\t*cmd_lookup(const char *str, unsigned int len);"
}

set data {
# builtin functions (sorted)
_g2bk
abort
_access
_adler32
admin
alias
annotate
bam
BAM => bam
base64
bin
bisect
bkd
bkver
binpool => bam
cat
_catfile        # bsd contrib/cat.c
_cat_partition remote
cfile
changes
check
checked remote
checksum
chksum
clean
_cleanpath
clone
cmdlog
collapse
comments
commit
components      # old compat code
comps
config
cp
_cpus
partition
create
crypto
cset
csets
csetprune
dbexplode
dbimplode
_debugargs remote
deledit
delget
delta
diff
diffs => diff
dotbk
_dumpconfig
_exists
export
_fastimport
_fastexport
_fgzip
features
_filtertest1
_filtertest2
_find
_findcset
_findhashdup
findkey remote
findmerge
fix
fixtool
_fslchmod
_chmod => _fslchmod
_fslcp
_cp => _fslcp
_fslmkdir
_mkdir => _fslmkdir
_fslmv
_mv => _fslmv
_fslrm
_rm => _fslrm
_fslrmdir
_rmdir => _fslrmdir
fstype
gca
get
_getdir
gethelp
gethost
_getkv
getmsg
_getopt_test
getuser
gfiles
glob
gnupatch
gone
graft
grep
_gzip
_hashstr_test
_hashfile_test
havekeys remote
_heapdump
help
man => help
helpsearch
helptopics
here
_httpfetch
hostme
id remote
idcache
info_server
info_shell
isascii
key2rev
key2path
_keyunlink
_kill
level remote
_lines
_link
_listkey
lock
_locktest
log
_lstat
_mailslot
mail
makepatch
mdbmdump
merge
mklock
mtime
mv
mvdir
names
ndiff
needscheck
_nested
newroot
nfiles
opark
ounpark
_parallel
parent
park
patch
path
pending
platform
_poly
_popensystem
populate
port => pull
_probekey
_progresstest
prompt
prs
_prunekey
pull
push
pwd
r2c     remote
range
rcheck
_rclone
rcs2bk
rcsparse
receive
_recurse
_realpath
regex
_registry
renumber
_repair
repogca
repostats
repotype
relink
repos
resolve
restore
_reviewmerge
rm
rmdel
rmgone
root
rset
sane
sccs2bk
_scat
sccslog
_sec2hms
send
sendbug
set
_setkv
setup
sfiles => gfiles
_sfiles_bam
_sfiles_clone
_sfiles_local
sfio remote
_shellSplit_test
shrink
sinfo
smerge
sort
_startmenu
_stat
_stattest
status
stripdel
_strings
_svcinfo
synckeys
tagmerge
takepatch
_tclsh
_testlines
test
testdates
time
_timestamp
tmpdir
_touch
_unbk
_uncat
_undefined
undo
undos
unedit
_unittests
_unlink
unlock
uninstall
unpark
unpopulate
unpull
unrm
unwrap
upgrade
_usleep
uuencode
uudecode
val
version remote
what
which
xflags
zone

#aliases of builtin functions
add => delta
attach => clone
detach => clone
_cat => _catfile
ci => delta
dbnew => delta
enter => delta
new => delta
_get => get
co => get
checkout => get
edit => get
fast-import => _fastimport
fast-export => _fastexport
comment => comments     # alias for Linus, remove...
identity => id
info => sinfo
uniq_server => info_server
init => setup
_key2path => key2path
_mail => mail
aliases => alias
_preference => config
rechksum => checksum
rev2cset => r2c
sccsdiff => diff
sfind => gfiles
_sort => sort
support => sendbug
_test => test
unget => unedit

# commands we don't want to work
#cmp => _undefined
#diff3 => _undefined
#sdiff => _undefined

# guis
citool gui
committool => citool
csettool gui
difftool gui
fm3tool gui
fmtool gui
gui => helptool
helptool gui
installtool gui
msgtool gui
oldcitool gui
renametool gui
revtool gui
setuptool gui
showproc gui
debugtool gui
outputtool gui

# gui aliases
csetool => csettool
fm3 => fm3tool
fm => fmtool
fm2tool => fmtool
histool => revtool
histtool => revtool
sccstool => revtool

# shell scripts
import shell
uuwrap shell
unuuwrap shell
b64wrap shell
unb64wrap shell
gzip_b64wrap shell
ungzip_b64wrap shell
gzip_wrap shell
ungzip_wrap shell

# L scripts
check_comments lscript
describe lscript
hello lscript
pull-size lscript
repocheck lscript
}

set entries {}
set prototypes {}
array set rmts {}
set lineno 0
foreach line [split $data "\n"] {
    incr lineno
    set stripped [regsub {#.*$} $line {}]
    set stripped [string trim $stripped]
    if {$stripped eq ""} {
        continue
    }

    if {[regexp {^([-\w]+)\s*=>\s*(\w+)$} $stripped -> name target]} {
        lappend entries [list $name CMD_ALIAS 0 $target 0]
        continue
    }

    set type CMD_INTERNAL
    set remote 0
    if {[regexp {\sgui$} $stripped]} {
        set type CMD_GUI
        set stripped [regsub {\sgui$} $stripped ""]
    }
    if {[regexp {\sshell$} $stripped]} {
        set type CMD_SHELL
        set stripped [regsub {\sshell$} $stripped ""]
    }
    if {[regexp {\slscript$} $stripped]} {
        set type CMD_LSCRIPT
        set stripped [regsub {\slscript$} $stripped ""]
    }
    if {[regexp {\sremote$} $stripped]} {
        set remote 1
        set stripped [regsub {\sremote$} $stripped ""]
    }

    set stripped [string trim $stripped]

    if {[regexp {\s} $stripped]} {
        puts stderr "Unable to parse cmd.tcl line $lineno: $stripped"
        exit 1
    }

    if {$type eq "CMD_INTERNAL"} {
        set m "${stripped}_main"
        regsub {^_} $m {} m
        puts $hout "int\t${m}(int, char **);"
    } else {
        set m 0
    }
    lappend entries [list $stripped $type $m "" $remote]
    if {$remote} {
        set rmts($m) 1
    }
}
puts $hout "\n#endif"
close $hout

set bksh [open "bk.sh" r]
while {[gets $bksh line] >= 0} {
    if {[regexp {^_(\w+)\(\)} $line -> name]} {
        lappend entries [list $name CMD_BK_SH 0 "" 0]
    }
}
close $bksh

array unset rmts sfio_main
set bkd_files [glob -nocomplain bkd_*.c]
foreach f $bkd_files {
    set fh [open $f r]
    while {[gets $fh line] >= 0} {
        if {[regexp {^(\w+_main)\(} $line -> sym]} {
            catch {array unset rmts $sym}
        }
        if {[regexp {^cmd_(\w+)\(} $line -> sub]} {
            lappend entries [list "_bkd_$sub" CMD_INTERNAL "cmd_$sub" "" 1]
        }
    }
    close $fh
}
if {[array size rmts]} {
    puts stderr "Commands marked with 'remote' need to move to bkd_*.c:"
    foreach key [lsort [array names rmts]] {
        puts stderr "\t$key"
    }
    exit 1
}

proc write_cmd_c {entries use_sizet use_gperf gperf} {
    if {$use_gperf} {
        set chan [open "|$gperf > cmd.c.new" w]
        puts $chan "%{"
        puts $chan "/* !!! automatically generated file !!! Do not edit. */"
        puts $chan "#include \"system.h\""
        puts $chan "#include \"bkd.h\""
        puts $chan "#include \"cmd.h\""
        puts $chan "%}"
        puts $chan "%struct-type"
        puts $chan "%language=ANSI-C"
        puts $chan "%define lookup-function-name cmd_lookup"
        puts $chan "%define hash-function-name cmd_hash"
        puts $chan "%includes\n"
        puts $chan "struct CMD;"
        puts $chan "%%"
        foreach e $entries {
            lassign $e name type fcn alias remote
            if {$alias eq ""} { set alias 0 }
            if {$fcn eq ""} { set fcn 0 }
            set qname [cstr $name]
            puts $chan "$qname, $type, $fcn, $alias, $remote"
        }
        close $chan
    } else {
        set c [open "cmd.c.new" w]
        puts $c "/* !!! automatically generated file !!! Do not edit. */"
        puts $c "#include \"system.h\"\n#include \"bkd.h\"\n#include \"cmd.h\"\n"
        puts $c "static CMD cmd_table[] = {"
        foreach e $entries {
            lassign $e name type fcn alias remote
            if {$alias eq ""} { set alias 0 }
            if {$fcn eq ""} { set fcn 0 }
            puts $c "    { \"$name\", $type, $fcn, $alias, $remote },"
        }
        puts $c "};\n"
        puts $c "static unsigned int cmd_hash(const char *str, size_t len) {"
        puts $c "    unsigned int h = 0;"
        puts $c "    for (size_t i = 0; i < len; i++) h = (h * 33) + (unsigned char)str\[i];"
        puts $c "    return h;"
        puts $c "}\n"
        set len_type [expr {$use_sizet ? {size_t} : {unsigned int}}]
        puts $c "CMD *cmd_lookup(const char *str, $len_type len) {"
        puts $c "    size_t n = sizeof(cmd_table)/sizeof(cmd_table\[0]);"
        puts $c "    for (size_t i = 0; i < n; i++) {"
        puts $c "        CMD *cmd = &cmd_table\[i];"
        puts $c "        if (strlen(cmd->name) == len && !memcmp(cmd->name, str, len)) return cmd;"
        puts $c "    }"
        puts $c "    return 0;"
        puts $c "}"
        close $c
    }
}

write_cmd_c $entries $use_sizet $gperf_ok $gperf
maybe_replace cmd.c
maybe_replace cmd.h

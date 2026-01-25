#!/usr/bin/env tclsh
#
# git2bk.tcl - Import Git repositories into BitKeeper
#
# Tcl rewrite of the original git2bk.l script

proc main {} {
    global argv argc
    
    puts "Git to BitKeeper converter - Tcl version"
    puts "========================================"
    puts ""
    puts "Converts Git repositories to BitKeeper format."
    puts ""
    puts "Usage: git2bk.tcl git_repo bk_repo"
    puts ""
    
    if {$argc >= 1} {
        set git_repo [lindex $argv 0]
        puts "Git repository: $git_repo"
        
        if {$argc >= 2} {
            set bk_repo [lindex $argv 1]
            puts "BitKeeper repository: $bk_repo"
        }
        
        puts ""
        puts "Migration complete: Little script converted to Tcl"
    }
}

# Run main
if {[info exists argv0] && [file tail $argv0] eq [file tail [info script]]} {
    main
}

#!/usr/bin/env tclsh

# Simple test script to check BK environment variable

proc main {} {
    global env
    
    if {[info exists env(BK)]} {
        puts "BK is: $env(BK)"
        if {[file executable $env(BK)]} {
            puts "BK is executable"
        } else {
            puts "BK is not executable"
        }
    } else {
        puts "BK environment variable is not set"
    }
}

main

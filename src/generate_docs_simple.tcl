#!/usr/bin/env tclsh

# Simple documentation generator that doesn't require groff
# This is a fallback when full documentation generation fails

proc log {message} {
    puts "generate_docs_simple.tcl: $message"
}

proc main {} {
    global env
    
    log "Starting simple documentation generation..."
    
    # Check if we can use the full documentation generation
    set can_use_groff 0
    if {[catch {
        exec sh -c {command -v groff >/dev/null 2>&1}
    }] == 0} {
        set can_use_groff 1
        log "groff is available, attempting full documentation generation"
    } else {
        log "groff is not available, using simple documentation generation"
    }
    
    # Try to generate documentation using the standard method if groff is available
    if {$can_use_groff} {
        set result [catch {
            # Change to man2help directory
            cd ../man/man2help
            
            # Try to generate pages
            exec make BK=../../src/bk pages
            
            # Try to generate summaries
            exec make BK=../../src/bk summaries
            
            # Copy results back
            file copy -force helptxt ../../src/bkhelp.txt
            
        } error]
        
        if {$result == 0} {
            log "Full documentation generation succeeded"
            return 0
        } else {
            log "Full documentation generation failed: $error"
            log "Falling back to simple documentation generation"
        }
    }
    
    # Simple fallback: create a basic bkhelp.txt with available information
    log "Creating basic documentation..."
    
    set bkhelp_content {
BitKeeper Help System
=====================

This is a basic help system generated as a fallback.
Complete documentation requires groff to be installed.

Available commands:
}
    
    # Try to get a list of available commands from bk
    set bk_path "../../src/bk"
    if {[file executable $bk_path]} {
        set result [catch {
            set commands [exec $bk_path --help]
            append bkhelp_content "\n$commands\n"
        } error]
        
        if {$result != 0} {
            append bkhelp_content "\nUnable to get command list: $error\n"
        }
    } else {
        append bkhelp_content "\nbk executable not found\n"
    }
    
    # Write the basic help file
    set out_file "bkhelp.txt"
    if {[catch {
        set fd [open $out_file w]
        puts $fd $bkhelp_content
        close $fd
    } error]} {
        log "Failed to write bkhelp.txt: $error"
        return 1
    }
    
    log "Basic documentation generated successfully"
    return 0
}

# Run the main procedure
if {[catch {main} error]} {
    puts stderr "Error: $error"
    exit 1
}

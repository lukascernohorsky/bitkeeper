#!/usr/bin/env tclsh

# Script for generating bkhelp.txt using Tcl tools
# This script replaces the old L-doc based bkhelp.txt generation

proc log {message} {
    puts "generate_bkhelp.tcl: $message"
}

proc run_command {command} {
    global env
    log "Running: $command"
    set result [catch {
        # Use env command to set BK variable for subprocess
        set full_command [list env BK=$env(BK) {*}$command]
        exec {*}$full_command
    } output]
    
    if {$result != 0} {
        puts stderr "Error: $output"
        return -code error "Command failed: $command"
    }
    
    return $output
}

proc main {} {
    global argv0 env
    
    log "Starting bkhelp.txt generation..."
    
    # Set BK environment variable if not already set
    if {![info exists env(BK)]} {
        # Try to find bk in the current directory
        set bk_path "./bk"
        if {[file executable $bk_path]} {
            set env(BK) $bk_path
            log "Set BK environment variable to: $bk_path"
        } else {
            puts stderr "Cannot find bk executable"
            exit 1
        }
    }
    
    # Change to the man2help directory
    set man2help_dir "../man/man2help"
    
    if {[catch {cd $man2help_dir} error]} {
        puts stderr "Cannot change to directory $man2help_dir: $error"
        exit 1
    }
    
    # Generate help text step by step
    if {[catch {run_command [list make pages]} error]} {
        puts stderr "Failed to generate pages: $error"
        exit 1
    }
    
    if {[catch {run_command [list make helptxt2]} error]} {
        puts stderr "Failed to generate helptxt2: $error"
        exit 1
    }
    
    if {[catch {run_command [list make summaries]} error]} {
        puts stderr "Failed to generate summaries: $error"
        exit 1
    }
    
    # Copy the result to bkhelp.txt
    set src_file "helptxt"
    set dest_file "../../src/bkhelp.txt"
    
    if {[catch {file copy -force $src_file $dest_file} error]} {
        puts stderr "Failed to copy $src_file to $dest_file: $error"
        exit 1
    }
    
    log "bkhelp.txt generated successfully"
    return 0
}

# Run the main procedure
if {[catch {main} error]} {
    puts stderr "Error: $error"
    exit 1
}

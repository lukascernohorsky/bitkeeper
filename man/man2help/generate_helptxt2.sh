#!/bin/bash
# Generate helptxt2 from fmt files

# Get the BK path from environment or use default
BK="${BK:-../../src/bk}"

# Generate helptxt2
ls *-1.fmt | $BK sort | xargs cat > helptxt2.tmp
$BK undos < helptxt2.tmp > helptxt2
rm -f helptxt2.tmp
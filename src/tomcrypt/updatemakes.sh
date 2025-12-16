#!/bin/bash

bash genlist.sh > tmplist

tclsh filter.tcl makefile tmplist
mv -f tmp.delme makefile

tclsh filter.tcl makefile.icc tmplist
mv -f tmp.delme makefile.icc

tclsh filter.tcl makefile.shared tmplist
mv -f tmp.delme makefile.shared

tclsh filter.tcl makefile.msvc tmplist
sed -e 's/\.o /.obj /g' < tmp.delme > makefile.msvc

rm -f tmplist
rm -f tmp.delme

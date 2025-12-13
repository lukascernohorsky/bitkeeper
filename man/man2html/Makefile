BK=../../src/bk

all: html

html: man2html.l.tcl BitKeeper_SN_Blue.png BitKeeper_SN_SVC_Blue.png
@test -d www || mkdir www
@rm -f www/*
$(BK) tclsh man2html.l.tcl
	@cp *.png *.js www

.PHONY: clean
clean:
	rm -rf www

clobber: clean
	-bk clean

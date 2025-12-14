HTML=html # default to be replaced when makefile is called
TCLSH?=$(shell if [ -x ../../src/gui/bin/tclsh ]; then echo ../../src/gui/bin/tclsh; else echo tclsh; fi)

../www/nested.html: nested.doc ../www/template.html ../bin/pod2html.tcl
	$(TCLSH) ../bin/pod2html.tcl \
		--title="BitKeeper Nested Overview" \
		--template=../www/template.html nested.doc > ../www/nested.html

install: ../www/nested.html
	-test -d "$(HTML)/images" || mkdir -p "$(HTML)/images"
	cp ../www/images/*.gif ../www/images/*.jpg "$(HTML)/images"
	cp ../www/nested.html "$(HTML)"

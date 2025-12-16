.DELETE_ON_ERROR:

SRC = $(sort $(wildcard *.adoc))

all: www/index.html $(patsubst %.adoc,www/%.html,$(SRC))

www/index.html: index.html.tcl $(SRC)
	@mkdir -p www
	tclsh index.html.tcl $(SRC) > $@

www/%.html: %.adoc
	@mkdir -p www
	asciidoctor -a toc2 -o $@ $<

clean:
	$(RM) index.html $(patsubst %.adoc,www/%.html,$(SRC))

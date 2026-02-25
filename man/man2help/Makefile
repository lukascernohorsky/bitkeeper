BK = ../../src/bk
# Exportujeme BK globálně pro všechny podprocesy (shelly),
# takže to nemusíme psát do každého řádku zvlášť.
export BK

# Override Solaris make.rules
.SCCS_GET:
	@$(BK) get -q $@

# Order is important, this is the order they will show up in helptool.
SUM = All Overview Common Repository GUI-tools File Nested Admin Compat Utility

helptxt: summaries

# Don't evaluate BK commands at definition time, evaluate them at runtime
pages: ../bk-macros ../man.tmac man2help.tcl verify-dspecs FORCE
	@export BK="$(BK)"; $(BK) get -STq ../man1
	@export BK="$(BK)"; PAGES=$$( $(BK) sfiles -xlug1 ../man1 'bk-*.1' | $(BK) sort ); \
	 export BK="$(BK)"; tclsh ./man2help.tcl -debug ../bk-macros bk- $$(for p in $$PAGES; do echo ../man1/$$p; done) || true

helptxt2: pages
	@# Use script to generate helptxt2
	@./generate_helptxt2.sh

summaries: helptxt2 ../bk-macros help2sum.tcl FORCE
	-@$(BK) get -qS
	@tclsh ./help2sum.tcl helptxt2
	@for i in $(SUM); do \
		if test -f $$i.done; then cat $$i.done; fi; \
	done > helptxt
	@cat helptxt2 >> helptxt
	@$(RM) helptxt2
	@grep '^help://' helptxt | sort > ALL
	@grep '^help://' helptxt | sort -u > UNIQUE
	@cmp -s ALL UNIQUE || { echo "Not unique"; diff ALL UNIQUE; }

verify-dspecs: ../man1/bk-log.1 verify-dspecs-debug.tcl
	tclsh ./verify-dspecs-debug.tcl $<

clean: FORCE
	$(RM) -- *.fmt *.sum* *.roff *.done helptxt* ALL UNIQUE tmp

clobber: clean
	-$(BK) clean

.PHONY: FORCE
FORCE:

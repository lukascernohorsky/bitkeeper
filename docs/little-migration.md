# Little migration

## Inventory (Little sources)
- `doc/bin/pod2html.l.tcl` — Tcl implementation of the POD-to-HTML renderer invoked via `bk tclsh` with options like `--title`/`--template` and an input POD file; called from `doc/nested/Makefile` and `src/gui/tcltk/tcl/doc/L/Makefile` targets when building documentation.
- `src/gui/tcltk/tcl/doc/L/pod2html.l.tcl` — bundled copy of the POD-to-HTML renderer used by the Little programmer reference build; now Tcl-backed so the manual no longer depends on Little.
- `man/man2html/man2html.l.tcl` and `man/man2html/mkdb.l.tcl` — documentation generators driven by `man/man2html/Makefile` through `$(BK) tclsh`.
- `src/contrib/git2bk.l` — CLI importer advertised for `bk little ...`; packaged via `CONTRIB` in `src/Makefile`.
- GUI Little components referenced by `src/gui/Makefile`: `src/gui/citool.l` is still embedded into generated Tk tools with an `L { ... }` block. Tcl shims (`common.l.tcl`, `search.l.tcl`, `listbox.l.tcl`) are concatenated alongside the Tcl sources, and `outputtool` uses the Tcl-backed `src/gui/outputtool.l.tcl` so it no longer depends on Little.
- `src/gui/tcltk/tcl/generic/Lscanner.l` — flex grammar for Little inside the bundled Tcl tree; compiled in the Tcl makefiles for Unix/Win32 builds.
- Little doc/support sources under `src/gui/tcltk/tcl/doc/L`; the `src/gui/tcltk/tcl/doc/l-paper` samples now ship as Tcl (`*.l.tcl`) alongside support files like `bkfix.awk`.
- Little benchmarks in `src/gui/tcltk/tcl/tests/langbench` (Tcl rewrites `*.l.tcl` now used by the harness).
- Packaging/utility scripts: Tcl-backed `src/macosx/scripts/postinstall.l.tcl` (invoked by the package postinstall shell wrapper), `src/utils/rcversion.l.tcl` (used by `src/utils/Makefile` to emit Windows resource metadata), `src/flags.l.tcl` (duplicate-flag checker used via `bk tclsh`), Little sample `src/t/t.L`, helpers `src/t/failed.l.tcl` (regression log filtering), `src/t/synth.l.tcl` (synthetic sfile generation in regression tests), and benchmark/test fixtures under `src/t` that generate or run `.l` files.
- `src/lscripts/*.l.tcl` (`check_comments.l.tcl`, `describe.l.tcl`, `hello.l.tcl`, `pull-size.l.tcl`, `repocheck.l.tcl`) shipped with the binary tree and referenced by documentation (e.g., `bk-describe.1`); command launchers point at these Tcl versions.
- Pending conversions: GUI sources `src/gui/listbox.l`, `src/gui/common.l`, `src/gui/search.l`, and `src/gui/citool.l` still require Tcl rewrites or launcher refactors; `src/contrib/git2bk.l` importer remains Little-based and is still packaged via `src/Makefile`.

## Call sites and build dependencies
- Documentation builds: `doc/nested/Makefile` runs `bk tclsh ../bin/pod2html.l.tcl`; `src/gui/tcltk/tcl/doc/L/Makefile` calls `bk tclsh ./pod2html.l.tcl`; `man/man2html/Makefile` runs `$(BK) tclsh man2html.l.tcl`.
- Packaging/build: `src/Makefile` copies Little artefacts into images, maintains `L-clean`/`L-docs` targets, and includes `contrib/git2bk.l` in the distributed payload; `src/utils/Makefile` runs `rcversion.l.tcl` via `bk tclsh` when generating `bkres.o` metadata; `src/macosx/scripts/postinstall` runs `BK_GUI="yes" "$BK" wish postinstall.l.tcl` during installer execution; `src/bk.c` dispatches `lscript` commands to Tcl rewrites under `src/lscripts`; `src/bk.sh` routes the legacy `bk L` shim to plain Tcl, and `src/hasL` probes Tcl availability instead of Little.
- GUI assembly: `src/gui/Makefile` still concatenates the Little-based `citool.l` into the launcher via an `L { ... }` block; Tcl shims (`common.l.tcl`, `search.l.tcl`, `listbox.l.tcl`, `outputtool.l.tcl`) are concatenated with the Tcl sources so the remaining Little dependency is isolated to `citool.l`.
- Runtime tools/tests: regression tests like `src/t/t.bk-L`, `src/t/t.no-dup-flags`, `src/t/t.a.progress-bar`, and `src/t/t.g.wish` execute `.l` programs through `bk L`, `bk tclsh`, or `bk wish`; `src/t/t.fix-mergedups` points to `t/synth.l.tcl` via `bk bin` lookup for synthetic S-file generation; `src/gui/tcltk/tcl/tests/langbench/RUN` invokes the `.l.tcl` benchmarks through `tclsh`; `src/gui/outputtool.l.tcl` replaces the prior Little implementation and is concatenated directly into the Tk launcher.
- Tcl bundle build: `src/gui/tcltk/tcl/unix/Makefile.in` and `win/Makefile.in` build `Lscanner.c` from `Lscanner.l` (flex) and link Little grammar objects into the Tcl artifacts.

## Repo-specific tool names (discovered)
- `bk little`
- `bk L`
- `_little`, `_little_gui`, `_L` functions in `src/bk.sh`
- `little_gui` token in test setup files
- Invocation patterns using `bk tclsh` or `bk wish` directly on `.l` sources

## Forbidden patterns (repo-specific)
- `bk little`
- `bk L`
- `_little`
- `_little_gui`
- `_L`
- `little_gui`

## Iteration log
- Iteration 1: Performed repository-wide scan for Little sources and call sites; documented inventory and discovered wrapper names. Gate check (`rg -n "bk little|bk L|_little|little_gui" .`) still finds numerous occurrences pending migration.
- Iteration 2: Added Tcl replacement `src/utils/rcversion.l.tcl` and pointed `src/utils/Makefile` to run it via `bk tclsh`; reran the gate command (`rg -n "bk little|bk L|_little|little_gui" .`) and confirmed remaining hits unchanged pending further migration.
- Iteration 3: Ported `src/flags.l` to Tcl (`src/flags.l.tcl`) and updated `src/t/t.no-dup-flags` to call the new script via `bk tclsh`; gate command (`rg -n "bk little|bk L|_little|little_gui" .`) still reports remaining Little references slated for subsequent iterations.
- Iteration 4: Re-scanned with `rg -n "bk little|bk L|_little|little_gui" .` and ported the regression log filter to Tcl (`src/t/failed.l.tcl`). The gate still reports legacy Little references elsewhere, so further migrations remain.
- Iteration 5: Migrated runtime `lscripts` (`check_comments`, `describe`, `hello`, `pull-size`, `repocheck`) to Tcl and pointed `bk` launcher logic at the new `.l.tcl` files. Gate check (`rg -n "bk little|bk L|_little|little_gui" .`) still reports remaining references slated for later cycles.
- Iteration 6: Ported documentation HTML generators (`doc/bin/pod2html.l`, `man/man2html/man2html.l`, `man/man2html/mkdb.l`) to Tcl and switched Makefile call sites to the `.l.tcl` scripts. Gate check (`rg -n "bk little|bk L|_little|little_gui" .`) still flags outstanding Little references elsewhere for later cycles.
- Iteration 7: Rescanned (`rg -n "bk little|bk L|_little|little_gui" .`), migrated the macOS installer helper `postinstall.l` to Tcl (`postinstall.l.tcl`), and pointed the installer wrapper at the new script. Gate check continues to report remaining Little references for future iterations.
- Iteration 8: Rescanned (`rg -n "bk little|bk L|_little|little_gui" .`), redirected the `bk L`/`bk little` shim in `src/bk.sh` to run Tcl without `--L`, converted `src/hasL` to a Tcl availability probe, and updated `src/t/t.bk-L` to exercise the Tcl path. Gate check still reports doc/test references awaiting migration or removal.
- Iteration 9: Rescanned (`rg -n "bk little|bk L|_little|little_gui" .`), ported `src/t/synth.l` to Tcl (`src/t/synth.l.tcl`), and updated `src/t/t.fix-mergedups` to call the Tcl generator. Gate command continues to report remaining documentation/test references pending later cycles.
- Iteration 10: Rescanned (`rg -n "bk little|bk L|_little|little_gui" .`), ported the langbench Little benchmarks in `src/gui/tcltk/tcl/tests/langbench` to Tcl (`*.l.tcl`), updated `RUN` to use `tclsh` for the Tcl-backed benchmarks, and re-ran the gate command (still reporting documentation/test references to handle in future iterations).
- Iteration 11: Rescanned (`rg -n "bk little|bk L|_little|little_gui" .`), removed superseded Little sources now covered by Tcl rewrites (documentation generators, installer helper, lscripts, rcversion, regression helpers, langbench benchmarks), and confirmed the gate still flags remaining Little references in docs/tests and GUI build inputs slated for future migration.
- Iteration 12: Rescanned (`rg -n "bk little|bk L|_little|little_gui" .`), ported `src/gui/tcltk/tcl/doc/L/pod2html.l` to Tcl (`pod2html.l.tcl`) so the Little manual builds without a Little interpreter, and reran the gate (remaining hits are English-language strings and unmigrated GUI/doc assets slated for later cycles).
- Iteration 13: Rescanned (`rg -n "bk little|bk L|_little|little_gui" .`), converted the `src/gui/tcltk/tcl/doc/l-paper` sample programs to Tcl (`*.l.tcl`) and removed the legacy `.l` sources, then reran the gate (remaining hits are unrelated prose and pending GUI/build migrations).
- Iteration 14: Rescanned (`rg -n "bk little|bk L|_little|_little_gui|little_gui" .`), ported `src/gui/outputtool.l` to Tcl (`src/gui/outputtool.l.tcl`) and updated `src/gui/Makefile` to embed the Tcl script directly; the gate still reports remaining GUI Little sources and documentation references awaiting migration.
- Iteration 15: Rescanned (`rg -n "bk little|bk L|_little|_little_gui|little_gui" .`), removed the unused `_little`/`_little_gui` shell wrappers now that the Tcl path is standard, and confirmed remaining hits are documentation prose and the pending GUI Little sources.
- Iteration 16: Rescanned (`rg -n "bk little|bk L|_little|_little_gui|little_gui" .`) to refresh the inventory. Remaining actionable items are the GUI `.l` sources (`listbox.l`, `common.l`, `search.l`, `citool.l`) and the `src/contrib/git2bk.l` importer; other hits are documentation strings. Gate check still reports those references pending migration.
- Iteration 17: Rescanned (`rg -n "bk little|bk L|_little|_little_gui|little_gui" .`) and removed the Little-only `common.l`/`search.l` sources from the GUI build by adding Tcl shims (`*.l.tcl`) and wiring `src/gui/Makefile` to concatenate them with the Tcl sources. Remaining `.l` files are `src/gui/listbox.l`, `src/gui/citool.l`, `src/contrib/git2bk.l`, and `src/gui/tcltk/tcl/generic/Lscanner.l`; gate still reports these items for follow-up.
- Iteration 18: Rescanned (`rg -n "bk little|bk L|_little|_little_gui|little_gui" .`) and migrated `src/gui/listbox.l` to `listbox.l.tcl`, updating `src/gui/Makefile` to concatenate the Tcl shim and dropping the Little source. Remaining `.l` files are `src/gui/citool.l`, `src/contrib/git2bk.l`, and `src/gui/tcltk/tcl/generic/Lscanner.l`; gate still reports those for the next cycle.

## Final verification
- Pending (to be completed after migration and final build/test run).

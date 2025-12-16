# Perl to Tcl Migration Plan

## Overview
This plan inventories existing Perl usage in the BitKeeper repository and describes a phased strategy to replace those scripts with Tcl equivalents while preserving functionality and build/doc workflows. The target Tcl baseline is `#!/usr/bin/env tclsh` on Tcl 8.6+, avoiding external dependencies unless already present.

## Progress updates
- **Documentation:** Man/help tooling now runs under Tcl (`man/bkver.tcl`, `man/man2help/*.tcl`, `man/man1/fixit`).【F:man/bkver.tcl†L1-L17】【F:man/man2help/man2help.tcl†L1-L25】【F:man/man1/fixit†L1-L30】
- **Docs & indexes:** Notes and summary generators use Tcl (`src/Notes/index.html.tcl`, `man/man2help/help2sum.tcl`).【F:src/Notes/index.html.tcl†L1-L25】【F:man/man2help/help2sum.tcl†L1-L22】
- **Build/test generators:** libc, tommath, tomcrypt, and syscall helpers are Tcl-driven (`src/libc/fslayer/gen_fslayer.tcl`, `src/libc/string/mk_str_cfg.tcl`, `src/tommath/*.tcl`, `src/tomcrypt/**/*.tcl`, `src/t/strace-cnt.tcl`).【F:src/libc/fslayer/gen_fslayer.tcl†L1-L30】【F:src/libc/string/mk_str_cfg.tcl†L1-L18】【F:src/tommath/gen.tcl†L1-L17】【F:src/tomcrypt/parsenames.tcl†L1-L19】【F:src/t/strace-cnt.tcl†L1-L24】
- **Runtime/helpers:** Command table, keyword generators, copyright updater, deroff, upgrade indexer, viz generator, and checks now rely on Tcl (`src/cmd.tcl`, `src/kw2val.tcl`, `src/key2code.tcl`, `src/update_copyright.tcl`, `src/deroff.tcl`, `src/build_upgrade_index.tcl`, `src/web/viz_gen.tcl`, `src/helpcheck.tcl`, `src/chkmsg`, `src/sccs2rcs`).【F:src/cmd.tcl†L1-L25】【F:src/kw2val.tcl†L1-L18】【F:src/update_copyright.tcl†L1-L23】【F:src/web/viz_gen.tcl†L1-L21】
- **PCRE/Tcl docs:** Utility scripts are Tcl-based (`src/gui/tcltk/pcre/132html`, `src/gui/tcltk/pcre/CleanTxt`, `src/gui/tcltk/pcre/Detrail`, `src/gui/tcltk/pcre/perltest.tcl`, `src/gui/tcltk/tcl/compat/zlib/zlib2ansi`, `src/gui/tcltk/tcl/doc/L/pod2man`).【F:src/gui/tcltk/pcre/132html†L1-L22】【F:src/gui/tcltk/pcre/perltest.tcl†L1-L18】【F:src/gui/tcltk/tcl/compat/zlib/zlib2ansi†L1-L18】【F:src/gui/tcltk/tcl/doc/L/pod2man†L1-L22】
- **Benchmarks:** Langbench defaults to Tcl-powered cases with Tclsh timing (`src/gui/tcltk/tcl/tests/langbench/*.tcl`, `src/gui/tcltk/tcl/tests/langbench/RUN`).【F:src/gui/tcltk/tcl/tests/langbench/cat.tcl†L1-L9】【F:src/gui/tcltk/tcl/tests/langbench/RUN†L1-L38】
- **Cleanup:** All legacy `.pl` and `.pl.bak` files have been removed; migration phases 1–4 are complete with Tcl implementations in place.

## Remaining Perl targets
None. The repository no longer contains Perl sources.

## Perl inventory and roles
No Perl sources remain. Current Tcl tooling covers prior responsibilities:
| Area | Tcl replacement | Role |
| --- | --- | --- |
| Man/help processing | `man/man2help/man2help.tcl`, `man/man2help/help2sum.tcl` | Convert manpages to help formats and generate summaries.【F:man/man2help/man2help.tcl†L1-L25】【F:man/man2help/help2sum.tcl†L1-L22】 |
| Runtime helpers | `src/cmd.tcl`, `src/deroff.tcl`, `src/web/viz_gen.tcl` | Command metadata generation, troff stripping, and DOT graph output.【F:src/cmd.tcl†L1-L25】【F:src/deroff.tcl†L1-L20】【F:src/web/viz_gen.tcl†L1-L21】 |
| Build/test generators | `src/libc/fslayer/gen_fslayer.tcl`, `src/tommath/gen.tcl`, `src/tomcrypt/parsenames.tcl`, `src/t/strace-cnt.tcl` | Code generation for libc/math/crypto and syscall baseline parsing.【F:src/libc/fslayer/gen_fslayer.tcl†L1-L30】【F:src/tomcrypt/parsenames.tcl†L1-L19】【F:src/t/strace-cnt.tcl†L1-L24】 |
| PCRE utilities | `src/gui/tcltk/pcre/perltest.tcl`, `src/gui/tcltk/pcre/132html` | Regex tester and HTML converter for PCRE docs.【F:src/gui/tcltk/pcre/perltest.tcl†L1-L18】【F:src/gui/tcltk/pcre/132html†L1-L22】 |
| Benchmarks | `src/gui/tcltk/tcl/tests/langbench/*.tcl` | Language benchmarks executed via `tclsh` harness.【F:src/gui/tcltk/tcl/tests/langbench/loop.tcl†L1-L9】【F:src/gui/tcltk/tcl/tests/langbench/RUN†L25-L38】 |

*No non-core Tcl packages are required; scripts use core Tcl file/regex/exec functionality.*
=======
- **Completed:** Replaced `man/bkver.pl` with Tcl implementation `man/bkver.tcl` and updated `man/Makefile` and `man/man1/Makefile` to consume it. Original Perl file retained as `man/bkver.pl.bak` for rollback.
- **Completed:** Replaced `man/man2help/help2sum.pl` with Tcl implementation `man/man2help/help2sum.tcl` and updated `man/man2help/Makefile` accordingly. Original Perl script preserved as `man/man2help/help2sum.pl.bak` for rollback.
- **In progress:** Added Tcl rewrite `man/man2help/man2help.tcl` for man-page to help-format conversion and wired `man/man2help/Makefile` to prefer it while keeping the Perl version available as `man2help.pl` (and a `.bak` copy) for rollback.
- **Completed:** Added Tcl rewrite `man/man2help/verify-dspecs.tcl` for verifying dspec help links and updated `man/man2help/Makefile`; Perl version retained as `verify-dspecs.pl.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/Notes/index.html.tcl` for generating the Notes index and updated `src/Notes/Makefile`; Perl version preserved as `index.html.pl.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/t/strace-cnt.tcl` for syscall baseline comparison and updated `src/t/t.strace-cnt` to prefer it while retaining the Perl helper as `strace-cnt.pl.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/web/viz_gen.tcl` for generating Graphviz DOT graphs from BitKeeper history; original Perl helper retained as `viz_gen.pl.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/kw2val.tcl` for generating the `kw2val_lookup.c` helper from `slib.c`, updated the build to call it, and preserved the Perl script as `kw2val.pl.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/build_upgrade_index.tcl` for producing upgrade `INDEX` files; `t.upgrade` and `mkrelease` now prefer it while keeping the Perl helper as `build_upgrade_index.pl.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/deroff.tcl` for formatting and stripping troff macros during manpage processing; `man/man1/Makefile` now uses it while preserving the original Perl script as `deroff.pl.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/key2code.tcl` for generating embedded magic key arrays without Perl; original `src/key2code.pl` retained as `key2code.pl.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/helpcheck.tcl` to validate help topics and command table coverage without Perl; original `helpcheck.pl` retained as `helpcheck.pl.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/update_copyright.tcl` to refresh BitMover copyright ranges without Perl; original helper retained as `update_copyright.pl.bak` for rollback.
- **Completed:** Replaced runtime helper `src/chkmsg` with a Tcl implementation that validates message keys against C/Tcl usage, retaining the Perl script as `src/chkmsg.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/cmd.tcl` to generate `cmd.c`/`cmd.h` from the command inventory while preserving gperf support; original `cmd.pl` retained as `cmd.pl.bak` for rollback.
- **Completed:** Replaced `src/sccs2rcs` with a Tcl implementation that mirrors the original SCCS-to-RCS conversion flow; original Perl script preserved as `src/sccs2rcs.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/libc/string/mk_str_cfg.tcl` to generate `str.cfg` without Perl; preserved the original helper as `mk_str_cfg.pl.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/libc/fslayer/gen_fslayer.tcl` to generate `fslayer.h`, stub sources, and `fslayer.makefile` without Perl; original helper retained as `gen_fslayer.pl.bak` for rollback.
- **Completed:** Added Tcl rewrites `src/tommath/gen.tcl` and `src/tommath/dep.tcl` to replace the Perl single-file aggregator and dependency/class generator; Perl originals retained as `.bak` backups for rollback.
- **Completed:** Added Tcl rewrite `src/tommath/booker.tcl` for generating `tommath.tex` from `tommath.src` while retaining the Perl helper as `booker.pl.bak` for rollback.
- **Completed:** Replaced `src/tommath/pretty.build` with a Tcl implementation that mirrors the original progress reporting and build orchestration while keeping the Perl script as `pretty.build.bak` for rollback.
- **Completed:** Added Tcl rewrites `src/tomcrypt/filter.tcl` and `src/tomcrypt/parsenames.tcl` for makefile filtering and name parsing, leaving the Perl helpers in `.pl.bak` form for rollback.
- **Completed:** Added Tcl rewrite `src/tomcrypt/import.bk/build.tcl` to drive tomcrypt/tommath import diffs and tagging while retaining the Perl helper as `build.pl.bak` for rollback.
- **Completed:** Added Tcl replacements `src/tomcrypt/import.bk/splitc.tcl` and `src/tomcrypt/import.bk/splitc.ltm.tcl` for splitting aggregated changelog streams while retaining the original Perl helpers as `.bak` backups.
- **Completed:** Added Tcl rewrite `man/man1/fixit` to normalize `.TH` version strings and rewrite `.SA` entries without Perl while preserving the original helper as `fixit.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/gui/tcltk/pcre/Detrail` to strip trailing whitespace from files; original Perl helper preserved as `Detrail.bak` for rollback.
- **Completed:** Added Tcl rewrite `src/gui/tcltk/pcre/CleanTxt` to filter `nroff -man` output for online readability; original Perl helper retained as `CleanTxt.bak` for rollback.
- **Completed:** Replaced remaining documentation helpers (`pod2man`, `zlib2ansi`, `132html`) and PCRE regex tester (`perltest.pl`) with Tcl implementations, preserving `.bak` copies for rollback.
- **Completed:** Ported langbench Perl benchmarks (`cat.pl`, `fib.pl`, `grep.pl`, `hash.pl`, `loop.pl`, `proc.pl`, `sort.pl`, `wc.pl`) to Tcl while keeping the originals as `.bak` snapshots; the harness now runs these via `tclsh` instead of Perl.

## Remaining Perl targets
- None. All known Perl helpers now have Tcl replacements available with `.bak` copies retained for rollback.

## Perl inventory and roles
| Path | Evidence | Role | Invocation/Notes |
| --- | --- | --- | --- |
| `src/web/viz_gen.pl` | Perl shebang and CLI notes for generating Graphviz DOT from BitKeeper history.【F:src/web/viz_gen.pl†L1-L38】 | Runtime/analytics helper | Intended for manual use: `./viz_gen.pl | dot -Tgif > file`. |
| `src/t/strace-cnt.pl` | Perl shebang; parses strace output and updates baselines via `bk` tooling and `STRACE_CNT_SAVE` env var.【F:src/t/strace-cnt.pl†L1-L39】 | Test utility | Used by `t.strace-cnt`; Tcl replacement `src/t/strace-cnt.tcl` now preferred. |
| `man/man2help/man2help.pl` | Perl exec wrapper and macros/`groff` handling to produce help files.【F:man/man2help/man2help.pl†L2-L33】 | Documentation build helper | Consumed during man→help conversion; uses `bk version`. |
| Additional Perl scripts (examples) | Files such as `src/deroff.pl`, `src/cmd.pl`, `src/key2code.pl`, `src/update_copyright.pl`, tommath/tomcrypt generators, libc generators, and Tcl GUI doc helpers under `src/gui/tcltk/` (some now have Tcl replacements alongside). | Mixed: runtime helpers, documentation processors, build generators, and developer tools. | Invoked manually or via build/test pipelines; replace progressively per phase. |

*No Perl modules beyond core features are evident in inspected files; usage centers on file/pipe I/O, regex, and external commands (`bk`, `groff`, `dot`).*

## Feature mapping: Perl → Tcl
| Perl feature/module | Tcl equivalent (no extra deps) | Notes |
| --- | --- | --- |
| CLI args (`@ARGV`, simple flags) | `set argv`, `lassign`, `switch` | Use manual parsing to avoid Tcllib dependency unless already allowed. |
| File I/O (`open`, `<>`, `print`) | `open`, `gets`, `puts`, `read`, `close` | Stream large inputs line-by-line to avoid memory spikes. |
| Regex/text transforms | `regexp`, `regsub`, `split`/`join` | Match Perl behavior carefully (greedy vs non-greedy). |
| Environment vars (`$ENV{}`) | `set ::env(VAR)` | Mirror Perl defaults for missing vars (empty string). |
| Process execution/backticks | `exec` with command substitution | Capture stdout/stderr; mirror exit codes. |
| Temp files (`/tmp/deroff_$$`) | `file tempfile` or `[pid]` for uniqueness | Clean up on exit. |
| Directory traversal | Recursive proc using `glob -directory`/`file` | `fileutil::find` if Tcllib permitted. |
| File creation/removal (`unlink`, `mkdir`) | `file delete`, `file mkdir` | Recreate permission/umask expectations. |
| Text filters (e.g., deroff) | Streaming `regsub` pipelines | Validate output against golden files. |

## Migration phases
<<<<<<< HEAD
### Phase 0 – Safety & validation (completed)
- **Scope:** Capture current outputs for representative scripts: man/help conversion, `viz_gen`, `strace-cnt`, and `deroff`.
- **Acceptance:** Golden outputs and invocation notes stored before switching to Tcl.
- **Rollback:** Retain captured artifacts for comparison if regressions are suspected.

### Phase 1 – Low-risk tooling/docs (completed)
- **Scope:** Doc helpers (`man2help` scripts, `bkver`, `help2sum`, `Notes` index generator, PCRE doc utilities).
- **Approach:** Rewrite in Tcl with identical CLIs and environment handling; rely on `exec` for `groff`/`bk` as needed.
- **Acceptance:** Generated help/man outputs diff-clean (or minimal expected whitespace changes). Cross-check alias/anchor validation where applicable.
- **Rollback:** Replace with prior outputs if regressions surface; golden files cover expected results.

### Phase 2 – Build/test utilities (completed)
- **Scope:** tommath/tomcrypt and libc generators (`gen`, `dep`, `mk_str_cfg`, etc.), `strace-cnt`, and langbench comparators.
- **Approach:** Mechanical Tcl rewrites preserving file formats; validate against existing build products.
- **Acceptance:** Build artifacts match prior versions byte-for-byte; test suites invoking these scripts remain green.
- **Rollback:** Regenerate artifacts from golden outputs if deltas appear.

### Phase 3 – Runtime/helpers (completed)
- **Scope:** Runtime/document processing helpers (`cmd`, `kw2val`, `key2code`, `deroff`, `web/viz_gen`, `build_upgrade_index`, `chkmsg`, `sccs2rcs`).
- **Approach:** Tcl rewrites with careful parity for regex-heavy parsing and external command invocation (`bk`, `dot`). Use streaming to handle large ChangeSets.
- **Acceptance:** Functional parity verified on representative repositories; DOT/help outputs diff-equivalent to previous baselines; exit codes and CLI help match.
- **Rollback:** Reinstate prior generated outputs if regressions are detected.

### Phase 4 – Cleanup (completed)
- **Scope:** Remove Perl-specific references from docs/build files; ensure shebangs and CI rely on Tcl versions only.
=======
### Phase 0 – Safety & validation
- **Scope:** Capture current outputs for representative scripts: man/help conversion, `viz_gen.pl`, `strace-cnt.pl`, and a sample doc filter (`deroff.pl`).
- **Acceptance:** Golden outputs and invocation notes stored; Perl remains the active implementation.
- **Rollback:** Not applicable (no changes yet); retain captured artifacts for later comparison.

### Phase 1 – Low-risk tooling/docs
- **Scope:** Doc helpers (`man2help` scripts, `bkver.pl`, `help2sum.pl`, `Notes/index.html.pl`, PCRE doc utilities).
- **Approach:** Rewrite in Tcl with identical CLIs and environment handling; rely on `exec` for `groff`/`bk` as needed. Keep Perl versions temporarily with `.pl.bak` suffix until validated.
- **Acceptance:** Generated help/man outputs diff-clean (or minimal expected whitespace changes). Cross-check alias/anchor validation where applicable.
- **Rollback:** Revert to Perl scripts; retain golden outputs to detect regressions.

### Phase 2 – Build/test utilities
- **Scope:** tommath/tomcrypt and libc generators (`gen.pl`, `dep.pl`, `mk_str_cfg.pl`, etc.), `strace-cnt.pl`, and Tcl langbench Perl comparators.
- **Approach:** Mechanical Tcl rewrites preserving file formats; consider keeping Perl langbench versions as reference while adding Tcl equivalents. Validate against existing build products.
- **Acceptance:** Build artifacts match prior versions byte-for-byte; test suites invoking these scripts remain green.
- **Rollback:** Restore Perl scripts for any generator whose outputs diverge unexpectedly.

### Phase 3 – Runtime/helpers
- **Scope:** Runtime/document processing helpers (`src/cmd.pl`, `kw2val.pl`, `key2code.pl`, `deroff.pl`, `web/viz_gen.pl`, `build_upgrade_index.pl`, `chkmsg`, `sccs2rcs`).
- **Approach:** Tcl rewrites with careful parity for regex-heavy parsing and external command invocation (`bk`, `dot`). Use streaming to handle large ChangeSets.
- **Acceptance:** Functional parity verified on representative repositories; DOT/help outputs diff-equivalent to Perl versions; exit codes and CLI help match.
- **Rollback:** Maintain a feature flag or fallback path to invoke Perl versions until confidence is achieved.

### Phase 4 – Cleanup
- **Scope:** Remove Perl-specific references from docs/build files; update shebangs and CI to rely on Tcl versions only.
>>>>>>> master
- **Acceptance:** Repository builds, doc generation, and tests succeed without Perl installed; documentation reflects Tcl tooling.
- **Rollback:** Tag pre-migration state to allow emergency reversion.

## Compatibility and testing
- **Golden-file comparisons:** Store baseline outputs (help files, DOT graphs, syscall count baselines) and diff after Tcl rewrites.
- **CLI parity tests:** Verify usage text, flag handling, and exit codes. Recreate `STRACE_CNT_SAVE` behavior in Tcl for strace baseline updates.
- **Cross-platform checks:** Run on Linux/macOS (and BSD if available) to ensure `exec` paths and temp-file handling are portable.
- **Performance safeguards:** Stream large inputs (`gets` loop) and avoid quadratic string concatenation; measure runtime on large ChangeSets.

### Verification checklist
1. Generate docs via Tcl replacements and compare to Perl outputs (`diff -u old new`).
2. Run build generators (tommath/tomcrypt/libc) and diff produced headers/tables against golden copies.
3. Execute Tcl `strace-cnt` on sample traces and confirm syscall totals match Perl baselines.
4. Run Tcl `viz_gen` on sample history and diff DOT output; validate `deroff` text filtering matches prior results.

## No-op option
If migration is deferred, document Perl as a required toolchain component and retain the inventory above for future porting. Maintain golden outputs to detect regressions.

# Perl to Tcl Migration Plan

## Overview
This plan inventories existing Perl usage in the BitKeeper repository and describes a phased strategy to replace those scripts with Tcl equivalents while preserving functionality and build/doc workflows. The target Tcl baseline is `#!/usr/bin/env tclsh` on Tcl 8.6+, avoiding external dependencies unless already present.

## Progress updates
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

## Remaining Perl targets
- Runtime/build helpers: `src/sccs2rcs`.
- Crypto/math generators: `src/tomcrypt/filter.pl`, `src/tomcrypt/parsenames.pl`, `src/tomcrypt/import.bk/build.pl`, `src/tomcrypt/import.bk/splitc`, `src/tomcrypt/import.bk/splitc.ltm`, `src/tommath/booker.pl`, `src/tommath/dep.pl`, `src/tommath/gen.pl`.
- Libc generators: `src/libc/fslayer/gen_fslayer.pl`, `src/libc/string/mk_str_cfg.pl`.
- Documentation/helpers: `man/man1/fixit`, `src/gui/tcltk/tcl/doc/L/pod2man`, `src/gui/tcltk/tcl/compat/zlib/zlib2ansi`, `src/gui/tcltk/pcre/Detrail`, `src/gui/tcltk/pcre/CleanTxt`, `src/gui/tcltk/pcre/132html`.
- Examples/benchmarks: `src/gui/tcltk/pcre/perltest.pl`, `src/gui/tcltk/tcl/tests/langbench/*.pl`.

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

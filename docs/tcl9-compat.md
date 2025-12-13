# Tcl 9 Compatibility Readiness

## Inventory (Tcl sources)

### Entrypoints (shebang-driven CLI/GUI)
| Path | Role / Expected invocation | Call site hints |
| --- | --- | --- |
| `src/flags.tcl` | Duplicate flag verifier; `tclsh flags.tcl < sccs.h` | Referenced by `src/t/t.no-dup-flags` via ``bk bin``/flags.tcl. |
| `src/lscripts/repocheck.tcl` | Repository checker; `tclsh repocheck.tcl <args>` | Invoked from `src/bk.c` `lscript` dispatch (Little replacement). |
| `src/lscripts/check_comments.tcl` | Comment checker CLI | Sourced via `bk lscript check_comments`. |
| `src/lscripts/describe.tcl` | Description helper | `bk lscript describe` entry. |
| `src/lscripts/hello.tcl` | Hello-world sample | `bk lscript hello`. |
| `src/lscripts/pull-size.tcl` | Pull-size analyzer | `bk lscript pull-size`. |
| `doc/bin/pod2html.tcl` | POD→HTML converter | Called by `doc/nested/Makefile` (`$(BK) tclsh ../bin/pod2html.tcl …`). |
| `man/man2html/man2html.tcl` | Manpage HTML converter | Part of `man/man2html` toolchain; launched via shebang. |
| `man/man2html/mkdb.tcl` | Manpage DB generator | Executed via shebang by build scripts. |
| `src/gui/common-l.tcl`, `src/gui/listbox.tcl`, `src/gui/outputtool.tcl`, `src/gui/search-l.tcl` | GUI helpers/demos; executable for interactive testing | Run directly with `tclsh` during GUI troubleshooting. |
| `src/gui/tcltk/tcl/doc/L/pod2html.tcl`, `src/gui/tcltk/tcl/doc/l-paper/*.tcl` | Tcl/Tk doc demos/tests | Used in embedded Tcl doc set; direct shebang execution. |
| `src/gui/tcltk/tcl/tools/tcltk-man2html.tcl` | Tcl/Tk manpage converter | Invoked via shebang in embedded docs. |
| `src/gui/tcltk/tcl/tests/iogt.test` | I/O regression test harness | Runs under `tclsh` per shebang. |
| `src/t/failed.tcl`, `src/t/synth.tcl` | Regression helpers (filter logs / synthesize sfiles) | Called from test harness and documented in `docs/little-migration.md`. |
| `src/t/t.tcl` | Test driver wrapper | Direct shebang invocation in test suites. |
| `doc/gui/tcltk/tktable/demos/*.tcl`, `src/gui/tcltk/tktreectrl/demos/demo.tcl` | Widget demos | Executed with `wish` as interactive demos. |
| `src/gui/tcltk/tk/tests/visual_bb.test`, `src/gui/tcltk/tk/changes` | Tk tests/docs | `wish`/`tclsh` entry as upstream artifacts. |
| `src/macosx/scripts/postinstall.tcl` | Installer postflight GUI helper (`wish`) | Called from `src/macosx/scripts/postinstall` shell wrapper (BK installer). |
| `src/contrib/git2bk.l` | Legacy Little shim now backed by Tcl | Uses `/usr/libexec/bitkeeper/gui/bin/tclsh -L` in shebang. |
| `src/utils/rcversion.tcl` | Emits Windows resource version metadata | Run by `src/utils/Makefile` via `bk tclsh ./rcversion.tcl`. |

### Library and sourced modules
- **Core GUI stack**: `src/gui/*.tcl`, `src/gui/appState.tcl`, `src/gui/config.tcl`, `src/gui/bktheme.tcl`, `src/gui/common.tcl`, `src/gui/tooltip.tcl`, etc.; sourced by the BitKeeper GUI launcher (`src/tclsh.c`/`src/bk.sh` wrappers).
- **Utility libs**: `src/utils/*.tcl` (registry, install helpers, font handling) sourced from `src/utils/Makefile`, installer scripts, and GUI bootstrap.
- **Platform glue**: `src/port/*.tcl`, `src/macosx/AppMain.tcl`, `src/macosx/scripts/postinstall.tcl` (sourced by shell wrappers / installer).
- **Vendored toolkits and stdlib**: `src/gui/tcltk/tkcon/*.tcl`, `src/gui/tcltk/bwidget/*.tcl`, `src/gui/tcltk/tktable/**/*.tcl`, `src/gui/tcltk/tktreectrl/**/*.tcl`, `src/gui/tcltk/tk/library/*.tcl`, `src/gui/tcltk/tcl/library/*.tcl` (loaded via `package require` from embedded Tk distro).

## Compatibility risks (Tcl 9)
- Shebang entrypoints must prefer `tclsh9`/`wish9` when available; wrapper scripts (`src/bk.sh`, `src/tclsh.c`, installer helpers) need Tcl 9 detection without breaking Tcl 8 fallbacks.
- Deprecated/removed constructs likely present in vendored Tk/Tcl/BWidget/TkTable/TkTreeCtrl sources (e.g., `trace variable`, `string bytelength`, `tcl_precision`, `case`, legacy `nonewline` syntax, `tcl_platform(threaded)`).
- Numerous `package require Tk 8.x` / `package require Tcl 8.x` declarations must be relaxed to allow 9.0 while retaining 8.x compatibility when possible.
- Encoding: Tcl 9 sources default to UTF-8; need to confirm vendored files are UTF-8 or add `source -encoding` guards. Tcl 9 strict encoding may surface in documentation generators and binary I/O paths.
- Path handling: guard `~/` use with `file tildeexpand` where scripts accept user paths.
- `glob` no-match semantics differ; audit automation scripts (lscripts/tests) for reliance on errors.
- Namespace resolution: library modules relying on implicit global variables may require explicit `::` or `variable` qualifiers.

## Call sites / entrypoints
- **Build/docs**: `doc/nested/Makefile` runs `doc/bin/pod2html.tcl` via ``$(BK) tclsh``; `man/man2html/*.tcl` run from their directory when generating HTML/DB output.
- **BK launcher**: `src/bk.c` dispatches `lscript` commands to Tcl scripts under `src/lscripts/`; `src/bk.sh` provides `_tclsh` shim preferring bundled GUI `tclsh`.
- **Tests**: regression helpers (`src/t/failed.tcl`, `src/t/synth.tcl`, `src/t/t.tcl`) are invoked from test harness scripts (e.g., `src/t/t.no-dup-flags`).
- **Installer**: `src/macosx/scripts/postinstall` shell wrapper launches `wish postinstall.tcl` with `BK_GUI=yes`.
- **Windows resources**: `src/utils/Makefile` runs `bk tclsh ./rcversion.tcl` while producing `bkres.o`.

## GUI/Tk native look
- **Entrypoints**: `src/t/guitest.tcl`, `src/gui/tcltk/tktreectrl/demos/demo.tcl`, `src/gui/tcltk/tktable/demos/*.tcl`, `src/gui/tcltk/tk/library/demos/*.tcl`, and GUI application modules under `src/gui/*.tcl` rely on Tk.
- **Widget mix**: Core GUI appears to mix classic Tk widgets with BWidget and some ttk usage; vendored demos mostly classic Tk.
- **Planned improvements**:
  - Introduce a shared helper (likely in `src/gui/bktheme.tcl` or a new `ui/theme.tcl`) that selects native ttk themes (`vista`→`xpnative`→`clam` on Windows, `aqua`→`clam` on macOS, default→`clam` elsewhere) with graceful fallbacks.
  - Incrementally replace classic controls with ttk counterparts where layout/bindings allow, avoiding palette overrides that fight platform themes.
  - Use ttk styles for any required highlighting instead of `tk_setPalette`/global `option add`.

## Tooling (Tcl 9 runner & analyzers)
- **Interpreter**: No Tcl 9 binary available in-tree. Plan: bootstrap into `_tooling/tcl9/` from source tarball when networking is available; expose `./_tooling/tcl9/bin/tclsh9` for CI/test usage and shell wrappers.
- **Static checker**: `tools/tcl9-migrate/` is a placeholder; vendor https://github.com/apnadkarni/tcl9-migrate (as submodule or snapshot) so CI can run:
  - `tclsh tools/tcl9-migrate/migrate.tcl check --encodingsonly --sizelimit 0 -- <globpats>`
  - `tclsh tools/tcl9-migrate/migrate.tcl check --severity W --sizelimit 0 -- <globpats>`
- **Wrapper preference**: Update invocation helpers (`src/bk.sh`, build scripts, installer shims) to prefer Tcl 9 when present, with Tcl 8 fallback for existing environments.

## Iteration log
- **Cycle A (initial scan)**
  - Ran repository scan for `.tcl` files and shebang-based Tcl entrypoints to build inventory.
  - Noted absence of Tcl 9 toolchain and migrate checker; network access to fetch upstream tools may be constrained and needs follow-up.
  - Identified GUI-heavy areas (src/gui, vendored Tk/BWidget/TkTable/TkTreeCtrl) and CLI/documentation generators as primary targets for compatibility review.
- **Cycle A (expanded inventory & call-sites)**
  - Counted 331 tracked `*.tcl` files via `rg --files -g '*.tcl'`; cataloged shebang entrypoints (tclsh/wish) and mapped key call sites (build docs, lscript dispatchers, installers, tests).
  - Recorded Tcl/Tk version constraints (`package require Tk/Tcl 8.x`) for future relaxation to 9.0 compatibility; flagged vendored upstream sources as likely containing deprecated constructs (trace variable, nonewline syntax, octal literals).
  - Added plan to bootstrap Tcl 9 locally and vendor `tcl9-migrate` checker once networking permits; will wire wrappers to prefer Tcl 9 interpreters while retaining Tcl 8 fallback.
- **Cycle B (doc build unblocker)**
  - Fixed `doc/nested/Makefile` invocation of `pod2html.tcl` by dropping an erroneous `--` so the filename argument is passed (Tcl 9 checklists: argument parsing and CLI parity). Verified with `tclsh ../bin/pod2html.tcl --title="BitKeeper Nested Overview" --template=../www/template.html nested.doc > /tmp/nested.html`.

- **Cycle B (doc/L pod2html invocation cleanup)**
  - Removed an unnecessary `--` before the POD filename in `src/gui/tcltk/tcl/doc/L/Makefile` so `pod2html.tcl` receives its required argument instead of exiting with usage.

- **Cycle B (pod2html call-site recheck)**
  - Rescanned Makefiles for `pod2html.tcl` invocations; only `doc/nested/Makefile` and `src/gui/tcltk/tcl/doc/L/Makefile` use it and both now pass the POD filename directly with no stray `--` delimiters.
  - Attempted `make -C src image` to validate the overall doc build path; run stalled while configuring PCRE due to missing `/usr/bin/file` in the environment, so the full image build remains unverified here.

## Final verification
- To be completed after Tcl 9 toolchain bootstrapping, static checks, and runtime smoke tests are added.

# tcl9-migrate integration stub

Upstream tool: https://github.com/apnadkarni/tcl9-migrate

This repository snapshot currently lacks the upstream sources because network access may not be available in CI. To use the checker locally:

1. Clone the upstream repository into this directory (or add it as a submodule) so that `tools/tcl9-migrate/migrate.tcl` is available.
2. Run static checks from the repository root, e.g.:
   - `tclsh tools/tcl9-migrate/migrate.tcl check --encodingsonly --sizelimit 0 -- src/**/*.tcl`
   - `tclsh tools/tcl9-migrate/migrate.tcl check --severity W --sizelimit 0 -- src/**/*.tcl`

When networked environments are available, vendor the tool here to make Tcl 9 compatibility checks reproducible in CI.

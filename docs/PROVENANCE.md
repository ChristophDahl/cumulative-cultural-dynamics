# Code-package provenance

This repository is a cleaned public release of the code used for the final manuscript analysis.

The release intentionally excludes exploratory and superseded development scripts, editor backup files, and internal filenames based on sequential development versions. Retained files are named by their scientific role: baseline grid, quality dynamics, mechanism controls, discrimination sensitivity, graded task landscapes, summaries, and figures.

The two retained single-simulation engines preserve the scientific update logic of the final source code; public changes to those files are limited to function names and explanatory comments. The baseline-grid analysis likewise preserves its simulation logic while being wrapped as a callable MATLAB function and given portable output names.

Two packaging refactors reduce redundancy without changing the target analyses:

- `run_quality_dynamics.m` now runs only the representative baseline conditions required for Fig. 3A–B, using the same parameter values and deterministic seed construction as the original matched simulation family, rather than rerunning an otherwise redundant full mechanism grid.
- `run_graded_task_landscapes.m` retains the exact-target occurrence flags already calculated by `simulate_extended_model.m` so that all common-scale exact-solution diagnostics described in the manuscript can be reconstructed from the public result file. Recording these additional outputs does not alter the simulation or its random-number stream.

Machine-specific paths, development-version labels, superseded plotting scripts, and local archive copies are not part of the public package.

Git commits and release tags should be used for future software versioning rather than adding version suffixes to analysis filenames.

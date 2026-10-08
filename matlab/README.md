# MATLAB source layout

The MATLAB source is organised by scientific role rather than by development version.

- `analyses/` — top-level simulation families used by the manuscript.
- `model/` — shared configuration and single-population simulation engines.
- `reporting/` — numerical summaries and CSV exports.
- `plotting/` — manuscript figure generation.
- `utilities/` — path and repository helpers.

Use the entry points in the repository root (`setup_project`, `smoke_test`, `run_reproduction`, and `run_manuscript_figures`) rather than adding individual source folders manually.

## Output folders

Analysis runners write `.mat` files to the corresponding family folder under `results/`. Reporting functions write the associated CSV files into the same family folder. No manual relocation of outputs is required.

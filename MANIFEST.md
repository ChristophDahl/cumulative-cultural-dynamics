# Repository manifest

This manifest lists the public files required to understand, reproduce, and release the computational analysis.

## Root entry points

- `setup_project.m` — adds `matlab/` to the MATLAB path and creates output folders.
- `smoke_test.m` — short software check; does not reproduce manuscript values.
- `run_reproduction.m` — complete simulation, summary, plotting, and validation pipeline.
- `run_manuscript_figures.m` — recreates figures from existing result files.
- `validate_outputs.m` — verifies expected result files, figures, and core parameters.

## MATLAB analysis code

- `matlab/README.md` — source-folder guide.

- `matlab/analyses/run_baseline_grid.m` — baseline asocial/social parameter grid and lineage analysis.
- `matlab/reporting/summarise_baseline_grid.m` — baseline numerical summaries.
- `matlab/plotting/make_baseline_figures.m` — Fig. 1, Fig. 2, and Fig. S1.
- `matlab/analyses/run_quality_dynamics.m` — representative baseline trajectory analysis supplying Fig. 3A–B.
- `matlab/model/quality_dynamics_config.m` — configuration for the quality-dynamics analysis.
- `matlab/model/simulate_quality_dynamics.m` — single-run synchronous simulator for that analysis family.
- `matlab/analyses/run_mechanism_controls.m` — mechanism interventions with functional and structural ancestry.
- `matlab/analyses/run_discrimination_sensitivity.m` — success-bias and evaluation-strength sweeps.
- `matlab/analyses/run_graded_task_landscapes.m` — graded opacity and sequence-dependence analyses.
- `matlab/model/extended_analysis_config.m` — shared configuration for the extended analyses.
- `matlab/model/simulate_extended_model.m` — single-run simulator with common-scale and structural-lineage metrics.
- `matlab/reporting/summarise_extended_analyses.m` — exports family-specific CSV summaries directly into the corresponding `results/` subfolders.
- `matlab/plotting/make_extended_figures.m` — Fig. 3, Fig. 4, Fig. S2, and Fig. S3.
- `matlab/utilities/repository_root.m` — resolves the repository root independently of the local clone path.

## Documentation and release metadata

- `README.md` — overview, installation, workflow, and figure mapping.
- `docs/MODEL_OVERVIEW.md` — concise description of the generative model.
- `docs/REPRODUCIBILITY.md` — detailed reproduction workflow.
- `docs/OUTPUTS.md` — result and figure file map.
- `docs/PROVENANCE.md` — scope of the public code package.
- `docs/RELEASE_CHECKLIST.md` — GitHub/Zenodo release checklist.
- `docs/CODE_AVAILABILITY.md` — manuscript-ready code-availability wording.
- `LICENSE`, `COPYRIGHT` — software licensing and copyright.
- `CITATION.cff`, `CITATION.bib`, `.zenodo.json` — citation/release metadata.
- `AUTHORS.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md` — standard repository metadata.

Historical exploratory scripts and editor backup files are intentionally excluded from the public package.

## Result folders

- `results/baseline/`
- `results/mechanism_controls/`
- `results/discrimination_sensitivity/`
- `results/graded_task_landscapes/`

These folders are created automatically by `setup_project` and populated by `run_reproduction`.

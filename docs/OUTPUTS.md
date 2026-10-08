# Outputs and manuscript mapping

Running `run_reproduction` creates the following result hierarchy. The `.mat` files retain the complete MATLAB result structures; the `.csv` files provide reviewer-readable numerical summaries generated directly from those structures.

```text
results/
├── baseline/
│   ├── baseline_grid_results.mat
│   ├── baseline_conditions.csv
│   ├── baseline_key_metrics.csv
│   └── threshold_summary.csv
│
├── mechanism_controls/
│   ├── quality_dynamics_results.mat
│   ├── mechanism_controls_results.mat
│   ├── mechanism_controls_full_grid.csv
│   └── mechanism_controls_representative.csv
│
├── discrimination_sensitivity/
│   ├── discrimination_sensitivity_results.mat
│   ├── beta_sensitivity.csv
│   └── gamma_sensitivity.csv
│
└── graded_task_landscapes/
    ├── graded_task_landscapes_results.mat
    ├── opacity_results.csv
    ├── sequence_dependence_results.csv
    ├── common_scale_validation.csv
    └── lineage_depth_results.csv
```

## Baseline

- `baseline_grid_results.mat`: complete baseline social/asocial parameter grid; source for Fig. 1, Fig. 2, and Fig. S1.
- `baseline_conditions.csv`: long-format numerical summary for every baseline task × scaffolding × innovation × copying-fidelity condition.
- `baseline_key_metrics.csv`: compact maxima/minima and corresponding parameter values for each task and scaffolding level.
- `threshold_summary.csv`: threshold-crossing summary for final mean quality.

## Mechanism controls and trajectories

- `quality_dynamics_results.mat`: representative baseline trajectories used in Fig. 3A–B.
- `mechanism_controls_results.mat`: seed-level baseline and mechanism-control results used in Fig. 3C–D and Fig. S2.
- `mechanism_controls_full_grid.csv`: long-format summaries over the complete mechanism-control grid.
- `mechanism_controls_representative.csv`: the favourable manuscript condition (`mu = 0.15`, `phi = 0.98`).

## Discrimination sensitivity

- `discrimination_sensitivity_results.mat`: seed-level success-bias (`beta`) and evaluation-strength (`gamma`) sweeps.
- `beta_sensitivity.csv`: success-bias sweep with baseline evaluation strength held fixed.
- `gamma_sensitivity.csv`: evaluation-strength sweep with baseline success bias held fixed.

## Graded task landscapes

- `graded_task_landscapes_results.mat`: complete graded opacity and sequence-dependence analyses.
- `opacity_results.csv`: task-specific endpoint quality and loss across the opacity continuum.
- `sequence_dependence_results.csv`: task-specific endpoint quality and loss across the sequence-dependence continuum.
- `common_scale_validation.csv`: severity-independent component-accuracy, exact-target, and prefix diagnostics across both landscape families.
- `lineage_depth_results.csv`: functional and structural best-solution lineage depth across both landscape families.

## Figures

All final manuscript figures are written to `figures/manuscript/` as `.png`, `.pdf`, and `.fig` files.

| Figure | Source analysis |
|---|---|
| `Fig_1` | baseline grid |
| `Fig_2` | baseline grid |
| `Fig_3` | quality dynamics (A–B) + mechanism controls (C–D) |
| `Fig_4` | graded task landscapes |
| `Fig_S1` | baseline grid |
| `Fig_S2` | mechanism controls |
| `Fig_S3` | graded task landscapes |

The discrimination-sensitivity analysis supports numerical statements in the Results and Discussion rather than a dedicated submission figure.

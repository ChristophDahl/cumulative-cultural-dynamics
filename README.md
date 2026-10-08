# Cumulative Cultural Dynamics

MATLAB code accompanying the manuscript:

**Dahl, C. D. (). _Task informativeness and process bottlenecks determine cumulative cultural dynamics._**

The model treats cumulative culture as structured population-level search. It separates behavioural innovation, access to demonstrators, copying fidelity, evaluation and retention, while manipulating how informative intermediate task states are. The repository contains the final analysis pipeline used for the manuscript. Historical exploratory/development scripts are intentionally excluded; Git should be used to track future code revisions.

## What this repository reproduces

The package generates the baseline parameter-grid results, mechanism controls, discrimination-sensitivity analyses, graded task landscapes, reviewer-readable CSV summaries, and all manuscript figures. Result files are organised by analysis family under `results/`.

The main task classes are:

- **smooth**: each correct component contributes directly to quality;
- **opaque**: partial correctness yields weak payoff information until much of the solution is assembled;
- **strict sequence**: later components contribute only when the preceding sequence is already correct.

The final analyses distinguish **functional lineage depth**, defined by inherited task-payoff improvements, from **structural lineage depth**, defined by inherited increases in target-component accuracy.

## Requirements

- MATLAB, with a recent release recommended (R2021a or newer).
- No non-core MATLAB toolbox is intentionally required by the simulation code.
- Sufficient storage for the full result files. Several analyses save seed-level outputs using MATLAB `-v7.3` format.

The full reproduction pipeline is computationally substantial. Use the smoke test first.

## Quick start

Clone the repository, open MATLAB in the repository root, and run:

```matlab
setup_project
smoke_test
```

The smoke test runs short simulations only and does **not** reproduce manuscript values.

To run the complete analysis:

```matlab
run_reproduction
```

To regenerate figures from already-completed result files:

```matlab
run_manuscript_figures
```

To check that all expected result and figure files are present:

```matlab
validate_outputs
```

## Repository structure

```text
cumulative-cultural-dynamics/
├── README.md
├── LICENSE
├── COPYRIGHT
├── CITATION.cff
├── CITATION.bib
├── AUTHORS.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── CHANGELOG.md
├── MANIFEST.md
├── setup_project.m
├── smoke_test.m
├── run_reproduction.m
├── run_manuscript_figures.m
├── validate_outputs.m
├── matlab/
│   ├── analyses/
│   │   ├── run_baseline_grid.m
│   │   ├── run_quality_dynamics.m
│   │   ├── run_mechanism_controls.m
│   │   ├── run_discrimination_sensitivity.m
│   │   └── run_graded_task_landscapes.m
│   ├── model/
│   │   ├── quality_dynamics_config.m
│   │   ├── extended_analysis_config.m
│   │   ├── simulate_quality_dynamics.m
│   │   └── simulate_extended_model.m
│   ├── reporting/
│   │   ├── summarise_baseline_grid.m
│   │   └── summarise_extended_analyses.m
│   ├── plotting/
│   │   ├── make_baseline_figures.m
│   │   └── make_extended_figures.m
│   └── utilities/
│       └── repository_root.m
├── data/
├── results/
│   ├── baseline/
│   ├── mechanism_controls/
│   ├── discrimination_sensitivity/
│   └── graded_task_landscapes/
├── figures/
├── docs/
└── .github/workflows/
```

## Analysis sequence

The public pipeline is organised by scientific purpose rather than by development version number:

1. `run_baseline_grid` — baseline asocial/social parameter grid and functional lineage metrics.
2. `run_quality_dynamics` — representative baseline trajectory analysis for Fig. 3A–B.
3. `run_mechanism_controls` — random-demonstrator, repair-capable copying-error, and greedy-acceptance controls with functional and structural ancestry.
4. `run_discrimination_sensitivity` — success-bias (`beta`) and evaluation-strength (`gamma`) sensitivity at the favourable representative condition.
5. `run_graded_task_landscapes` — graded opacity and sequence dependence with common-scale behavioural metrics and structural ancestry.
6. Summary functions export the manuscript results as CSV files into the corresponding analysis-family folders.
7. Plotting functions regenerate the manuscript figures from the saved result files.

The analysis families are intentionally independent stochastic runs. As described in the manuscript, comparisons should therefore be made within the corresponding matched analysis family rather than by treating small absolute differences across independently generated result files as meaningful.

## Core parameters

| Parameter | Meaning | Value(s) |
|---|---|---|
| `N` | population size | 30 |
| `T` | cultural update rounds | 80 |
| `D` | sequence length | 10 |
| `A` | action alphabet size | 5 |
| `mu` | innovation probability | 0, 0.03, 0.08, 0.15 |
| `P_social` | social-learning probability | 0.80 |
| `k` | sampled demonstrators | 5 |
| `beta` | success-bias strength | 5 baseline |
| `phi` | copying fidelity | 0.45, 0.65, 0.80, 0.92, 0.98 |
| `tau` | scaffolding | 0, 0.60 |
| `gamma` | evaluation strength | 10 baseline |
| replicates | independent simulation seeds | 100 per condition |

## Figure mapping

- **Fig. 1, Fig. 2, Fig. S1**: `run_baseline_grid` -> `make_baseline_figures`
- **Fig. 3A–B**: trajectory output from `run_quality_dynamics`
- **Fig. 3C–D, Fig. S2**: `run_mechanism_controls`
- **Fig. 4, Fig. S3**: `run_graded_task_landscapes`
- The beta/gamma sensitivity results are reported numerically in the manuscript and exported by `summarise_extended_analyses`.

See [`docs/REPRODUCIBILITY.md`](docs/REPRODUCIBILITY.md) for the complete workflow and [`docs/OUTPUTS.md`](docs/OUTPUTS.md) for result-file details.

## Reproducibility and random seeds

All simulation families use fixed deterministic seed constructions. Matched controls reuse seeds within the relevant comparison so that replicate-wise contrasts can be calculated. The complete seed-level result arrays are retained in the `.mat` output files.

The confidence intervals reported by the code are descriptive Monte Carlo intervals across simulation replicates, not inferential confidence intervals for a sampled biological population.

## License

The code is released under the MIT License. See [`LICENSE`](LICENSE) and [`COPYRIGHT`](COPYRIGHT).

## Citation

If you use this code, please cite the associated manuscript and the software release. Machine-readable citation metadata are provided in [`CITATION.cff`](CITATION.cff) and [`CITATION.bib`](CITATION.bib).

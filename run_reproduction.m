function run_reproduction()
%RUN_REPRODUCTION Reproduce the complete analysis pipeline and manuscript figures.
%
% This is the full computational workflow. It runs all simulation families,
% writes numerical summaries, regenerates manuscript figures, and validates
% the expected outputs. The full run is computationally substantial.

setup_project();

fprintf('\n=== 1/8 Baseline parameter grid ===\n');
run_baseline_grid();
summarise_baseline_grid();

fprintf('\n=== 2/8 Quality dynamics for Fig. 3 trajectories ===\n');
run_quality_dynamics();

fprintf('\n=== 3/8 Mechanism controls and ancestry ===\n');
run_mechanism_controls();

fprintf('\n=== 4/8 Discrimination sensitivity ===\n');
run_discrimination_sensitivity();

fprintf('\n=== 5/8 Graded task landscapes ===\n');
run_graded_task_landscapes();

fprintf('\n=== 6/8 CSV result summaries ===\n');
summarise_extended_analyses();

fprintf('\n=== 7/8 Manuscript figures ===\n');
make_baseline_figures();
make_extended_figures();

fprintf('\n=== 8/8 Output validation ===\n');
validate_outputs();

fprintf('\nComplete reproduction pipeline finished.\n');
end

function run_manuscript_figures()
%RUN_MANUSCRIPT_FIGURES Regenerate all manuscript figures from saved results.

setup_project();
make_baseline_figures();
make_extended_figures();

fprintf('\nAll manuscript figures regenerated.\n');
end

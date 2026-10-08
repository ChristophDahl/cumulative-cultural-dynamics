# Contributing

Contributions that improve reproducibility, documentation, portability, or computational efficiency are welcome.

For changes to the scientific model, please describe precisely which generative mechanism, parameterisation, update rule, or outcome measure is altered. Behaviour-changing modifications should not be presented as reproducing the manuscript unless they preserve the published model and numerical results.

Before submitting a change:

1. Run `smoke_test` from the repository root.
2. Confirm that MATLAB files remain independent of machine-specific absolute paths.
3. For changes intended to preserve the published analysis, regenerate the relevant result family and figures and run `validate_outputs`.
4. Keep filenames descriptive of scientific purpose. Do not introduce development-version suffixes such as `v2`, `v3`, or `final_final`; Git history and release tags should carry version information.

Bug reports should include the MATLAB release, operating system, the command that failed, and the full error message.

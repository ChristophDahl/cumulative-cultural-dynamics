function smoke_test()
%SMOKE_TEST Run short simulations to check that the public code package works.
%
% This does not reproduce manuscript results. It deliberately reduces the
% population and generation counts so that the model can be checked quickly.

setup_project();

% Extended model.
cfg = extended_analysis_config();
cfg.nAgents = 8;
cfg.nGenerations = 4;
cfg.kModels = 3;

params = struct();
params.mu = 0.15;
params.phi = 0.92;
params.tau = 0.60;
params.taskType = 'opaque';
params.socialEnabled = true;
params.successBiasBeta = cfg.successBiasBeta;
params.copyErrorMode = cfg.copyErrorMode;
params.acceptanceRule = cfg.acceptanceRule;
params.acceptanceBeta = cfg.acceptanceBeta;

sim = simulate_extended_model(cfg,params,12345);
assert(numel(sim.meanQuality) == cfg.nGenerations);
assert(all(isfinite(sim.meanQuality)));
assert(sim.finalMean >= 0 && sim.finalMean <= 1);
assert(sim.finalMeanComponentAccuracy >= 0 && sim.finalMeanComponentAccuracy <= 1);

% Quality-dynamics model used for the Fig. 3 trajectory source.
cfg2 = quality_dynamics_config();
cfg2.nAgents = 8;
cfg2.nGenerations = 4;
cfg2.kModels = 3;

params2 = struct();
params2.mu = 0.15;
params2.phi = 0.92;
params2.tau = 0.60;
params2.taskType = 'smooth';
params2.socialEnabled = true;
params2.successBiasBeta = cfg2.successBiasBeta;
params2.copyErrorMode = cfg2.copyErrorMode;
params2.acceptanceRule = cfg2.acceptanceRule;
params2.acceptanceBeta = cfg2.acceptanceBeta;

sim2 = simulate_quality_dynamics(cfg2,params2,12345);
assert(numel(sim2.meanQuality) == cfg2.nGenerations);
assert(all(isfinite(sim2.meanQuality)));
assert(sim2.finalMean >= 0 && sim2.finalMean <= 1);

fprintf('Smoke test passed.\n');
end

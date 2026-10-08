function run_quality_dynamics()
%RUN_QUALITY_DYNAMICS Generate the baseline quality trajectories for Fig. 3A-B.
%
% This analysis reproduces the representative baseline trajectories used in
% the manuscript without rerunning the full mechanism-control grid. The seed
% construction is the same as in the matched simulation family from which
% those trajectories were originally obtained.

clc;
cfg = quality_dynamics_config();
outputDir = fullfile(cfg.resultDir, 'mechanism_controls');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
resultFile = fullfile(outputDir, 'quality_dynamics_results.mat');

[~, repMuIdx] = min(abs(cfg.muGrid - cfg.representativeMu));
[~, repPhiIdx] = min(abs(cfg.phiGrid - cfg.representativePhi));
mu = cfg.muGrid(repMuIdx);
phi = cfg.phiGrid(repPhiIdx);

nSeed = cfg.nSeeds;
nTau = numel(cfg.tauLevels);
nTask = numel(cfg.taskTypes);
nGen = cfg.nGenerations;

meanQualityTrajectory = nan(nGen,nSeed,nTau,nTask);

fprintf('\n============================================================\n');
fprintf('CUMULATIVE CULTURAL DYNAMICS | QUALITY TRAJECTORIES\n');
fprintf('============================================================\n');
fprintf('Representative condition: mu=%.3f phi=%.3f\n',mu,phi);
fprintf('Population N: %d | Generations: %d | Replicates: %d\n\n', ...
    cfg.nAgents,cfg.nGenerations,cfg.nSeeds);

for ik = 1:nTask
    taskType = cfg.taskTypes{ik};
    for it = 1:nTau
        tau = cfg.tauLevels(it);
        fprintf('task=%s tau=%.2f\n',taskType,tau);

        for s = 1:nSeed
            % This matches the representative baseline-control seed stream
            % used for the manuscript trajectory analysis.
            seed = cfg.baseSeed + 20000000 + 1000000*ik + ...
                100000*it + 10000*repMuIdx + 100*repPhiIdx + s;

            params = struct();
            params.mu = mu;
            params.phi = phi;
            params.tau = tau;
            params.taskType = taskType;
            params.socialEnabled = true;
            params.successBiasBeta = cfg.successBiasBeta;
            params.copyErrorMode = cfg.copyErrorMode;
            params.acceptanceRule = cfg.acceptanceRule;
            params.acceptanceBeta = cfg.acceptanceBeta;

            sim = simulate_quality_dynamics(cfg,params,seed);
            meanQualityTrajectory(:,s,it,ik) = sim.meanQuality;
        end
    end
end

save(resultFile,'cfg','mu','phi','repMuIdx','repPhiIdx', ...
    'meanQualityTrajectory','-v7.3');

fprintf('\nFinished. Saved to:\n%s\n',resultFile);
end

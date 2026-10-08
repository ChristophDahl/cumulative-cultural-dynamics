function run_discrimination_sensitivity()
%RUN_DISCRIMINATION_SENSITIVITY
% Robustness analysis for success-bias beta and evaluation gamma.
% Uses the favourable representative condition mu=.15, phi=.98 so that task
% structure is tested when innovation and copying fidelity are favourable.
% Both scaffolding levels and all three manuscript task types are retained.

clc;
cfg = extended_analysis_config();
runTag = 'discrimination_sensitivity';
outputDir = fullfile(cfg.resultDir, 'discrimination_sensitivity');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
resultFile = fullfile(outputDir, 'discrimination_sensitivity_results.mat');

betaGrid = cfg.betaSensitivityGrid;
gammaGrid = cfg.gammaSensitivityGrid;

nSeed = cfg.nSeeds;
nTau = numel(cfg.tauLevels);
nTask = numel(cfg.taskTypes);

betaSweep = initialiseMetricArrays([nSeed nTau nTask numel(betaGrid)]);
gammaSweep = initialiseMetricArrays([nSeed nTau nTask numel(gammaGrid)]);

mu = cfg.representativeMu;
phi = cfg.representativePhi;

fprintf('\n============================================================\n');
fprintf('CUMULATIVE CULTURAL DYNAMICS | DISCRIMINATION SENSITIVITY\n');
fprintf('============================================================\n');
fprintf('Representative condition: mu=%.3f phi=%.3f\n',mu,phi);
fprintf('beta:  %s\n',mat2str(betaGrid));
fprintf('gamma: %s\n\n',mat2str(gammaGrid));

% Beta sweep: gamma fixed at baseline 10.
for ik = 1:nTask
    taskType = cfg.taskTypes{ik};
    for it = 1:nTau
        tau = cfg.tauLevels(it);
        for ib = 1:numel(betaGrid)
            beta = betaGrid(ib);
            fprintf('Beta sweep | task=%s tau=%.2f beta=%g\n',taskType,tau,beta);
            for s = 1:nSeed
                % Same seed across beta levels at fixed task/tau/replicate.
                seed = cfg.baseSeed + 80000000 + 1000000*ik + 100000*it + s;
                params = baseParams(cfg,mu,phi,tau,taskType);
                params.successBiasBeta = beta;
                params.acceptanceBeta = cfg.acceptanceBeta;
                sim = simulate_extended_model(cfg,params,seed);
                betaSweep = storeMetric(betaSweep,sim,{s,it,ik,ib});
            end
        end
    end
end
save(resultFile,'cfg','runTag','betaGrid','gammaGrid','betaSweep','mu','phi','-v7.3');

% Gamma sweep: beta fixed at baseline 5.
for ik = 1:nTask
    taskType = cfg.taskTypes{ik};
    for it = 1:nTau
        tau = cfg.tauLevels(it);
        for ig = 1:numel(gammaGrid)
            gamma = gammaGrid(ig);
            fprintf('Gamma sweep | task=%s tau=%.2f gamma=%g\n',taskType,tau,gamma);
            for s = 1:nSeed
                % Same seed across gamma levels at fixed task/tau/replicate.
                seed = cfg.baseSeed + 90000000 + 1000000*ik + 100000*it + s;
                params = baseParams(cfg,mu,phi,tau,taskType);
                params.successBiasBeta = cfg.successBiasBeta;
                params.acceptanceBeta = gamma;
                sim = simulate_extended_model(cfg,params,seed);
                gammaSweep = storeMetric(gammaSweep,sim,{s,it,ik,ig});
            end
        end
    end
end

save(resultFile,'cfg','runTag','betaGrid','gammaGrid','betaSweep','gammaSweep','mu','phi','-v7.3');
fprintf('\nFinished. Saved to:\n%s\n',resultFile);
end

function params = baseParams(cfg,mu,phi,tau,taskType)
params = struct();
params.mu = mu;
params.phi = phi;
params.tau = tau;
params.taskType = taskType;
params.socialEnabled = true;
params.successBiasBeta = cfg.successBiasBeta;
params.copyErrorMode = cfg.copyErrorMode;
params.acceptanceRule = 'softmax';
params.acceptanceBeta = cfg.acceptanceBeta;
end

function S = initialiseMetricArrays(sz)
S = struct();
S.finalMean = nan(sz);
S.lossRate = nan(sz);
S.bestFunctionalLineageDepth = nan(sz);
S.bestStructuralLineageDepth = nan(sz);
S.finalMeanComponentAccuracy = nan(sz);
S.finalExactTargetFraction = nan(sz);
end

function S = storeMetric(S,sim,subs)
idx = substruct('()',subs);
S.finalMean = subsasgn(S.finalMean,idx,sim.finalMean);
S.lossRate = subsasgn(S.lossRate,idx,sim.lossRate);
S.bestFunctionalLineageDepth = subsasgn(S.bestFunctionalLineageDepth,idx,sim.finalBestFunctionalLineageDepth);
S.bestStructuralLineageDepth = subsasgn(S.bestStructuralLineageDepth,idx,sim.finalBestStructuralLineageDepth);
S.finalMeanComponentAccuracy = subsasgn(S.finalMeanComponentAccuracy,idx,sim.finalMeanComponentAccuracy);
S.finalExactTargetFraction = subsasgn(S.finalExactTargetFraction,idx,sim.finalExactTargetFraction);
end

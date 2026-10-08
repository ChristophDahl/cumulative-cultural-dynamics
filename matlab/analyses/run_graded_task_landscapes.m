function run_graded_task_landscapes()
%RUN_GRADED_TASK_LANDSCAPES
% Repeats the graded opacity and sequence-dependence analyses while adding
% task-independent structural lineage depth d_m. This directly tests whether
% restrictive tasks suppress structural accumulation itself or primarily
% suppress its payoff expression.

clc;
cfg = extended_analysis_config();
runTag = 'graded_task_landscapes';
outputDir = fullfile(cfg.resultDir, 'graded_task_landscapes');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
resultFile = fullfile(outputDir, 'graded_task_landscapes_results.mat');

familyNames = {'opacity_mix','sequence_mix'};
severityValues = {[0.00 0.25 0.50 0.75 0.90], ...
                  [0.00 0.25 0.50 0.75 1.00]};

nFamily = numel(familyNames);
nSeverity = numel(severityValues{1});
nSeed = cfg.nSeeds;
nMu = numel(cfg.muGrid);
nPhi = numel(cfg.phiGrid);
nTau = numel(cfg.tauLevels);

social = initialiseMetricArrays([nSeed nMu nPhi nTau nSeverity nFamily]);

fprintf('\n============================================================\n');
fprintf('CUMULATIVE CULTURAL DYNAMICS | GRADED TASK LANDSCAPES\n');
fprintf('============================================================\n');
fprintf('N=%d | T=%d | replicates=%d\n\n',cfg.nAgents,cfg.nGenerations,cfg.nSeeds);

for iff = 1:nFamily
    familyName = familyNames{iff};
    levels = severityValues{iff};

    for isev = 1:nSeverity
        severity = levels(isev);
        [taskType,overrides] = sensitivityParameters(familyName,severity,cfg);

        for it = 1:nTau
            tau = cfg.tauLevels(it);
            for im = 1:nMu
                mu = cfg.muGrid(im);
                for ip = 1:nPhi
                    phi = cfg.phiGrid(ip);
                    fprintf('family=%s severity=%.2f tau=%.2f mu=%.3f phi=%.3f\n', ...
                        familyName,severity,tau,mu,phi);

                    for s = 1:nSeed
                        % Same seed across severity within each family/grid point.
                        seed = cfg.baseSeed + 100000000 + 10000000*iff + ...
                            1000000*it + 100000*im + 10000*ip + s;

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
                        params = applyOverrides(params,overrides);

                        sim = simulate_extended_model(cfg,params,seed);
                        social = storeMetric(social,sim,{s,im,ip,it,isev,iff});
                    end
                end
            end
        end

        save(resultFile,'cfg','runTag','familyNames','severityValues','social','-v7.3');
        fprintf('Checkpoint saved after %s severity %.2f\n',familyName,severity);
    end
end

save(resultFile,'cfg','runTag','familyNames','severityValues','social','-v7.3');
fprintf('\nFinished. Saved to:\n%s\n',resultFile);
end

function [taskType,overrides] = sensitivityParameters(familyName,severity,cfg)
overrides = struct();
switch lower(familyName)
    case 'opacity_mix'
        taskType = 'opaque_mixed';
        overrides.opaqueMix = severity;
        overrides.opaquePower = cfg.opaquePower;
    case 'sequence_mix'
        taskType = 'sequence_mixed';
        overrides.sequenceMix = severity;
        overrides.strictPower = cfg.strictPower;
    otherwise
        error('Unknown family: %s',familyName);
end
end

function params = applyOverrides(params,overrides)
fields = fieldnames(overrides);
for i = 1:numel(fields)
    params.(fields{i}) = overrides.(fields{i});
end
end

function S = initialiseMetricArrays(sz)
S = struct();
S.finalMean = nan(sz);
S.lossRate = nan(sz);
S.bestFunctionalLineageDepth = nan(sz);
S.bestStructuralLineageDepth = nan(sz);
S.finalMeanComponentAccuracy = nan(sz);
S.finalMaxComponentAccuracy = nan(sz);
S.finalExactTargetFraction = nan(sz);
S.finalAnyExactTarget = nan(sz);
S.everAnyExactTarget = nan(sz);
S.firstExactTargetGeneration = nan(sz);
S.finalMeanPrefixFraction = nan(sz);
S.finalMaxPrefixFraction = nan(sz);
end

function S = storeMetric(S,sim,subs)
idx = substruct('()',subs);
S.finalMean = subsasgn(S.finalMean,idx,sim.finalMean);
S.lossRate = subsasgn(S.lossRate,idx,sim.lossRate);
S.bestFunctionalLineageDepth = subsasgn(S.bestFunctionalLineageDepth,idx,sim.finalBestFunctionalLineageDepth);
S.bestStructuralLineageDepth = subsasgn(S.bestStructuralLineageDepth,idx,sim.finalBestStructuralLineageDepth);
S.finalMeanComponentAccuracy = subsasgn(S.finalMeanComponentAccuracy,idx,sim.finalMeanComponentAccuracy);
S.finalMaxComponentAccuracy = subsasgn(S.finalMaxComponentAccuracy,idx,sim.finalMaxComponentAccuracy);
S.finalExactTargetFraction = subsasgn(S.finalExactTargetFraction,idx,sim.finalExactTargetFraction);
S.finalAnyExactTarget = subsasgn(S.finalAnyExactTarget,idx,double(sim.finalAnyExactTarget));
S.everAnyExactTarget = subsasgn(S.everAnyExactTarget,idx,double(sim.everAnyExactTarget));
S.firstExactTargetGeneration = subsasgn(S.firstExactTargetGeneration,idx,sim.firstExactTargetGeneration);
S.finalMeanPrefixFraction = subsasgn(S.finalMeanPrefixFraction,idx,sim.finalMeanPrefixFraction);
S.finalMaxPrefixFraction = subsasgn(S.finalMaxPrefixFraction,idx,sim.finalMaxPrefixFraction);
end

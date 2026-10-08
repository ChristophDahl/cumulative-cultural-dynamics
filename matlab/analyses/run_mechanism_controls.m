function run_mechanism_controls()
%RUN_MECHANISM_CONTROLS
% Runs the four mechanism conditions on the full manuscript grid and adds
% task-independent structural lineage depth. Matched controls use aligned
% random-number consumption.

clc;
cfg = extended_analysis_config();

runTag = 'mechanism_controls';
outputDir = fullfile(cfg.resultDir, 'mechanism_controls');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
resultFile = fullfile(outputDir, 'mechanism_controls_results.mat');
controlNames = {'baseline','random_demonstrator','random_copy_error','greedy_acceptance'};

nSeed = cfg.nSeeds;
nMu = numel(cfg.muGrid);
nPhi = numel(cfg.phiGrid);
nTau = numel(cfg.tauLevels);
nTask = numel(cfg.taskTypes);
nControl = numel(controlNames);

social = initialiseMetricArrays([nSeed nMu nPhi nTau nTask nControl]);

fprintf('\n============================================================\n');
fprintf('CUMULATIVE CULTURAL DYNAMICS | MECHANISM CONTROLS\n');
fprintf('============================================================\n');
fprintf('N=%d | T=%d | replicates=%d\n',cfg.nAgents,cfg.nGenerations,cfg.nSeeds);
fprintf('Result file: %s\n\n',resultFile);

total = nControl*nTask*nTau*nMu*nPhi;
counter = 0;

for ic = 1:nControl
    controlName = controlNames{ic};
    control = getControlParameters(cfg,controlName);

    for ik = 1:nTask
        taskType = cfg.taskTypes{ik};
        for it = 1:nTau
            tau = cfg.tauLevels(it);
            for im = 1:nMu
                mu = cfg.muGrid(im);
                for ip = 1:nPhi
                    phi = cfg.phiGrid(ip);
                    counter = counter + 1;
                    fprintf('%4d/%4d | %s | task=%s tau=%.2f mu=%.3f phi=%.3f\n', ...
                        counter,total,controlName,taskType,tau,mu,phi);

                    for s = 1:nSeed
                        % Same matched seed at a grid point for all controls.
                        seed = cfg.baseSeed + 70000000 + 1000000*ik + ...
                            100000*it + 10000*im + 100*ip + s;

                        params = struct();
                        params.mu = mu;
                        params.phi = phi;
                        params.tau = tau;
                        params.taskType = taskType;
                        params.socialEnabled = true;
                        params.successBiasBeta = control.successBiasBeta;
                        params.copyErrorMode = control.copyErrorMode;
                        params.acceptanceRule = control.acceptanceRule;
                        params.acceptanceBeta = cfg.acceptanceBeta;

                        sim = simulate_extended_model(cfg,params,seed);
                        social = storeMetric(social,sim,{s,im,ip,it,ik,ic});
                    end
                end
            end
        end
    end

    save(resultFile,'cfg','runTag','controlNames','social','-v7.3');
    fprintf('Checkpoint saved after control: %s\n',controlName);
end

save(resultFile,'cfg','runTag','controlNames','social','-v7.3');
fprintf('\nFinished. Saved to:\n%s\n',resultFile);
end

function S = initialiseMetricArrays(sz)
S = struct();
S.finalMean = nan(sz);
S.finalMax = nan(sz);
S.lossRate = nan(sz);
S.bestFunctionalLineageDepth = nan(sz);
S.maxFunctionalLineageDepth = nan(sz);
S.bestStructuralLineageDepth = nan(sz);
S.maxStructuralLineageDepth = nan(sz);
S.finalMeanComponentAccuracy = nan(sz);
S.finalMaxComponentAccuracy = nan(sz);
S.finalExactTargetFraction = nan(sz);
S.acceptedChangeRate = nan(sz);
S.functionalImprovementEventRate = nan(sz);
S.structuralImprovementEventRate = nan(sz);
end

function S = storeMetric(S,sim,subs)
idx = substruct('()',subs);
S.finalMean = subsasgn(S.finalMean,idx,sim.finalMean);
S.finalMax = subsasgn(S.finalMax,idx,sim.finalMax);
S.lossRate = subsasgn(S.lossRate,idx,sim.lossRate);
S.bestFunctionalLineageDepth = subsasgn(S.bestFunctionalLineageDepth,idx,sim.finalBestFunctionalLineageDepth);
S.maxFunctionalLineageDepth = subsasgn(S.maxFunctionalLineageDepth,idx,sim.finalMaxFunctionalLineageDepth);
S.bestStructuralLineageDepth = subsasgn(S.bestStructuralLineageDepth,idx,sim.finalBestStructuralLineageDepth);
S.maxStructuralLineageDepth = subsasgn(S.maxStructuralLineageDepth,idx,sim.finalMaxStructuralLineageDepth);
S.finalMeanComponentAccuracy = subsasgn(S.finalMeanComponentAccuracy,idx,sim.finalMeanComponentAccuracy);
S.finalMaxComponentAccuracy = subsasgn(S.finalMaxComponentAccuracy,idx,sim.finalMaxComponentAccuracy);
S.finalExactTargetFraction = subsasgn(S.finalExactTargetFraction,idx,sim.finalExactTargetFraction);
S.acceptedChangeRate = subsasgn(S.acceptedChangeRate,idx,sim.acceptedChangeRate);
S.functionalImprovementEventRate = subsasgn(S.functionalImprovementEventRate,idx,sim.functionalImprovementEventRate);
S.structuralImprovementEventRate = subsasgn(S.structuralImprovementEventRate,idx,sim.structuralImprovementEventRate);
end

function control = getControlParameters(cfg,name)
control = struct('successBiasBeta',cfg.successBiasBeta, ...
    'copyErrorMode',cfg.copyErrorMode,'acceptanceRule',cfg.acceptanceRule);
switch lower(name)
    case 'baseline'
    case 'random_demonstrator'
        control.successBiasBeta = 0;
    case 'random_copy_error'
        control.copyErrorMode = 'random';
    case 'greedy_acceptance'
        control.acceptanceRule = 'greedy';
    otherwise
        error('Unknown control: %s',name);
end
end

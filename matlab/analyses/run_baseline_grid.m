function run_baseline_grid()
%RUN_BASELINE_GRID Run the baseline manuscript parameter grid.
% Synchronous cultural-accumulation model with lineage tracking on the manuscript grid.
%
% This analysis includes:
%   - rooted project folders
%   - loss-only copying errors
%   - explicit task types:
%       smooth
%       opaque
%       strict_sequence
%   - asocial baselines computed only by mu and task type, then reused
%     across phi and tau
%   - fixed plotting:
%       social heatmaps use index-based axes, avoiding artificial negative
%       values on the mu axis
%       asocial metrics are plotted as one-dimensional curves over mu
%       instead of duplicated tau panels
%   - lineage tracking:
%       variantID
%       parentVariantID
%       generationCreated
%       sourceCode
%       quality
%       cumulativeImprovementDepth

clear; clc; close all;

%% ------------------------------------------------------------------------
% Configuration
% -------------------------------------------------------------------------

cfg = struct();

% Project folders
cfg.rootDir = repository_root();

cfg.dataDir    = fullfile(cfg.rootDir, 'data');
cfg.figureDir  = fullfile(cfg.rootDir, 'figures');
cfg.resultDir  = fullfile(cfg.rootDir, 'results');
cfg.srcDir     = fullfile(cfg.rootDir, 'matlab');

projectDirs = {cfg.dataDir, cfg.figureDir, cfg.resultDir, cfg.srcDir};
for dd = 1:numel(projectDirs)
    if ~exist(projectDirs{dd}, 'dir')
        mkdir(projectDirs{dd});
    end
end

addpath(genpath(cfg.srcDir));

% Family-specific output folder
outputDir = fullfile(cfg.resultDir, 'baseline');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

cfg.runTag = 'baseline_grid';

% Reproducibility
cfg.baseSeed = 1001;

% Population and simulation length
cfg.nAgents      = 30;
cfg.nGenerations = 80;
cfg.nSeeds       = 100;

% Behavioural task
cfg.seqLength    = 10;
cfg.alphabetSize = 5;

% Target sequence. For simplicity, the correct action is 1 at every step.
cfg.targetSeq = ones(1, cfg.seqLength);

% Explicit task types
cfg.taskTypes = {'smooth', 'opaque', 'strict_sequence'};

% Parameters for quality functions
cfg.opaqueMix   = 0.90;
cfg.opaquePower = 8;
cfg.strictPower = 2;

% Learning parameters
cfg.muGrid  = [0.00 0.03 0.08 0.15];
cfg.phiGrid = [0.45 0.65 0.80 0.92 0.98];

% Teaching/scaffolding levels
cfg.tauLevels = [0.00 0.60];

% Demonstrator access
cfg.kModels = 5;

% Social learning probability
cfg.socialLearningProb = 0.80;

% Copying-error mode
%
% 'random':
%   Copying errors randomly replace an action with another action.
%   This can accidentally improve an incorrect component.
%
% 'loss_only':
%   Copying errors can destroy correct structure but cannot repair an
%   incorrect component. This separates copying fidelity from innovation.

cfg.copyErrorMode = 'loss_only';

% Selection intensity for success-biased demonstrator choice
cfg.successBiasBeta = 5;

% Acceptance rule:
%  'greedy'  : retain candidate only if quality is not worse
%  'softmax' : probabilistic acceptance based on quality difference
cfg.acceptanceRule = 'softmax';
cfg.acceptanceBeta = 10;

% Threshold for treating the target solution as high-quality acquired
cfg.highQualityThreshold = 0.95;

% Numerical threshold for counting an improvement along a lineage
cfg.improvementEps = 1e-12;

%% ------------------------------------------------------------------------
% Run parameter sweep
% -------------------------------------------------------------------------

fprintf('\n============================================================\n');
fprintf('CUMULATIVE CULTURAL DYNAMICS | BASELINE GRID\n');
fprintf('============================================================\n');
fprintf('Agents: %d | Generations: %d | Seeds: %d\n', ...
    cfg.nAgents, cfg.nGenerations, cfg.nSeeds);
fprintf('Sequence length: %d | Alphabet size: %d\n', ...
    cfg.seqLength, cfg.alphabetSize);
fprintf('Task types: %s\n', strjoin(cfg.taskTypes, ', '));
fprintf('Root folder: %s\n', cfg.rootDir);
fprintf('Results folder: %s\n', outputDir);
fprintf('Figures folder: %s\n', cfg.figureDir);
fprintf('============================================================\n\n');

results = runParameterSweep(cfg);

resultFile = fullfile(outputDir, 'baseline_grid_results.mat');
save(resultFile, 'cfg', 'results');

fprintf('\nSaved results to:\n%s\n', resultFile);

%% ------------------------------------------------------------------------
% Plot summary phase diagrams
% -------------------------------------------------------------------------

plotPhaseDiagrams(cfg, results);

fprintf('\nFinished.\n');

end

%% ========================================================================
% Local functions
% ========================================================================

function results = runParameterSweep(cfg)

nMu   = numel(cfg.muGrid);
nPhi  = numel(cfg.phiGrid);
nTau  = numel(cfg.tauLevels);
nTask = numel(cfg.taskTypes);

template = nan(nMu, nPhi, nTau, nTask);

results = struct();

% Standard metrics
results.finalMean_social    = template;
results.finalMean_asocial   = template;
results.finalMax_social     = template;
results.finalMax_asocial    = template;
results.normalisedSocialGain        = template;
results.cceSlope_social     = template;
results.cceSlope_asocial    = template;
results.tradition_social    = template;
results.tradition_asocial   = template;
results.lossRate_social     = template;
results.lossRate_asocial    = template;
results.pHigh_social        = template;
results.pHigh_asocial       = template;
results.firstReach_social   = template;
results.firstReach_asocial  = template;

% Lineage metrics
results.functionalLineageDepth_social        = template;
results.functionalLineageDepth_asocial       = template;
results.bestFunctionalLineageDepth_social    = template;
results.bestFunctionalLineageDepth_asocial   = template;
results.improvementRate_social     = template;
results.improvementRate_asocial    = template;
results.acceptedChangeRate_social  = template;
results.acceptedChangeRate_asocial = template;
results.finalVariantCount_social   = template;
results.finalVariantCount_asocial  = template;

totalSocialCombos = nTask * nMu * nTau * nPhi;
socialCounter = 0;

for ik = 1:nTask

    taskType = cfg.taskTypes{ik};

    for im = 1:nMu

        mu = cfg.muGrid(im);

        % -------------------------------------------------------------
        % Asocial baseline:
        % computed once for each task type and innovation probability.
        % It is then copied across phi and tau, because phi and tau do
        % not operate when social learning is disabled.
        % -------------------------------------------------------------
        seedMetrics_asocial = initialiseSeedMetrics(cfg.nSeeds);

        for s = 1:cfg.nSeeds
            seed = cfg.baseSeed + 1000000*ik + 10000*im + s;

            params = struct();
            params.mu            = mu;
            params.phi           = NaN;
            params.tau           = NaN;
            params.taskType      = taskType;
            params.socialEnabled = false;

            simAsocial = runSingleSimulation(cfg, params, seed);
            seedMetrics_asocial = collectSeedMetrics(seedMetrics_asocial, simAsocial, s, cfg);
        end

        aggA = aggregateSeedMetrics(seedMetrics_asocial);

        for it = 1:nTau

            tau = cfg.tauLevels(it);

            for ip = 1:nPhi

                phi = cfg.phiGrid(ip);

                socialCounter = socialCounter + 1;

                fprintf('Social %3d/%3d | task=%s tau=%.2f mu=%.3f phi=%.3f\n', ...
                    socialCounter, totalSocialCombos, taskType, tau, mu, phi);

                seedMetrics_social = initialiseSeedMetrics(cfg.nSeeds);

                for s = 1:cfg.nSeeds
                    seed = cfg.baseSeed + 1000000*ik + 100000*it + ...
                           10000*im + 100*ip + s;

                    params = struct();
                    params.mu            = mu;
                    params.phi           = phi;
                    params.tau           = tau;
                    params.taskType      = taskType;
                    params.socialEnabled = true;

                    simSocial = runSingleSimulation(cfg, params, seed);
                    seedMetrics_social = collectSeedMetrics(seedMetrics_social, simSocial, s, cfg);
                end

                aggS = aggregateSeedMetrics(seedMetrics_social);

                results.finalMean_social(im,ip,it,ik)   = aggS.finalMean;
                results.finalMean_asocial(im,ip,it,ik)  = aggA.finalMean;
                results.finalMax_social(im,ip,it,ik)    = aggS.finalMax;
                results.finalMax_asocial(im,ip,it,ik)   = aggA.finalMax;
                results.cceSlope_social(im,ip,it,ik)    = aggS.cceSlope;
                results.cceSlope_asocial(im,ip,it,ik)   = aggA.cceSlope;
                results.tradition_social(im,ip,it,ik)   = aggS.tradition;
                results.tradition_asocial(im,ip,it,ik)  = aggA.tradition;
                results.lossRate_social(im,ip,it,ik)    = aggS.lossRate;
                results.lossRate_asocial(im,ip,it,ik)   = aggA.lossRate;
                results.pHigh_social(im,ip,it,ik)       = aggS.pHigh;
                results.pHigh_asocial(im,ip,it,ik)      = aggA.pHigh;
                results.firstReach_social(im,ip,it,ik)  = aggS.firstReach;
                results.firstReach_asocial(im,ip,it,ik) = aggA.firstReach;

                results.functionalLineageDepth_social(im,ip,it,ik)        = aggS.functionalLineageDepth;
                results.functionalLineageDepth_asocial(im,ip,it,ik)       = aggA.functionalLineageDepth;
                results.bestFunctionalLineageDepth_social(im,ip,it,ik)    = aggS.bestFunctionalLineageDepth;
                results.bestFunctionalLineageDepth_asocial(im,ip,it,ik)   = aggA.bestFunctionalLineageDepth;
                results.improvementRate_social(im,ip,it,ik)     = aggS.improvementRate;
                results.improvementRate_asocial(im,ip,it,ik)    = aggA.improvementRate;
                results.acceptedChangeRate_social(im,ip,it,ik)  = aggS.acceptedChangeRate;
                results.acceptedChangeRate_asocial(im,ip,it,ik) = aggA.acceptedChangeRate;
                results.finalVariantCount_social(im,ip,it,ik)   = aggS.finalVariantCount;
                results.finalVariantCount_asocial(im,ip,it,ik)  = aggA.finalVariantCount;

                denom = max(1e-9, 1 - aggA.finalMean);
                results.normalisedSocialGain(im,ip,it,ik) = ...
                    (aggS.finalMean - aggA.finalMean) / denom;
            end
        end
    end
end

end

function seedMetrics = initialiseSeedMetrics(nSeeds)

seedMetrics = struct();
seedMetrics.finalMean  = nan(nSeeds,1);
seedMetrics.finalMax   = nan(nSeeds,1);
seedMetrics.cceSlope   = nan(nSeeds,1);
seedMetrics.tradition  = nan(nSeeds,1);
seedMetrics.lossRate   = nan(nSeeds,1);
seedMetrics.pHigh      = nan(nSeeds,1);
seedMetrics.firstReach = nan(nSeeds,1);

seedMetrics.functionalLineageDepth       = nan(nSeeds,1);
seedMetrics.bestFunctionalLineageDepth   = nan(nSeeds,1);
seedMetrics.improvementRate    = nan(nSeeds,1);
seedMetrics.acceptedChangeRate = nan(nSeeds,1);
seedMetrics.finalVariantCount  = nan(nSeeds,1);

end

function seedMetrics = collectSeedMetrics(seedMetrics, sim, s, cfg)

seedMetrics.finalMean(s) = sim.meanQuality(end);
seedMetrics.finalMax(s)  = sim.maxQuality(end);

t = (1:numel(sim.meanQuality))';
idx = t > floor(numel(t)/2);
p = polyfit(t(idx), sim.meanQuality(idx), 1);
seedMetrics.cceSlope(s) = p(1);

seedMetrics.tradition(s) = sim.traditionStrength(end);

dqMax = diff(sim.maxQuality);
seedMetrics.lossRate(s) = mean(dqMax < -1e-12);

seedMetrics.pHigh(s) = mean(sim.finalQualities >= cfg.highQualityThreshold);

idxHigh = find(sim.maxQuality >= cfg.highQualityThreshold, 1, 'first');
if isempty(idxHigh)
    seedMetrics.firstReach(s) = NaN;
else
    seedMetrics.firstReach(s) = idxHigh;
end

seedMetrics.functionalLineageDepth(s)       = sim.finalMaxFunctionalLineageDepth;
seedMetrics.bestFunctionalLineageDepth(s)   = sim.finalBestFunctionalLineageDepth;
seedMetrics.improvementRate(s)    = sim.improvementEventRate;
seedMetrics.acceptedChangeRate(s) = sim.acceptedChangeRate;
seedMetrics.finalVariantCount(s)  = sim.finalVariantCount;

end

function agg = aggregateSeedMetrics(seedMetrics)

agg = struct();

fields = fieldnames(seedMetrics);
for f = 1:numel(fields)
    x = seedMetrics.(fields{f});
    if all(isnan(x))
        agg.(fields{f}) = NaN;
    else
        agg.(fields{f}) = mean(x, 'omitnan');
    end
end

end

function sim = runSingleSimulation(cfg, params, seed)

rng(seed);

n = cfg.nAgents;
D = cfg.seqLength;
A = cfg.alphabetSize;

pop = randi(A, n, D);
q = evaluatePopulation(pop, cfg, params);

% Initialise lineage store.
variantStore = initialiseVariantStore(D);

agentVariantID = nan(n,1);
for i = 1:n
    [variantStore, newID] = addVariant(variantStore, pop(i,:), 0, 0, 1, q(i), cfg);
    agentVariantID(i) = newID;
end

meanQuality = nan(cfg.nGenerations,1);
maxQuality  = nan(cfg.nGenerations,1);
tradition   = nan(cfg.nGenerations,1);

acceptedChangeCount = 0;
improvementEventCount = 0;

for gen = 1:cfg.nGenerations

    % ------------------------------------------------------------------
    % Synchronous generational update.
    %
    % Demonstrators are always sampled from the previous generation
    % (pop_old/q_old/agentVariantID_old). Candidate outcomes are written
    % to pop_new/q_new/agentVariantID_new and become visible only after all
    % agents have had one update opportunity. This prevents within-generation
    % copying cascades in which early-updated agents can immediately become
    % demonstrators for later-updated agents in the same generation.
    % ------------------------------------------------------------------
    pop_old = pop;
    q_old = q;
    agentVariantID_old = agentVariantID;

    pop_new = pop_old;
    q_new = q_old;
    agentVariantID_new = agentVariantID_old;

    order = randperm(n);

    for idx = 1:n
        i = order(idx);

        current = pop_old(i,:);
        qCurrent = q_old(i);
        currentVariantID = agentVariantID_old(i);

        candidate = current;
        candidateParentID = currentVariantID;

        didSocial = false;
        didCopyError = false;
        didInnovate = false;

        if params.socialEnabled && rand < cfg.socialLearningProb
            j = chooseDemonstrator(i, pop_old, q_old, cfg);

            demo = pop_old(j,:);
            demoVariantID = agentVariantID_old(j);

            [candidate, didCopyError] = copyBehaviour(demo, cfg, params);

            candidateParentID = demoVariantID;
            didSocial = true;
        end

        [candidate, didInnovate] = innovateBehaviour(candidate, cfg, params);

        qCandidate = evaluateBehaviour(candidate, cfg, params);

        accept = acceptCandidate(qCurrent, qCandidate, cfg);

        if accept && any(candidate ~= current)

            sourceCode = classifySource(didSocial, didCopyError, didInnovate);

            qParent = variantStore.quality(candidateParentID);
            isImprovement = qCandidate > qParent + cfg.improvementEps;

            [variantStore, newVariantID] = addVariant( ...
                variantStore, candidate, candidateParentID, gen, ...
                sourceCode, qCandidate, cfg);

            pop_new(i,:) = candidate;
            q_new(i) = qCandidate;
            agentVariantID_new(i) = newVariantID;

            acceptedChangeCount = acceptedChangeCount + 1;
            if isImprovement
                improvementEventCount = improvementEventCount + 1;
            end
        end
    end

    pop = pop_new;
    q = q_new;
    agentVariantID = agentVariantID_new;

    meanQuality(gen) = mean(q);
    maxQuality(gen)  = max(q);
    tradition(gen)   = computeTraditionStrength(pop);
end

finalFunctionalLineageDepths = variantStore.functionalDepth(agentVariantID);
finalMaxFunctionalLineageDepth = max(finalFunctionalLineageDepths);

bestQ = max(q);
bestIdx = q >= bestQ - 1e-12;
finalBestFunctionalLineageDepth = max(finalFunctionalLineageDepths(bestIdx));

nUpdateOpportunities = cfg.nAgents * cfg.nGenerations;

sim = struct();
sim.meanQuality       = meanQuality;
sim.maxQuality        = maxQuality;
sim.traditionStrength = tradition;
sim.finalPopulation   = pop;
sim.finalQualities    = q;

sim.finalAgentVariantID     = agentVariantID;
sim.variantStore            = variantStore;
sim.finalMaxFunctionalLineageDepth    = finalMaxFunctionalLineageDepth;
sim.finalBestFunctionalLineageDepth   = finalBestFunctionalLineageDepth;
sim.finalVariantCount       = numel(variantStore.parentID);
sim.acceptedChangeRate      = acceptedChangeCount / nUpdateOpportunities;
sim.improvementEventRate    = improvementEventCount / nUpdateOpportunities;

end

function variantStore = initialiseVariantStore(D)

variantStore = struct();
variantStore.seq      = zeros(0,D);
variantStore.parentID = zeros(0,1);
variantStore.gen      = zeros(0,1);
variantStore.source   = zeros(0,1);
variantStore.quality  = zeros(0,1);
variantStore.functionalDepth    = zeros(0,1);

end

function [variantStore, newID] = addVariant(variantStore, seq, parentID, gen, sourceCode, quality, cfg)

newID = size(variantStore.seq, 1) + 1;

variantStore.seq(newID,:)    = seq;
variantStore.parentID(newID) = parentID;
variantStore.gen(newID)      = gen;
variantStore.source(newID)   = sourceCode;
variantStore.quality(newID)  = quality;

if parentID == 0
    variantStore.functionalDepth(newID) = 0;
else
    parentDepth = variantStore.functionalDepth(parentID);
    parentQ = variantStore.quality(parentID);

    if quality > parentQ + cfg.improvementEps
        variantStore.functionalDepth(newID) = parentDepth + 1;
    else
        variantStore.functionalDepth(newID) = parentDepth;
    end
end

end

function sourceCode = classifySource(didSocial, didCopyError, didInnovate)
% Source-code key:
%   1 = initial variant
%   2 = asocial innovation
%   3 = faithful social copy
%   4 = social copy with copying error
%   5 = faithful social copy plus innovation
%   6 = social copy with copying error plus innovation
%   7 = other accepted change

if ~didSocial && didInnovate
    sourceCode = 2;
elseif didSocial && ~didCopyError && ~didInnovate
    sourceCode = 3;
elseif didSocial && didCopyError && ~didInnovate
    sourceCode = 4;
elseif didSocial && ~didCopyError && didInnovate
    sourceCode = 5;
elseif didSocial && didCopyError && didInnovate
    sourceCode = 6;
else
    sourceCode = 7;
end

end

function q = evaluatePopulation(pop, cfg, params)

n = size(pop,1);
q = nan(n,1);

for i = 1:n
    q(i) = evaluateBehaviour(pop(i,:), cfg, params);
end

end

function q = evaluateBehaviour(seq, cfg, params)
% Behaviour quality in [0,1].
%
% smooth:
%   Quality is the fraction of correct components.
%
% opaque:
%   Partial component correctness is weakly rewarded, but high quality
%   requires many correct components at once.
%
% strict_sequence:
%   Quality depends on the longest correct prefix. Correct components that
%   occur after the first incorrect component do not help. This imposes
%   order dependence.

target = cfg.targetSeq;
m = mean(seq == target);

switch lower(params.taskType)

    case 'smooth'
        q = m;

    case 'opaque'
        qSmooth = m;
        qOpaque = m ^ cfg.opaquePower;
        q = (1 - cfg.opaqueMix) * qSmooth + cfg.opaqueMix * qOpaque;

    case 'strict_sequence'
        prefixLength = 0;

        for d = 1:cfg.seqLength
            if seq(d) == target(d)
                prefixLength = prefixLength + 1;
            else
                break;
            end
        end

        prefixFraction = prefixLength / cfg.seqLength;
        q = prefixFraction ^ cfg.strictPower;

    otherwise
        error('Unknown params.taskType: %s', params.taskType);
end

q = min(max(q,0),1);

end

function j = chooseDemonstrator(i, pop, q, cfg)

n = size(pop,1);
candidates = setdiff(1:n, i);

if cfg.kModels < numel(candidates)
    candidates = candidates(randperm(numel(candidates), cfg.kModels));
end

qc = q(candidates);
w = exp(cfg.successBiasBeta * (qc - max(qc)));
w = w ./ sum(w);

u = rand;
cw = cumsum(w);
idx = find(u <= cw, 1, 'first');
j = candidates(idx);

end

function [copied, didCopyError] = copyBehaviour(demo, cfg, params)
% Copy demonstrator's action sequence with component-wise fidelity.
%
% In loss_only mode, copying errors can destroy correct structure but
% cannot repair incorrect structure.

D = cfg.seqLength;
A = cfg.alphabetSize;

phiEff = params.phi + params.tau * (1 - params.phi);
phiEff = min(max(phiEff, 0), 1);

copied = demo;
didCopyError = false;

for d = 1:D

    if rand <= phiEff
        copied(d) = demo(d);
        continue;
    end

    didCopyError = true;

    switch lower(cfg.copyErrorMode)

        case 'random'
            alternatives = setdiff(1:A, demo(d));
            copied(d) = alternatives(randi(numel(alternatives)));

        case 'loss_only'
            targetAction = cfg.targetSeq(d);
            wrongActions = setdiff(1:A, targetAction);
            copied(d) = wrongActions(randi(numel(wrongActions)));

        otherwise
            error('Unknown cfg.copyErrorMode: %s', cfg.copyErrorMode);
    end
end

end

function [seq, didInnovate] = innovateBehaviour(seq, cfg, params)
% Innovation is implemented as random modification of one action component.

didInnovate = false;

if rand < params.mu
    d = randi(cfg.seqLength);
    alternatives = setdiff(1:cfg.alphabetSize, seq(d));
    seq(d) = alternatives(randi(numel(alternatives)));
    didInnovate = true;
end

end

function accept = acceptCandidate(qCurrent, qCandidate, cfg)

switch lower(cfg.acceptanceRule)

    case 'greedy'
        accept = qCandidate >= qCurrent;

    case 'softmax'
        pAccept = 1 ./ (1 + exp(-cfg.acceptanceBeta * (qCandidate - qCurrent)));
        accept = rand < pAccept;

    otherwise
        error('Unknown acceptanceRule: %s', cfg.acceptanceRule);
end

end

function trad = computeTraditionStrength(pop)

[~,~,ic] = unique(pop, 'rows');
counts = accumarray(ic, 1);
trad = max(counts) / size(pop,1);

end

function plotPhaseDiagrams(cfg, results)

socialMetrics = { ...
    'normalisedSocialGain',             'Normalised social gain'; ...
    'finalMean_social',         'Final mean quality, social'; ...
    'cceSlope_social',          'CCE slope, social'; ...
    'tradition_social',         'Tradition strength, social'; ...
    'lossRate_social',          'Loss rate, social'; ...
    'functionalLineageDepth_social',      'Functional lineage depth, social'; ...
    'bestFunctionalLineageDepth_social',  'Best-solution functional lineage depth, social'; ...
    'improvementRate_social',   'Improvement-event rate, social'};

asocialMetrics = { ...
    'finalMean_asocial',        'Final mean quality, asocial'; ...
    'cceSlope_asocial',         'CCE slope, asocial'; ...
    'lossRate_asocial',         'Loss rate, asocial'; ...
    'functionalLineageDepth_asocial',     'Functional lineage depth, asocial'; ...
    'bestFunctionalLineageDepth_asocial', 'Best-solution functional lineage depth, asocial'; ...
    'improvementRate_asocial',  'Improvement-event rate, asocial'};

for m = 1:size(socialMetrics,1)

    metricName  = socialMetrics{m,1};
    metricTitle = socialMetrics{m,2};

    for ik = 1:numel(cfg.taskTypes)

        taskType = cfg.taskTypes{ik};

        fig = figure('Color','w', 'Position', [100 100 1300 380]);

        for it = 1:numel(cfg.tauLevels)

            tau = cfg.tauLevels(it);

            subplot(1, numel(cfg.tauLevels), it);

            Z = squeeze(results.(metricName)(:,:,it,ik));

            imagesc(Z);
            set(gca, 'YDir', 'normal');

            set(gca, ...
                'XTick', 1:numel(cfg.phiGrid), ...
                'XTickLabel', compose('%.2g', cfg.phiGrid), ...
                'YTick', 1:numel(cfg.muGrid), ...
                'YTickLabel', compose('%.2f', cfg.muGrid));

            xlabel('Copying fidelity \phi');
            ylabel('Innovation probability \mu');
            title(sprintf('\\tau = %.2f', tau));

            cb = colorbar;
            ylabel(cb, metricTitle);

            axis square;
            box off;
            set(gca, 'TickDir', 'out');
        end

        sgtitle(sprintf('%s | task type = %s', metricTitle, strrep(taskType,'_','\_')), ...
            'FontWeight', 'bold');

        fname = sprintf('%s_%s_%s.png', cfg.runTag, metricName, taskType);
        exportgraphics(fig, fullfile(cfg.figureDir, fname), 'Resolution', 300);

        fnamePdf = sprintf('%s_%s_%s.pdf', cfg.runTag, metricName, taskType);
        exportgraphics(fig, fullfile(cfg.figureDir, fnamePdf), 'ContentType', 'vector');

        close(fig);
    end
end

for m = 1:size(asocialMetrics,1)

    metricName  = asocialMetrics{m,1};
    metricTitle = asocialMetrics{m,2};

    for ik = 1:numel(cfg.taskTypes)

        taskType = cfg.taskTypes{ik};

        % Asocial metrics are invariant across phi and tau in this design.
        % Use phi index 1 and tau index 1 only.
        y = squeeze(results.(metricName)(:,1,1,ik));

        fig = figure('Color','w', 'Position', [100 100 620 460]);

        plot(cfg.muGrid, y, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);

        xlabel('Innovation probability \mu');
        ylabel(metricTitle);
        title(sprintf('%s | task type = %s', metricTitle, strrep(taskType,'_','\_')), ...
            'FontWeight', 'bold');

        xlim([min(cfg.muGrid) max(cfg.muGrid)]);
        box off;
        set(gca, 'TickDir', 'out');

        fname = sprintf('%s_%s_%s_asocialCurve.png', cfg.runTag, metricName, taskType);
        exportgraphics(fig, fullfile(cfg.figureDir, fname), 'Resolution', 300);

        fnamePdf = sprintf('%s_%s_%s_asocialCurve.pdf', cfg.runTag, metricName, taskType);
        exportgraphics(fig, fullfile(cfg.figureDir, fnamePdf), 'ContentType', 'vector');

        close(fig);
    end
end

end

function sim = simulate_quality_dynamics(cfg, params, seed)
%SIMULATE_QUALITY_DYNAMICS Run one synchronous cultural-dynamics simulation.
%
% Required params fields:
%   mu, taskType, socialEnabled
%
% Required for social runs:
%   phi, tau
%
% Optional overrides:
%   successBiasBeta, copyErrorMode, acceptanceRule,
%   opaqueMix, opaquePower, strictPower, sequenceMix

rng(seed, 'twister');

params = applyDefaults(cfg, params);

n = cfg.nAgents;
D = cfg.seqLength;
A = cfg.alphabetSize;

pop = randi(A, n, D);
q = evaluatePopulation(pop, cfg, params);

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

    % Synchronous update: all demonstrators come from the population state
    % at the beginning of the generation. New behaviours become visible
    % only after every agent has completed its update opportunity.
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
            j = chooseDemonstrator(i, q_old, cfg, params);
            demo = pop_old(j,:);
            demoVariantID = agentVariantID_old(j);

            [candidate, didCopyError] = copyBehaviour(demo, cfg, params);
            candidateParentID = demoVariantID;
            didSocial = true;
        end

        [candidate, didInnovate] = innovateBehaviour(candidate, cfg, params.mu);
        qCandidate = evaluateBehaviour(candidate, cfg, params);

        accept = acceptCandidate(qCurrent, qCandidate, cfg, params);

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
    maxQuality(gen) = max(q);
    tradition(gen) = computeTraditionStrength(pop);
end

finalFunctionalLineageDepths = variantStore.functionalDepth(agentVariantID);
finalMaxFunctionalLineageDepth = max(finalFunctionalLineageDepths);

bestQ = max(q);
bestIdx = q >= bestQ - 1e-12;
finalBestFunctionalLineageDepth = max(finalFunctionalLineageDepths(bestIdx));

nUpdateOpportunities = cfg.nAgents * cfg.nGenerations;

sim = struct();
sim.meanQuality = meanQuality;
sim.maxQuality = maxQuality;
sim.traditionStrength = tradition;
sim.finalQualities = q;
sim.finalMean = mean(q);
sim.finalMax = max(q);
sim.lossRate = mean(diff(maxQuality) < -1e-12);
sim.pHigh = mean(q >= cfg.highQualityThreshold);
sim.finalMaxFunctionalLineageDepth = finalMaxFunctionalLineageDepth;
sim.finalBestFunctionalLineageDepth = finalBestFunctionalLineageDepth;
sim.finalVariantCount = numel(variantStore.parentID);
sim.acceptedChangeRate = acceptedChangeCount / nUpdateOpportunities;
sim.improvementEventRate = improvementEventCount / nUpdateOpportunities;
sim.finalTraditionStrength = tradition(end);

end

function params = applyDefaults(cfg, params)

if ~isfield(params, 'phi'), params.phi = NaN; end
if ~isfield(params, 'tau'), params.tau = NaN; end
if ~isfield(params, 'successBiasBeta'), params.successBiasBeta = cfg.successBiasBeta; end
if ~isfield(params, 'copyErrorMode'), params.copyErrorMode = cfg.copyErrorMode; end
if ~isfield(params, 'acceptanceRule'), params.acceptanceRule = cfg.acceptanceRule; end
if ~isfield(params, 'acceptanceBeta'), params.acceptanceBeta = cfg.acceptanceBeta; end
if ~isfield(params, 'opaqueMix'), params.opaqueMix = cfg.opaqueMix; end
if ~isfield(params, 'opaquePower'), params.opaquePower = cfg.opaquePower; end
if ~isfield(params, 'strictPower'), params.strictPower = cfg.strictPower; end
if ~isfield(params, 'sequenceMix'), params.sequenceMix = 1; end

end

function variantStore = initialiseVariantStore(D)
variantStore = struct();
variantStore.seq = zeros(0,D);
variantStore.parentID = zeros(0,1);
variantStore.gen = zeros(0,1);
variantStore.source = zeros(0,1);
variantStore.quality = zeros(0,1);
variantStore.functionalDepth = zeros(0,1);
end

function [variantStore, newID] = addVariant(variantStore, seq, parentID, gen, sourceCode, quality, cfg)
newID = size(variantStore.seq,1) + 1;
variantStore.seq(newID,:) = seq;
variantStore.parentID(newID,1) = parentID;
variantStore.gen(newID,1) = gen;
variantStore.source(newID,1) = sourceCode;
variantStore.quality(newID,1) = quality;

if parentID == 0
    variantStore.functionalDepth(newID,1) = 0;
else
    parentDepth = variantStore.functionalDepth(parentID);
    parentQ = variantStore.quality(parentID);
    if quality > parentQ + cfg.improvementEps
        variantStore.functionalDepth(newID,1) = parentDepth + 1;
    else
        variantStore.functionalDepth(newID,1) = parentDepth;
    end
end
end

function sourceCode = classifySource(didSocial, didCopyError, didInnovate)
% 1 initial; 2 asocial innovation; 3 faithful social copy;
% 4 social copy with error; 5 faithful copy plus innovation;
% 6 copy error plus innovation; 7 other.
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
target = cfg.targetSeq;
m = mean(seq == target);

prefixLength = 0;
for d = 1:cfg.seqLength
    if seq(d) == target(d)
        prefixLength = prefixLength + 1;
    else
        break;
    end
end
prefixFraction = prefixLength / cfg.seqLength;

switch lower(params.taskType)
    case 'smooth'
        q = m;

    case 'opaque'
        q = (1 - params.opaqueMix) * m + ...
            params.opaqueMix * (m ^ params.opaquePower);

    case 'strict_sequence'
        q = prefixFraction ^ params.strictPower;

    case 'opaque_mixed'
        % A continuum from smooth (opaqueMix = 0) to the original opaque
        % task (opaqueMix = 0.90, opaquePower = 8).
        q = (1 - params.opaqueMix) * m + ...
            params.opaqueMix * (m ^ params.opaquePower);

    case 'sequence_mixed'
        % A continuum from smooth component reward (sequenceMix = 0) to
        % the original strict-sequence rule (sequenceMix = 1).
        qStrict = prefixFraction ^ params.strictPower;
        q = (1 - params.sequenceMix) * m + params.sequenceMix * qStrict;

    otherwise
        error('Unknown taskType: %s', params.taskType);
end

q = min(max(q,0),1);
end

function j = chooseDemonstrator(i, q, cfg, params)
n = numel(q);
candidates = setdiff(1:n, i);
if cfg.kModels < numel(candidates)
    candidates = candidates(randperm(numel(candidates), cfg.kModels));
end

qc = q(candidates);
if abs(params.successBiasBeta) < eps
    w = ones(size(qc)) / numel(qc);
else
    w = exp(params.successBiasBeta * (qc - max(qc)));
    w = w / sum(w);
end

u = rand;
cw = cumsum(w);
idx = find(u <= cw, 1, 'first');
if isempty(idx), idx = numel(candidates); end
j = candidates(idx);
end

function [copied, didCopyError] = copyBehaviour(demo, cfg, params)
D = cfg.seqLength;
A = cfg.alphabetSize;
phiEff = params.phi + params.tau * (1 - params.phi);
phiEff = min(max(phiEff,0),1);

copied = demo;
didCopyError = false;
for d = 1:D
    if rand <= phiEff
        continue;
    end

    didCopyError = true;
    switch lower(params.copyErrorMode)
        case 'loss_only'
            targetAction = cfg.targetSeq(d);
            wrongActions = setdiff(1:A, targetAction);
            copied(d) = wrongActions(randi(numel(wrongActions)));

        case 'random'
            alternatives = setdiff(1:A, demo(d));
            copied(d) = alternatives(randi(numel(alternatives)));

        otherwise
            error('Unknown copyErrorMode: %s', params.copyErrorMode);
    end
end
end

function [seq, didInnovate] = innovateBehaviour(seq, cfg, mu)
didInnovate = false;
if rand < mu
    d = randi(cfg.seqLength);
    alternatives = setdiff(1:cfg.alphabetSize, seq(d));
    seq(d) = alternatives(randi(numel(alternatives)));
    didInnovate = true;
end
end

function accept = acceptCandidate(qCurrent, qCandidate, cfg, params)
switch lower(params.acceptanceRule)
    case 'greedy'
        accept = qCandidate >= qCurrent;

    case 'softmax'
        pAccept = 1 / (1 + exp(-params.acceptanceBeta * (qCandidate - qCurrent)));
        accept = rand < pAccept;

    otherwise
        error('Unknown acceptanceRule: %s', params.acceptanceRule);
end
end

function trad = computeTraditionStrength(pop)
[~,~,ic] = unique(pop, 'rows');
counts = accumarray(ic,1);
trad = max(counts) / size(pop,1);
end

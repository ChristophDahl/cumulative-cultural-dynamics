function sim = simulate_extended_model(cfg, params, seed)
%SIMULATE_EXTENDED_MODEL Synchronous simulation with functional and structural ancestry metrics.
%
% This simulation additionally tracks:
%   1. functional lineage depth d_q based on task-specific quality q;
%   2. structural lineage depth d_m based on component accuracy m;
%   3. common-scale component, prefix, and exact-target outcomes.
%
% Within-agent update order is exactly:
%   current state -> optional social copy -> innovation -> evaluation ->
%   acceptance -> synchronous replacement after all agents update.
%
% The function consumes one acceptance uniform random variate on every update,
% including deterministic/greedy controls. This keeps random-number consumption
% aligned across matched mechanism controls while leaving baseline softmax
% behaviour unchanged.

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

meanComponentAccuracy = nan(cfg.nGenerations,1);
maxComponentAccuracy  = nan(cfg.nGenerations,1);
meanPrefixFraction    = nan(cfg.nGenerations,1);
maxPrefixFraction     = nan(cfg.nGenerations,1);
exactTargetFraction   = nan(cfg.nGenerations,1);

initialExact = all(pop == cfg.targetSeq, 2);
everAnyExactTarget = any(initialExact);
firstExactTargetGeneration = NaN;
if everAnyExactTarget
    firstExactTargetGeneration = 0;
end

acceptedChangeCount = 0;
functionalImprovementEventCount = 0;
structuralImprovementEventCount = 0;

for gen = 1:cfg.nGenerations

    % Synchronous update. Demonstrators and current-state comparisons come
    % only from the population at the start of the cultural update round.
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

        % 1. Optional social copying.
        if params.socialEnabled && rand < cfg.socialLearningProb
            j = chooseDemonstrator(i, q_old, cfg, params);
            demo = pop_old(j,:);
            demoVariantID = agentVariantID_old(j);

            [candidate, didCopyError] = copyBehaviour(demo, cfg, params);
            candidateParentID = demoVariantID;
            didSocial = true;
        end

        % 2. Innovation acts on the current candidate, including after copy.
        [candidate, didInnovate] = innovateBehaviour(candidate, cfg, params.mu);

        % 3. Evaluate the resulting candidate under the task payoff.
        qCandidate = evaluateBehaviour(candidate, cfg, params);

        % 4. Accept/reject relative to the learner's current behaviour.
        accept = acceptCandidate(qCurrent, qCandidate, params);

        if accept && any(candidate ~= current)
            sourceCode = classifySource(didSocial, didCopyError, didInnovate);

            parentQ = variantStore.quality(candidateParentID);
            parentM = variantStore.componentAccuracy(candidateParentID);
            candidateM = componentAccuracy(candidate, cfg);

            isFunctionalImprovement = qCandidate > parentQ + cfg.improvementEps;
            isStructuralImprovement = candidateM > parentM + cfg.improvementEps;

            [variantStore, newVariantID] = addVariant( ...
                variantStore, candidate, candidateParentID, gen, ...
                sourceCode, qCandidate, cfg);

            pop_new(i,:) = candidate;
            q_new(i) = qCandidate;
            agentVariantID_new(i) = newVariantID;

            acceptedChangeCount = acceptedChangeCount + 1;
            if isFunctionalImprovement
                functionalImprovementEventCount = functionalImprovementEventCount + 1;
            end
            if isStructuralImprovement
                structuralImprovementEventCount = structuralImprovementEventCount + 1;
            end
        end
    end

    % 5. Replace population only after all agents have updated.
    pop = pop_new;
    q = q_new;
    agentVariantID = agentVariantID_new;

    meanQuality(gen) = mean(q);
    maxQuality(gen) = max(q);
    tradition(gen) = computeTraditionStrength(pop);

    [componentAcc, prefixFrac, exactTarget] = commonBehaviourMetrics(pop, cfg);
    meanComponentAccuracy(gen) = mean(componentAcc);
    maxComponentAccuracy(gen) = max(componentAcc);
    meanPrefixFraction(gen) = mean(prefixFrac);
    maxPrefixFraction(gen) = max(prefixFrac);
    exactTargetFraction(gen) = mean(exactTarget);

    if ~everAnyExactTarget && any(exactTarget)
        everAnyExactTarget = true;
        firstExactTargetGeneration = gen;
    end
end

finalFunctionalDepths = variantStore.functionalDepth(agentVariantID);
finalStructuralDepths = variantStore.structuralDepth(agentVariantID);

finalMaxFunctionalLineageDepth = max(finalFunctionalDepths);
finalMaxStructuralLineageDepth = max(finalStructuralDepths);

bestQ = max(q);
bestQIdx = q >= bestQ - cfg.improvementEps;
finalBestFunctionalLineageDepth = max(finalFunctionalDepths(bestQIdx));

[finalComponentAcc, finalPrefixFrac, finalExactTarget] = commonBehaviourMetrics(pop, cfg);
bestM = max(finalComponentAcc);
bestMIdx = finalComponentAcc >= bestM - cfg.improvementEps;
finalBestStructuralLineageDepth = max(finalStructuralDepths(bestMIdx));

nUpdateOpportunities = cfg.nAgents * cfg.nGenerations;

sim = struct();
sim.meanQuality = meanQuality;
sim.maxQuality = maxQuality;
sim.traditionStrength = tradition;
sim.meanComponentAccuracy = meanComponentAccuracy;
sim.maxComponentAccuracy = maxComponentAccuracy;
sim.meanPrefixFraction = meanPrefixFraction;
sim.maxPrefixFraction = maxPrefixFraction;
sim.exactTargetFraction = exactTargetFraction;

sim.finalQualities = q;
sim.finalMean = mean(q);
sim.finalMax = max(q);
sim.lossRate = mean(diff(maxQuality) < -cfg.improvementEps);
sim.pHigh = mean(q >= cfg.highQualityThreshold);

sim.finalMaxFunctionalLineageDepth = finalMaxFunctionalLineageDepth;
sim.finalBestFunctionalLineageDepth = finalBestFunctionalLineageDepth;
sim.finalMaxStructuralLineageDepth = finalMaxStructuralLineageDepth;
sim.finalBestStructuralLineageDepth = finalBestStructuralLineageDepth;

sim.finalVariantCount = numel(variantStore.parentID);
sim.acceptedChangeRate = acceptedChangeCount / nUpdateOpportunities;
sim.functionalImprovementEventRate = functionalImprovementEventCount / nUpdateOpportunities;
sim.structuralImprovementEventRate = structuralImprovementEventCount / nUpdateOpportunities;
sim.improvementEventRate = sim.functionalImprovementEventRate;
sim.finalTraditionStrength = tradition(end);

% Severity-independent common-scale outcomes.
sim.finalMeanComponentAccuracy = mean(finalComponentAcc);
sim.finalMaxComponentAccuracy = max(finalComponentAcc);
sim.finalExactTargetFraction = mean(finalExactTarget);
sim.finalAnyExactTarget = any(finalExactTarget);
sim.everAnyExactTarget = everAnyExactTarget;
sim.firstExactTargetGeneration = firstExactTargetGeneration;
sim.finalMeanPrefixFraction = mean(finalPrefixFrac);
sim.finalMaxPrefixFraction = max(finalPrefixFrac);

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
variantStore.componentAccuracy = zeros(0,1);
variantStore.functionalDepth = zeros(0,1);
variantStore.structuralDepth = zeros(0,1);
end

function [variantStore, newID] = addVariant(variantStore, seq, parentID, gen, sourceCode, quality, cfg)
newID = size(variantStore.seq,1) + 1;
variantStore.seq(newID,:) = seq;
variantStore.parentID(newID,1) = parentID;
variantStore.gen(newID,1) = gen;
variantStore.source(newID,1) = sourceCode;
variantStore.quality(newID,1) = quality;
variantStore.componentAccuracy(newID,1) = componentAccuracy(seq, cfg);

if parentID == 0
    variantStore.functionalDepth(newID,1) = 0;
    variantStore.structuralDepth(newID,1) = 0;
else
    parentFunctionalDepth = variantStore.functionalDepth(parentID);
    parentStructuralDepth = variantStore.structuralDepth(parentID);
    parentQ = variantStore.quality(parentID);
    parentM = variantStore.componentAccuracy(parentID);
    childM = variantStore.componentAccuracy(newID);

    if quality > parentQ + cfg.improvementEps
        variantStore.functionalDepth(newID,1) = parentFunctionalDepth + 1;
    else
        variantStore.functionalDepth(newID,1) = parentFunctionalDepth;
    end

    if childM > parentM + cfg.improvementEps
        variantStore.structuralDepth(newID,1) = parentStructuralDepth + 1;
    else
        variantStore.structuralDepth(newID,1) = parentStructuralDepth;
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
    case {'opaque','opaque_mixed'}
        q = (1 - params.opaqueMix) * m + ...
            params.opaqueMix * (m ^ params.opaquePower);
    case 'strict_sequence'
        q = prefixFraction ^ params.strictPower;
    case 'sequence_mixed'
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

function accept = acceptCandidate(qCurrent, qCandidate, params)
% Always consume one uniform variate so matched controls remain aligned.
u = rand;
delta = qCandidate - qCurrent;

switch lower(params.acceptanceRule)
    case 'greedy'
        pAccept = double(delta >= 0);
    case 'softmax'
        if isinf(params.acceptanceBeta)
            if delta > 0
                pAccept = 1;
            elseif delta < 0
                pAccept = 0;
            else
                pAccept = 0.5;
            end
        else
            pAccept = 1 / (1 + exp(-params.acceptanceBeta * delta));
        end
    otherwise
        error('Unknown acceptanceRule: %s', params.acceptanceRule);
end
accept = u < pAccept;
end

function m = componentAccuracy(seq, cfg)
m = mean(seq == cfg.targetSeq);
end

function [componentAcc, prefixFrac, exactTarget] = commonBehaviourMetrics(pop, cfg)
n = size(pop,1);
componentAcc = mean(pop == cfg.targetSeq, 2);
prefixFrac = zeros(n,1);
for i = 1:n
    prefixLength = 0;
    for d = 1:cfg.seqLength
        if pop(i,d) == cfg.targetSeq(d)
            prefixLength = prefixLength + 1;
        else
            break;
        end
    end
    prefixFrac(i) = prefixLength / cfg.seqLength;
end
exactTarget = all(pop == cfg.targetSeq, 2);
end

function trad = computeTraditionStrength(pop)
[~,~,ic] = unique(pop, 'rows');
counts = accumarray(ic,1);
trad = max(counts) / size(pop,1);
end

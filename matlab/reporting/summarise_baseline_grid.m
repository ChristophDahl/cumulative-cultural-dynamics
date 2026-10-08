function summarise_baseline_grid()
%SUMMARISE_BASELINE_GRID Export baseline-grid numerical summaries.
% Summarise the final baseline manuscript-grid simulation.
%
% This function does not rerun the simulation. It loads the baseline-grid
% result file written by run_baseline_grid.m and writes:
%   - results/baseline/baseline_key_metrics.csv
%   - results/baseline/threshold_summary.csv
%   - results/baseline/baseline_conditions.csv
%
% It also prints the key summary and threshold tables to the command window.

clear; clc;

%% Paths
rootDir   = repository_root();
resultDir = fullfile(rootDir, 'results');
outputDir = fullfile(resultDir, 'baseline');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

resultFile = fullfile(outputDir, 'baseline_grid_results.mat');

if ~exist(resultFile, 'file')
    error(['The baseline-grid result file was not found:\n%s\n\n' ...
           'Run run_baseline_grid first.'], ...
           resultFile);
end

S = load(resultFile, 'cfg', 'results');
cfg = S.cfg;
results = S.results;

if isfield(cfg, 'runTag')
    runTag = cfg.runTag;
else
    [~, baseName] = fileparts(resultFile);
    runTag = strrep(baseName, 'cultural_dynamics_', '');
    runTag = strrep(runTag, '_results', '');
end


fprintf('\nLoaded baseline-grid result file:\n%s\n\n', resultFile);
fprintf('Run tag: %s\n', runTag);
fprintf('Tasks: %s\n', strjoin(cfg.taskTypes, ', '));
fprintf('mu values:  %s\n', mat2str(cfg.muGrid));
fprintf('phi values: %s\n', mat2str(cfg.phiGrid));
fprintf('tau values: %s\n\n', mat2str(cfg.tauLevels));

%% Basic dimensions
taskTypes = cfg.taskTypes;
tauLevels = cfg.tauLevels;
muGrid    = cfg.muGrid;
phiGrid   = cfg.phiGrid;

nTask = numel(taskTypes);
nTau  = numel(tauLevels);
nMu   = numel(muGrid);
nPhi  = numel(phiGrid);

%% Key summary table
row = 0;

TaskType = {};
Tau = [];

AsocialMaxFinalMean = [];
AsocialMuAtMaxFinalMean = [];

SocialMaxFinalMean = [];
MuAtMaxFinalMean = [];
PhiAtMaxFinalMean = [];
SocialGainAtMaxFinalMean = [];
LossAtMaxFinalMean = [];
BestFunctionalLineageDepthAtMaxFinalMean = [];

MaxNormalisedSocialGain = [];
MuAtMaxNormalisedSocialGain = [];
PhiAtMaxNormalisedSocialGain = [];

MinLossRate = [];
MuAtMinLossRate = [];
PhiAtMinLossRate = [];

MaxBestFunctionalLineageDepth = [];
MuAtMaxBestFunctionalLineageDepth = [];
PhiAtMaxBestFunctionalLineageDepth = [];

MaxPHigh = [];
MuAtMaxPHigh = [];
PhiAtMaxPHigh = [];

for ik = 1:nTask

    taskType = taskTypes{ik};

    % Asocial baseline is invariant across phi and tau; use first phi/tau slice.
    asocialCurve = squeeze(results.finalMean_asocial(:,1,1,ik));
    [asocialMax, imA] = max(asocialCurve);
    asocialMu = muGrid(imA);

    for it = 1:nTau

        tau = tauLevels(it);
        row = row + 1;

        Zfinal   = squeeze(results.finalMean_social(:,:,it,ik));
        Zgain = squeeze(results.normalisedSocialGain(:,:,it,ik));
        Zloss    = squeeze(results.lossRate_social(:,:,it,ik));
        Zlineage = squeeze(results.bestFunctionalLineageDepth_social(:,:,it,ik));
        ZpHigh   = squeeze(results.pHigh_social(:,:,it,ik));

        [maxFinal, imFinal, ipFinal] = maxWithLocation(Zfinal);
        [maxGain, imGain, ipGain] = maxWithLocation(Zgain);
        [minLoss, imLoss, ipLoss] = minWithLocation(Zloss);
        [maxLineage, imLineage, ipLineage] = maxWithLocation(Zlineage);
        [maxPHighVal, imPHigh, ipPHigh] = maxWithLocation(ZpHigh);

        TaskType{row,1} = taskType;
        Tau(row,1) = tau;

        AsocialMaxFinalMean(row,1) = asocialMax;
        AsocialMuAtMaxFinalMean(row,1) = asocialMu;

        SocialMaxFinalMean(row,1) = maxFinal;
        MuAtMaxFinalMean(row,1) = muGrid(imFinal);
        PhiAtMaxFinalMean(row,1) = phiGrid(ipFinal);
        SocialGainAtMaxFinalMean(row,1) = Zgain(imFinal, ipFinal);
        LossAtMaxFinalMean(row,1) = Zloss(imFinal, ipFinal);
        BestFunctionalLineageDepthAtMaxFinalMean(row,1) = Zlineage(imFinal, ipFinal);

        MaxNormalisedSocialGain(row,1) = maxGain;
        MuAtMaxNormalisedSocialGain(row,1) = muGrid(imGain);
        PhiAtMaxNormalisedSocialGain(row,1) = phiGrid(ipGain);

        MinLossRate(row,1) = minLoss;
        MuAtMinLossRate(row,1) = muGrid(imLoss);
        PhiAtMinLossRate(row,1) = phiGrid(ipLoss);

        MaxBestFunctionalLineageDepth(row,1) = maxLineage;
        MuAtMaxBestFunctionalLineageDepth(row,1) = muGrid(imLineage);
        PhiAtMaxBestFunctionalLineageDepth(row,1) = phiGrid(ipLineage);

        MaxPHigh(row,1) = maxPHighVal;
        MuAtMaxPHigh(row,1) = muGrid(imPHigh);
        PhiAtMaxPHigh(row,1) = phiGrid(ipPHigh);
    end
end

summaryTable = table( ...
    TaskType, Tau, ...
    AsocialMaxFinalMean, AsocialMuAtMaxFinalMean, ...
    SocialMaxFinalMean, MuAtMaxFinalMean, PhiAtMaxFinalMean, ...
    SocialGainAtMaxFinalMean, LossAtMaxFinalMean, BestFunctionalLineageDepthAtMaxFinalMean, ...
    MaxNormalisedSocialGain, MuAtMaxNormalisedSocialGain, PhiAtMaxNormalisedSocialGain, ...
    MinLossRate, MuAtMinLossRate, PhiAtMinLossRate, ...
    MaxBestFunctionalLineageDepth, MuAtMaxBestFunctionalLineageDepth, PhiAtMaxBestFunctionalLineageDepth, ...
    MaxPHigh, MuAtMaxPHigh, PhiAtMaxPHigh);

%% Threshold table
thresholds = [0.25 0.50 0.80 0.95];

row = 0;
TaskType_thr = {};
Tau_thr = [];
Threshold = [];
Reached = [];
MinPhiForThreshold = [];
MinMuForThreshold = [];
MaxValueAtThresholdSearch = [];

for ik = 1:nTask
    taskType = taskTypes{ik};
    for it = 1:nTau
        tau = tauLevels(it);
        Zfinal = squeeze(results.finalMean_social(:,:,it,ik));
        for th = thresholds
            row = row + 1;
            mask = Zfinal >= th;

            TaskType_thr{row,1} = taskType;
            Tau_thr(row,1) = tau;
            Threshold(row,1) = th;
            MaxValueAtThresholdSearch(row,1) = max(Zfinal(:));

            if any(mask(:))
                [muIdx, phiIdx] = find(mask);
                minPhi = min(phiGrid(phiIdx));
                usePhi = phiGrid(phiIdx) == minPhi;
                minMu = min(muGrid(muIdx(usePhi)));

                Reached(row,1) = true;
                MinPhiForThreshold(row,1) = minPhi;
                MinMuForThreshold(row,1) = minMu;
            else
                Reached(row,1) = false;
                MinPhiForThreshold(row,1) = NaN;
                MinMuForThreshold(row,1) = NaN;
            end
        end
    end
end

thresholdTable = table( ...
    TaskType_thr, Tau_thr, Threshold, Reached, ...
    MinPhiForThreshold, MinMuForThreshold, MaxValueAtThresholdSearch);

%% Long table
nRows = nTask * nTau * nMu * nPhi;

taskCol = cell(nRows,1);
tauCol  = nan(nRows,1);
muCol   = nan(nRows,1);
phiCol  = nan(nRows,1);

finalMean_social  = nan(nRows,1);
finalMean_asocial = nan(nRows,1);
normalisedSocialGain      = nan(nRows,1);
lossRate_social   = nan(nRows,1);
tradition_social  = nan(nRows,1);
bestFunctionalLineageDepth_social = nan(nRows,1);
pHigh_social      = nan(nRows,1);

row = 0;
for ik = 1:nTask
    for it = 1:nTau
        for im = 1:nMu
            for ip = 1:nPhi
                row = row + 1;
                taskCol{row,1} = taskTypes{ik};
                tauCol(row,1) = tauLevels(it);
                muCol(row,1) = muGrid(im);
                phiCol(row,1) = phiGrid(ip);
                finalMean_social(row,1) = results.finalMean_social(im,ip,it,ik);
                finalMean_asocial(row,1) = results.finalMean_asocial(im,ip,it,ik);
                normalisedSocialGain(row,1) = results.normalisedSocialGain(im,ip,it,ik);
                lossRate_social(row,1) = results.lossRate_social(im,ip,it,ik);
                tradition_social(row,1) = results.tradition_social(im,ip,it,ik);
                bestFunctionalLineageDepth_social(row,1) = results.bestFunctionalLineageDepth_social(im,ip,it,ik);
                pHigh_social(row,1) = results.pHigh_social(im,ip,it,ik);
            end
        end
    end
end

longTable = table(taskCol, tauCol, muCol, phiCol, ...
    finalMean_social, finalMean_asocial, normalisedSocialGain, ...
    lossRate_social, tradition_social, bestFunctionalLineageDepth_social, pHigh_social, ...
    'VariableNames', {'TaskType','Tau','Mu','Phi', ...
    'FinalMeanSocial','FinalMeanAsocial','NormalisedSocialGain', ...
    'LossRateSocial','TraditionSocial','BestFunctionalLineageDepthSocial','PHighSocial'});

%% Export
summaryCsv   = fullfile(outputDir, 'baseline_key_metrics.csv');
thresholdCsv = fullfile(outputDir, 'threshold_summary.csv');
longCsv      = fullfile(outputDir, 'baseline_conditions.csv');

writetable(summaryTable, summaryCsv);
writetable(thresholdTable, thresholdCsv);
writetable(longTable, longCsv);

fprintf('Wrote:\n%s\n', summaryCsv);
fprintf('Wrote:\n%s\n', thresholdCsv);
fprintf('Wrote:\n%s\n\n', longCsv);

disp('Key summary table:');
disp(summaryTable);

disp('Threshold table:');
disp(thresholdTable);

%% Helpers
end

function [val, rowIdx, colIdx] = maxWithLocation(Z)
valid = ~isnan(Z);
if ~any(valid(:))
    val = NaN; rowIdx = NaN; colIdx = NaN; return;
end
linearValid = find(valid);
vals = Z(valid);
[localVal, localIdx] = max(vals);
linearIdx = linearValid(localIdx);
[rowIdx, colIdx] = ind2sub(size(Z), linearIdx);
val = localVal;
end

function [val, rowIdx, colIdx] = minWithLocation(Z)
valid = ~isnan(Z);
if ~any(valid(:))
    val = NaN; rowIdx = NaN; colIdx = NaN; return;
end
linearValid = find(valid);
vals = Z(valid);
[localVal, localIdx] = min(vals);
linearIdx = linearValid(localIdx);
[rowIdx, colIdx] = ind2sub(size(Z), linearIdx);
val = localVal;
end

function summarise_extended_analyses()
%SUMMARISE_EXTENDED_ANALYSES Export reviewer-readable CSV summaries.
%
% Files are written directly into the result-family folders:
%
%   results/mechanism_controls/
%       mechanism_controls_full_grid.csv
%       mechanism_controls_representative.csv
%
%   results/discrimination_sensitivity/
%       beta_sensitivity.csv
%       gamma_sensitivity.csv
%
%   results/graded_task_landscapes/
%       opacity_results.csv
%       sequence_dependence_results.csv
%       common_scale_validation.csv
%       lineage_depth_results.csv
%
% All tables are generated from the saved .mat result files. No values are
% entered manually.

cfg = extended_analysis_config();

mechanismDir = fullfile(cfg.resultDir,'mechanism_controls');
discriminationDir = fullfile(cfg.resultDir,'discrimination_sensitivity');
landscapeDir = fullfile(cfg.resultDir,'graded_task_landscapes');

ensureDir(mechanismDir);
ensureDir(discriminationDir);
ensureDir(landscapeDir);

summarizeMechanism(cfg,mechanismDir);
summarizeDiscrimination(cfg,discriminationDir);
summarizeTaskSensitivity(cfg,landscapeDir);

fprintf('\nExtended-analysis CSV summaries written to the family folders under:\n%s\n',cfg.resultDir);
end

% =========================================================================
% Mechanism controls
% =========================================================================
function summarizeMechanism(cfg,outDir)
file = fullfile(outDir,'mechanism_controls_results.mat');
if ~exist(file,'file')
    warning('Mechanism file not found: %s',file);
    return;
end

R = load(file);
S = R.social;
controls = R.controlNames;

metrics = {'finalMean','lossRate','bestFunctionalLineageDepth', ...
    'bestStructuralLineageDepth','finalMeanComponentAccuracy', ...
    'finalExactTargetFraction'};

rows = {};
r = 0;
for ik = 1:numel(cfg.taskTypes)
    for it = 1:numel(cfg.tauLevels)
        for im = 1:numel(cfg.muGrid)
            for ip = 1:numel(cfg.phiGrid)
                for ic = 1:numel(controls)
                    for mm = 1:numel(metrics)
                        metric = metrics{mm};
                        x = squeeze(S.(metric)(:,im,ip,it,ik,ic));
                        [m,se,lo,hi,n] = stats95(x);

                        dMean = NaN; dSE = NaN; dLo = NaN; dHi = NaN; dN = NaN;
                        if ic ~= 1
                            b = squeeze(S.(metric)(:,im,ip,it,ik,1));
                            [dMean,dSE,dLo,dHi,dN] = stats95(x-b);
                        end

                        r = r + 1;
                        rows(r,:) = {cfg.taskTypes{ik},cfg.tauLevels(it),cfg.muGrid(im), ...
                            cfg.phiGrid(ip),controls{ic},metric,n,m,se,lo,hi, ...
                            dN,dMean,dSE,dLo,dHi}; %#ok<AGROW>
                    end
                end
            end
        end
    end
end

T = cell2table(rows,'VariableNames',{'Task','Tau','Mu','Phi','Control','Metric', ...
    'N','Mean','SE','CI_Low','CI_High','DeltaN','DeltaVsBaseline','DeltaSE', ...
    'DeltaCI_Low','DeltaCI_High'});

writetable(T,fullfile(outDir,'mechanism_controls_full_grid.csv'));

[~,im] = min(abs(cfg.muGrid-cfg.representativeMu));
[~,ip] = min(abs(cfg.phiGrid-cfg.representativePhi));
Trep = T(abs(T.Mu-cfg.muGrid(im))<1e-12 & abs(T.Phi-cfg.phiGrid(ip))<1e-12,:);
writetable(Trep,fullfile(outDir,'mechanism_controls_representative.csv'));
end

% =========================================================================
% Discrimination sensitivity: beta and gamma are deliberately separate.
% =========================================================================
function summarizeDiscrimination(cfg,outDir)
file = fullfile(outDir,'discrimination_sensitivity_results.mat');
if ~exist(file,'file')
    warning('Discrimination file not found: %s',file);
    return;
end

R = load(file);
metrics = {'finalMean','lossRate','bestFunctionalLineageDepth', ...
    'bestStructuralLineageDepth','finalMeanComponentAccuracy', ...
    'finalExactTargetFraction'};

Tbeta = sensitivityTable(R.betaSweep,R.betaGrid,'beta',cfg,metrics);
Tgamma = sensitivityTable(R.gammaSweep,R.gammaGrid,'gamma',cfg,metrics);

writetable(Tbeta,fullfile(outDir,'beta_sensitivity.csv'));
writetable(Tgamma,fullfile(outDir,'gamma_sensitivity.csv'));
end

function T = sensitivityTable(S,levels,parameterName,cfg,metrics)
rows = {};
r = 0;
for ik = 1:numel(cfg.taskTypes)
    for it = 1:numel(cfg.tauLevels)
        for il = 1:numel(levels)
            for mm = 1:numel(metrics)
                metric = metrics{mm};
                x = squeeze(S.(metric)(:,it,ik,il));
                [m,se,lo,hi,n] = stats95(x);
                r = r + 1;
                rows(r,:) = {parameterName,levels(il),cfg.taskTypes{ik}, ...
                    cfg.tauLevels(it),cfg.representativeMu,cfg.representativePhi, ...
                    metric,n,m,se,lo,hi}; %#ok<AGROW>
            end
        end
    end
end

T = cell2table(rows,'VariableNames',{'Parameter','Level','Task','Tau','Mu','Phi', ...
    'Metric','N','Mean','SE','CI_Low','CI_High'});
end

% =========================================================================
% Graded task landscapes
% =========================================================================
function summarizeTaskSensitivity(cfg,outDir)
file = fullfile(outDir,'graded_task_landscapes_results.mat');
if ~exist(file,'file')
    warning('Graded-task file not found: %s',file);
    return;
end

R = load(file);
S = R.social;

% Primary task-specific outcomes. These are split by landscape family so a
% reader can inspect each manipulation directly.
primaryMetrics = {'finalMean','lossRate'};
Topacity = gradedTable(S,R,1,cfg,primaryMetrics);
Tsequence = gradedTable(S,R,2,cfg,primaryMetrics);
writetable(Topacity,fullfile(outDir,'opacity_results.csv'));
writetable(Tsequence,fullfile(outDir,'sequence_dependence_results.csv'));

% Severity-independent behavioural diagnostics used to establish that the
% endpoint decline is not only a consequence of changing payoff functions.
commonScaleMetrics = {'finalMeanComponentAccuracy','finalMaxComponentAccuracy', ...
    'finalExactTargetFraction','finalAnyExactTarget','everAnyExactTarget', ...
    'firstExactTargetGeneration','finalMeanPrefixFraction','finalMaxPrefixFraction'};
Tcommon = gradedTable(S,R,[],cfg,commonScaleMetrics);
writetable(Tcommon,fullfile(outDir,'common_scale_validation.csv'));

% Functional and structural cultural ancestry.
lineageMetrics = {'bestFunctionalLineageDepth','bestStructuralLineageDepth'};
Tlineage = gradedTable(S,R,[],cfg,lineageMetrics);
writetable(Tlineage,fullfile(outDir,'lineage_depth_results.csv'));
end

function T = gradedTable(S,R,familySelection,cfg,metrics)
if isempty(familySelection)
    families = 1:numel(R.familyNames);
else
    families = familySelection;
end

rows = {};
r = 0;
for iff = families
    levels = R.severityValues{iff};
    for isev = 1:numel(levels)
        for it = 1:numel(cfg.tauLevels)
            for im = 1:numel(cfg.muGrid)
                for ip = 1:numel(cfg.phiGrid)
                    for mm = 1:numel(metrics)
                        metric = metrics{mm};
                        x = squeeze(S.(metric)(:,im,ip,it,isev,iff));
                        [m,se,lo,hi,n] = stats95(x);
                        r = r + 1;
                        rows(r,:) = {R.familyNames{iff},levels(isev),cfg.tauLevels(it), ...
                            cfg.muGrid(im),cfg.phiGrid(ip),metric,n,m,se,lo,hi}; %#ok<AGROW>
                    end
                end
            end
        end
    end
end

T = cell2table(rows,'VariableNames',{'Family','Severity','Tau','Mu','Phi', ...
    'Metric','N','Mean','SE','CI_Low','CI_High'});
end

% =========================================================================
% Helpers
% =========================================================================
function ensureDir(d)
if ~exist(d,'dir'), mkdir(d); end
end

function [m,se,lo,hi,n] = stats95(x)
x = x(isfinite(x));
n = numel(x);
if n == 0
    m = NaN; se = NaN; lo = NaN; hi = NaN;
    return;
end
m = mean(x);
if n > 1
    se = std(x,0)/sqrt(n);
else
    se = NaN;
end
lo = m - 1.96*se;
hi = m + 1.96*se;
end

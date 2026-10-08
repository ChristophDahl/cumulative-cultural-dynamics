function make_baseline_figures()
% Generate the baseline manuscript figures.
%
% Publication style:
%   - outward ticks
%   - square plotting axes
%   - clean Times New Roman typography
%   - separate colourbar for heatmaps, so all panels remain the same size
%   - TeX interpreter for Greek symbols while retaining journal-style font
%   - vector PDF output plus 600-dpi PNG and editable MATLAB FIG
%   - Figure 1 exported as a single multi-panel composite:
%         A   asocial discovery baseline
%         B-G social final-mean-quality heatmaps (3 tasks x 2 tau levels)
%
% Compatible plotting version: does not use ColorBar.Layout.Tile.

clearvars -except ans; clc;

rootDir   = repository_root();
resultDir = fullfile(rootDir, 'results');
figureDir = fullfile(rootDir, 'figures');

resultFile = fullfile(resultDir, 'baseline', 'baseline_grid_results.mat');

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
    runTag = 'baseline_grid';
end

paperDir = fullfile(figureDir, 'manuscript');
if ~exist(paperDir, 'dir')
    mkdir(paperDir);
end

% -------------------------------------------------------------------------
% Shared publication style
% -------------------------------------------------------------------------
STYLE = publicationStyle();

fprintf('Loaded result file:\n%s\n', resultFile);
fprintf('Exporting baseline manuscript figures to:\n%s\n\n', paperDir);

% Main composite figure.
% Figure 1 is unchanged.
plotFigure1MultiPanel(cfg, results, paperDir, STYLE);

% Figure 2: preservation and cumulative ancestry.
% A-F = loss rate; G-L = best-solution lineage depth.
plotFigure2LossLineage(cfg, results, paperDir, STYLE);

% Supplementary Figure S1: normalised social gain.
plotFigureS1SocialGain(cfg, results, paperDir, STYLE);

fprintf('Finished plotting baseline figures.\n');
end


% =========================================================================
% FIGURE 1 COMPOSITE
% =========================================================================
function plotFigure1MultiPanel(cfg, results, paperDir, STYLE)

muGrid    = cfg.muGrid;
phiGrid   = cfg.phiGrid;
tauLevels = cfg.tauLevels;
taskTypes = cfg.taskTypes;

nTask = numel(taskTypes);
nTau  = numel(tauLevels);

M = results.finalMean_social;

zMin = min(M(:));
zMax = max(M(:));
if ~isfinite(zMin) || ~isfinite(zMax) || zMin == zMax
    zMin = 0;
    zMax = 1;
end

% Large canvas: one left panel + 2x3 heatmap block + independent colourbar.
fig = figure( ...
    'Color', 'w', ...
    'Position', [60 60 900 500], ...
    'Renderer', 'painters', ...
    'InvertHardcopy', 'off');

cmap = parula(256);
colormap(fig, cmap);

% Layout geometry
leftMargin   = 0.055;
rightMargin  = 0.965;
bottomMargin = 0.105;
topMargin    = 0.865;

% Left panel: asocial baseline
axA = axes('Parent', fig, 'Position', [0.065 0.30 0.215 0.40]);
hold(axA, 'on');

for ik = 1:nTask
    y = squeeze(results.finalMean_asocial(:,1,1,ik));
    plot(axA, muGrid, y, '-o', ...
        'LineWidth', STYLE.LineWidth, ...
        'MarkerSize', STYLE.MarkerSize);
end

xlabel(axA, 'Innovation probability, \mu', ...
    'Interpreter', STYLE.Interpreter, ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.LabelFontSize);

ylabel(axA, 'Final mean quality, asocial', ...
    'Interpreter', STYLE.Interpreter, ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.LabelFontSize);

title(axA, 'Asocial search baseline', ...
    'Interpreter', STYLE.Interpreter, ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.PanelTitleFontSize, ...
    'FontWeight', 'normal');

lgd = legend(axA, cleanTaskNames(taskTypes), ...
    'Location', 'east', ...
    'Box', 'off', ...
    'Interpreter', 'none');
set(lgd, 'FontName', STYLE.FontName, 'FontSize', STYLE.LegendFontSize);

applyPublicationStyle(axA, STYLE);
axis(axA, 'square');
addPanelLabel(axA, 'A', STYLE);

% Right block: 2x3 heatmaps (B-G)
blockLeft   = 0.365;
blockRight  = 0.860;
blockBottom = 0.145;
blockTop    = 0.820;
gapX = 0.045;
gapY = 0.115;

panelW = (blockRight - blockLeft - (nTask - 1)*gapX) / nTask;
panelH = (blockTop - blockBottom - (nTau  - 1)*gapY) / nTau;

panelLetters = {'B','C','D','E','F','G'};
panelCounter = 0;

for it = 1:nTau
    for ik = 1:nTask

        panelCounter = panelCounter + 1;

        x0 = blockLeft + (ik - 1)*(panelW + gapX);
        y0 = blockTop - it*panelH - (it - 1)*gapY;

        ax = axes('Parent', fig, 'Position', [x0 y0 panelW panelH]);

        Z = squeeze(M(:,:,it,ik));
        imagesc(ax, 1:numel(phiGrid), 1:numel(muGrid), Z);
        set(ax, 'YDir', 'normal');
        caxis(ax, [zMin zMax]);
        colormap(ax, cmap);

        set(ax, ...
            'XTick', 1:numel(phiGrid), ...
            'XTickLabel', formatTickLabels(phiGrid), ...
            'YTick', 1:numel(muGrid), ...
            'YTickLabel', formatTickLabels(muGrid));

        title(ax, sprintf('%s, \\tau = %.2f', ...
            cleanTaskName(taskTypes{ik}), tauLevels(it)), ...
            'Interpreter', STYLE.Interpreter, ...
            'FontName', STYLE.FontName, ...
            'FontSize', STYLE.PanelTitleFontSize, ...
            'FontWeight', 'normal');

        if it == nTau
            xlabel(ax, 'Copying fidelity, \phi', ...
                'Interpreter', STYLE.Interpreter, ...
                'FontName', STYLE.FontName, ...
                'FontSize', STYLE.LabelFontSize);
        end

        if ik == 1
            ylabel(ax, 'Innovation probability, \mu', ...
                'Interpreter', STYLE.Interpreter, ...
                'FontName', STYLE.FontName, ...
                'FontSize', STYLE.LabelFontSize);
        end

        applyPublicationStyle(ax, STYLE);
        axis(ax, 'square');
        addPanelLabel(ax, panelLetters{panelCounter}, STYLE);
    end
end

% Independent colourbar (no shrinking of any heatmap panel).
cax = axes( ...
    'Parent', fig, ...
    'Position', [0.890 0.24 0.001 0.47], ...
    'Visible', 'off', ...
    'CLim', [zMin zMax]);

colormap(cax, cmap);
caxis(cax, [zMin zMax]);

cb = colorbar(cax, 'eastoutside');
set(cb, ...
    'Position', [0.905 0.24 0.016 0.47], ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.TickFontSize, ...
    'TickDirection', 'out', ...
    'LineWidth', STYLE.AxesLineWidth, ...
    'Box', 'off');

ylabel(cb, 'Final mean quality, social', ...
    'Interpreter', STYLE.Interpreter, ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.LabelFontSize);

% sgtitle(fig, 'Figure 1. Discovery and social accumulation', ...
%     'Interpreter', STYLE.Interpreter, ...
%     'FontName', STYLE.FontName, ...
%     'FontSize', STYLE.SuperTitleFontSize, ...
%     'FontWeight', 'normal');

exportFigure(fig, paperDir, 'Fig_1', STYLE);
close(fig);
end


% =========================================================================
% FIGURE 2 COMPOSITE
% A-F: social loss rate
% G-L: best-solution lineage depth
% =========================================================================
function plotFigure2LossLineage(cfg, results, paperDir, STYLE)

muGrid    = cfg.muGrid;
phiGrid   = cfg.phiGrid;
tauLevels = cfg.tauLevels;
taskTypes = cfg.taskTypes;

nTask = numel(taskTypes);
nTau  = numel(tauLevels);

Mloss = results.lossRate_social;
Mline = results.bestFunctionalLineageDepth_social;

% Separate shared colour scales for the two metrics.
lossMin = min(Mloss(:));
lossMax = max(Mloss(:));
if ~isfinite(lossMin) || ~isfinite(lossMax) || lossMin == lossMax
    lossMin = 0;
    lossMax = 1;
end

lineMin = min(Mline(:));
lineMax = max(Mline(:));
if ~isfinite(lineMin) || ~isfinite(lineMax) || lineMin == lineMax
    lineMin = 0;
    lineMax = 1;
end

fig = figure( ...
    'Color', 'w', ...
    'Position', [60 40 750 900], ...
    'Renderer', 'painters', ...
    'InvertHardcopy', 'off');

cmap = parula(256);
colormap(fig, cmap);

% -------------------------------------------------------------------------
% Manual geometry.
% Two 2 x 3 blocks share the same panel geometry.
% A dedicated strip on the right is reserved for the two colourbars, so no
% data panel is resized by a colourbar.
% -------------------------------------------------------------------------
blockLeft  = 0.090;
blockRight = 0.845;

gapX       = 0.045;
gapY       = 0.050;

upperTop    = 0.905;
upperBottom = 0.545;

lowerTop    = 0.445;
lowerBottom = 0.085;

panelW = (blockRight - blockLeft - (nTask - 1)*gapX) / nTask;
panelH1 = (upperTop - upperBottom - (nTau - 1)*gapY) / nTau;
panelH2 = (lowerTop - lowerBottom - (nTau - 1)*gapY) / nTau;
panelH = min(panelH1, panelH2);

panelLetters = {'A','B','C','D','E','F', ...
                'G','H','I','J','K','L'};
panelCounter = 0;

% -----------------------------
% A-F: loss rate
% -----------------------------
for it = 1:nTau
    for ik = 1:nTask

        panelCounter = panelCounter + 1;

        x0 = blockLeft + (ik - 1)*(panelW + gapX);
        y0 = upperTop - it*panelH - (it - 1)*gapY;

        ax = axes('Parent', fig, 'Position', [x0 y0 panelW panelH]);

        Z = squeeze(Mloss(:,:,it,ik));
        imagesc(ax, 1:numel(phiGrid), 1:numel(muGrid), Z);
        set(ax, 'YDir', 'normal');
        caxis(ax, [lossMin lossMax]);
        colormap(ax, cmap);

        set(ax, ...
            'XTick', 1:numel(phiGrid), ...
            'XTickLabel', formatTickLabels(phiGrid), ...
            'YTick', 1:numel(muGrid), ...
            'YTickLabel', formatTickLabels(muGrid));

        title(ax, sprintf('%s, \\tau = %.2f', ...
            cleanTaskName(taskTypes{ik}), tauLevels(it)), ...
            'Interpreter', STYLE.Interpreter, ...
            'FontName', STYLE.FontName, ...
            'FontSize', STYLE.PanelTitleFontSize, ...
            'FontWeight', 'normal');

        if it == nTau
            xlabel(ax, 'Copying fidelity, \phi', ...
                'Interpreter', STYLE.Interpreter, ...
                'FontName', STYLE.FontName, ...
                'FontSize', STYLE.LabelFontSize);
        end

        if ik == 1
            ylabel(ax, 'Innovation probability, \mu', ...
                'Interpreter', STYLE.Interpreter, ...
                'FontName', STYLE.FontName, ...
                'FontSize', STYLE.LabelFontSize);
        end

        applyPublicationStyle(ax, STYLE);
        axis(ax, 'square');
        addPanelLabel(ax, panelLetters{panelCounter}, STYLE);
    end
end

% -----------------------------
% G-L: lineage depth
% -----------------------------
for it = 1:nTau
    for ik = 1:nTask

        panelCounter = panelCounter + 1;

        x0 = blockLeft + (ik - 1)*(panelW + gapX);
        y0 = lowerTop - it*panelH - (it - 1)*gapY;

        ax = axes('Parent', fig, 'Position', [x0 y0 panelW panelH]);

        Z = squeeze(Mline(:,:,it,ik));
        imagesc(ax, 1:numel(phiGrid), 1:numel(muGrid), Z);
        set(ax, 'YDir', 'normal');
        caxis(ax, [lineMin lineMax]);
        colormap(ax, cmap);

        set(ax, ...
            'XTick', 1:numel(phiGrid), ...
            'XTickLabel', formatTickLabels(phiGrid), ...
            'YTick', 1:numel(muGrid), ...
            'YTickLabel', formatTickLabels(muGrid));

        title(ax, sprintf('%s, \\tau = %.2f', ...
            cleanTaskName(taskTypes{ik}), tauLevels(it)), ...
            'Interpreter', STYLE.Interpreter, ...
            'FontName', STYLE.FontName, ...
            'FontSize', STYLE.PanelTitleFontSize, ...
            'FontWeight', 'normal');

        if it == nTau
            xlabel(ax, 'Copying fidelity, \phi', ...
                'Interpreter', STYLE.Interpreter, ...
                'FontName', STYLE.FontName, ...
                'FontSize', STYLE.LabelFontSize);
        end

        if ik == 1
            ylabel(ax, 'Innovation probability, \mu', ...
                'Interpreter', STYLE.Interpreter, ...
                'FontName', STYLE.FontName, ...
                'FontSize', STYLE.LabelFontSize);
        end

        applyPublicationStyle(ax, STYLE);
        axis(ax, 'square');
        addPanelLabel(ax, panelLetters{panelCounter}, STYLE);
    end
end

% -------------------------------------------------------------------------
% Independent colourbar for loss rate.
% -------------------------------------------------------------------------
caxLoss = axes( ...
    'Parent', fig, ...
    'Position', [0.875 0.605 0.001 0.235], ...
    'Visible', 'off', ...
    'CLim', [lossMin lossMax]);

colormap(caxLoss, cmap);
caxis(caxLoss, [lossMin lossMax]);

cbLoss = colorbar(caxLoss, 'eastoutside');
set(cbLoss, ...
    'Position', [0.895 0.605 0.016 0.235], ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.TickFontSize, ...
    'TickDirection', 'out', ...
    'LineWidth', STYLE.AxesLineWidth, ...
    'Box', 'off');

ylabel(cbLoss, 'Loss rate, social', ...
    'Interpreter', STYLE.Interpreter, ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.LabelFontSize);

% -------------------------------------------------------------------------
% Independent colourbar for lineage depth.
% -------------------------------------------------------------------------
caxLine = axes( ...
    'Parent', fig, ...
    'Position', [0.875 0.145 0.001 0.235], ...
    'Visible', 'off', ...
    'CLim', [lineMin lineMax]);

colormap(caxLine, cmap);
caxis(caxLine, [lineMin lineMax]);

cbLine = colorbar(caxLine, 'eastoutside');
set(cbLine, ...
    'Position', [0.895 0.145 0.016 0.235], ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.TickFontSize, ...
    'TickDirection', 'out', ...
    'LineWidth', STYLE.AxesLineWidth, ...
    'Box', 'off');

ylabel(cbLine, 'Functional lineage depth, D_{q}', ...
    'Interpreter', STYLE.Interpreter, ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.LabelFontSize);

% Block labels. These describe the two metrics without adding a global title.
annotation(fig, 'textbox', [0.090 0.93 0.20 0.025], ...
    'String', 'Loss rate', ...
    'EdgeColor', 'none', ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.PanelTitleFontSize, ...
    'FontWeight', 'normal', ...
    'HorizontalAlignment', 'left');

annotation(fig, 'textbox', [0.090 0.47 0.30 0.025], ...
    'String', 'Best-solution functional lineage depth', ...
    'EdgeColor', 'none', ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.PanelTitleFontSize, ...
    'FontWeight', 'normal', ...
    'HorizontalAlignment', 'left', ...
    'FitBoxToText', 'on');

exportFigure(fig, paperDir, 'Fig_2', STYLE);
close(fig);
end


% =========================================================================
% SUPPLEMENTARY FIGURE S1: NORMALISED SOCIAL GAIN
% =========================================================================
function plotFigureS1SocialGain(cfg, results, paperDir, STYLE)

muGrid    = cfg.muGrid;
phiGrid   = cfg.phiGrid;
tauLevels = cfg.tauLevels;
taskTypes = cfg.taskTypes;

nTask = numel(taskTypes);
nTau  = numel(tauLevels);

% Historical field name retained in the saved results.
M = results.normalisedSocialGain;

% One shared colour scale for all six panels.
zMin = min(M(:));
zMax = max(M(:));
if ~isfinite(zMin) || ~isfinite(zMax) || zMin == zMax
    zMin = 0;
    zMax = 1;
end

fig = figure( ...
    'Color', 'w', ...
    'Position', [60 60 750 500], ...
    'Renderer', 'painters', ...
    'InvertHardcopy', 'off');

cmap = parula(256);
colormap(fig, cmap);

% -------------------------------------------------------------------------
% 2 x 3 square heatmap layout.
% A separate strip on the right is reserved for the colourbar so that all
% six panels remain exactly the same size.
% -------------------------------------------------------------------------
blockLeft   = 0.090;
blockRight  = 0.845;
blockBottom = 0.125;
blockTop    = 0.875;

gapX = 0.045;
gapY = 0.105;

panelW = (blockRight - blockLeft - (nTask - 1)*gapX) / nTask;
panelH = (blockTop - blockBottom - (nTau - 1)*gapY) / nTau;

panelLetters = {'A','B','C','D','E','F'};
panelCounter = 0;

for it = 1:nTau
    for ik = 1:nTask

        panelCounter = panelCounter + 1;

        x0 = blockLeft + (ik - 1)*(panelW + gapX);
        y0 = blockTop - it*panelH - (it - 1)*gapY;

        ax = axes('Parent', fig, 'Position', [x0 y0 panelW panelH]);

        Z = squeeze(M(:,:,it,ik));
        imagesc(ax, 1:numel(phiGrid), 1:numel(muGrid), Z);
        set(ax, 'YDir', 'normal');
        caxis(ax, [zMin zMax]);
        colormap(ax, cmap);

        set(ax, ...
            'XTick', 1:numel(phiGrid), ...
            'XTickLabel', formatTickLabels(phiGrid), ...
            'YTick', 1:numel(muGrid), ...
            'YTickLabel', formatTickLabels(muGrid));

        title(ax, sprintf('%s, \\tau = %.2f', ...
            cleanTaskName(taskTypes{ik}), tauLevels(it)), ...
            'Interpreter', STYLE.Interpreter, ...
            'FontName', STYLE.FontName, ...
            'FontSize', STYLE.PanelTitleFontSize, ...
            'FontWeight', 'normal');

        if it == nTau
            xlabel(ax, 'Copying fidelity, \phi', ...
                'Interpreter', STYLE.Interpreter, ...
                'FontName', STYLE.FontName, ...
                'FontSize', STYLE.LabelFontSize);
        end

        if ik == 1
            ylabel(ax, 'Innovation probability, \mu', ...
                'Interpreter', STYLE.Interpreter, ...
                'FontName', STYLE.FontName, ...
                'FontSize', STYLE.LabelFontSize);
        end

        applyPublicationStyle(ax, STYLE);
        axis(ax, 'square');
        addPanelLabel(ax, panelLetters{panelCounter}, STYLE);
    end
end

% Independent colourbar: does not resize any panel.
cax = axes( ...
    'Parent', fig, ...
    'Position', [0.875 0.255 0.001 0.46], ...
    'Visible', 'off', ...
    'CLim', [zMin zMax]);

colormap(cax, cmap);
caxis(cax, [zMin zMax]);

cb = colorbar(cax, 'eastoutside');
set(cb, ...
    'Position', [0.895 0.255 0.016 0.46], ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.TickFontSize, ...
    'TickDirection', 'out', ...
    'LineWidth', STYLE.AxesLineWidth, ...
    'Box', 'off');

ylabel(cb, 'Normalised social gain', ...
    'Interpreter', STYLE.Interpreter, ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.LabelFontSize);

% No overall title, matching the main figures.
exportFigure(fig, paperDir, 'Fig_S1', STYLE);
close(fig);
end


% =========================================================================
% COMBINED HEATMAP
% =========================================================================
function plotCombinedHeatmap(cfg, results, metricName, metricTitle, ...
    paperDir, fileStem, STYLE)

muGrid = cfg.muGrid;
phiGrid = cfg.phiGrid;
tauLevels = cfg.tauLevels;
taskTypes = cfg.taskTypes;

nTask = numel(taskTypes);
nTau = numel(tauLevels);

M = results.(metricName);

% One shared colour scale per metric figure.
zMin = min(M(:));
zMax = max(M(:));
if ~isfinite(zMin) || ~isfinite(zMax) || zMin == zMax
    zMin = 0;
    zMax = 1;
end

% Slightly wider canvas leaves a dedicated strip for the colourbar.
figW = max(1040, 295*nTask + 170);
figH = max(650, 290*nTau + 110);

fig = figure( ...
    'Color', 'w', ...
    'Position', [100 80 figW figH], ...
    'Renderer', 'painters', ...
    'InvertHardcopy', 'off');

% Use a restrained standard sequential map. This is shared by all panels
% and by the independent colourbar axis.
cmap = parula(256);
colormap(fig, cmap);

% -------------------------------------------------------------------------
% Manual grid geometry
% -------------------------------------------------------------------------
leftEdge   = 0.085;
rightEdge  = 0.855;
bottomEdge = 0.105;
topEdge    = 0.845;

gapX = 0.040;
gapY = 0.105;

panelW = (rightEdge - leftEdge - (nTask - 1)*gapX) / nTask;
panelH = (topEdge - bottomEdge - (nTau  - 1)*gapY) / nTau;

plotIdx = 0;

for it = 1:nTau
    for ik = 1:nTask

        plotIdx = plotIdx + 1;

        x0 = leftEdge + (ik - 1)*(panelW + gapX);
        y0 = topEdge - it*panelH - (it - 1)*gapY;

        ax = axes( ...
            'Parent', fig, ...
            'Position', [x0 y0 panelW panelH]);

        Z = squeeze(M(:,:,it,ik));

        imagesc(ax, 1:numel(phiGrid), 1:numel(muGrid), Z);
        set(ax, 'YDir', 'normal');
        caxis(ax, [zMin zMax]);
        colormap(ax, cmap);

        axis(ax, 'square');

        title(ax, ...
            sprintf('%s, \\tau = %.2f', ...
            cleanTaskName(taskTypes{ik}), tauLevels(it)), ...
            'Interpreter', STYLE.Interpreter, ...
            'FontName', STYLE.FontName, ...
            'FontSize', STYLE.PanelTitleFontSize, ...
            'FontWeight', 'normal');

        set(ax, ...
            'XTick', 1:numel(phiGrid), ...
            'XTickLabel', formatTickLabels(phiGrid), ...
            'YTick', 1:numel(muGrid), ...
            'YTickLabel', formatTickLabels(muGrid));

        if it == nTau
            xlabel(ax, 'Copying fidelity, \phi', ...
                'Interpreter', STYLE.Interpreter, ...
                'FontName', STYLE.FontName, ...
                'FontSize', STYLE.LabelFontSize);
        end

        if ik == 1
            ylabel(ax, 'Innovation probability, \mu', ...
                'Interpreter', STYLE.Interpreter, ...
                'FontName', STYLE.FontName, ...
                'FontSize', STYLE.LabelFontSize);
        end

        applyPublicationStyle(ax, STYLE);
    end
end

% Independent colourbar
cax = axes( ...
    'Parent', fig, ...
    'Position', [0.885 0.20 0.001 0.56], ...
    'Visible', 'off', ...
    'CLim', [zMin zMax]);

colormap(cax, cmap);
caxis(cax, [zMin zMax]);

cb = colorbar(cax, 'eastoutside');
set(cb, ...
    'Position', [0.900 0.205 0.018 0.555], ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.TickFontSize, ...
    'TickDirection', 'out', ...
    'LineWidth', STYLE.AxesLineWidth, ...
    'Box', 'off');

ylabel(cb, metricTitle, ...
    'Interpreter', STYLE.Interpreter, ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.LabelFontSize);

sgtitle(metricTitle, ...
    'Interpreter', STYLE.Interpreter, ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.SuperTitleFontSize, ...
    'FontWeight', 'normal');

exportFigure(fig, paperDir, fileStem, STYLE);
close(fig);
end


% =========================================================================
% PUBLICATION STYLE
% =========================================================================
function STYLE = publicationStyle()

STYLE.FontName = 'Times New Roman';

% TeX interpreter gives Greek symbols cleanly while preserving the selected
% font better than MATLAB's full LaTeX interpreter.
STYLE.Interpreter = 'tex';

STYLE.TickFontSize       = 9;
STYLE.LabelFontSize      = 10;
STYLE.LegendFontSize     = 9;
STYLE.PanelTitleFontSize = 11;
STYLE.TitleFontSize      = 10.5;
STYLE.SuperTitleFontSize = 11.5;

STYLE.AxesLineWidth = 0.5;
STYLE.LineWidth     = 1.;
STYLE.MarkerSize    = 3;
STYLE.TickLength    = [0.01 0.01];

STYLE.PNGResolution = 600;
end


function applyPublicationStyle(ax, STYLE)

set(ax, ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.TickFontSize, ...
    'LineWidth', STYLE.AxesLineWidth, ...
    'TickDir', 'out', ...
    'TickLength', STYLE.TickLength, ...
    'Box', 'off', ...
    'Layer', 'top');

grid(ax, 'off');

set(ax, ...
    'XMinorTick', 'off', ...
    'YMinorTick', 'off');
end


function addPanelLabel(ax, labelText, STYLE)

x = -0.18;
y = 1.10;

text(ax, x, y, labelText, ...
    'Units', 'normalized', ...
    'FontName', STYLE.FontName, ...
    'FontSize', STYLE.SuperTitleFontSize, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'Interpreter', 'none');
end


% =========================================================================
% EXPORT
% =========================================================================
function exportFigure(fig, paperDir, fileStem, STYLE)

pngFile = fullfile(paperDir, [fileStem '.png']);
pdfFile = fullfile(paperDir, [fileStem '.pdf']);
figFile = fullfile(paperDir, [fileStem '.fig']);

% Save the editable MATLAB figure.
savefig(fig, figFile);

% Export tightly cropped publication files.
% exportgraphics removes the large page margins introduced by print().
try
    exportgraphics(fig, pngFile, ...
        'Resolution', STYLE.PNGResolution, ...
        'BackgroundColor', 'white');

    exportgraphics(fig, pdfFile, ...
        'ContentType', 'vector', ...
        'BackgroundColor', 'white');
catch ME
    % Fallback for older MATLAB versions without exportgraphics.
    warning('exportgraphics failed (%s). Falling back to print().', ME.message);

    set(fig, 'PaperPositionMode', 'auto');

    % PNG fallback.
    print(fig, pngFile, '-dpng', sprintf('-r%d', STYLE.PNGResolution));

    % PDF fallback.
    try
        print(fig, pdfFile, '-dpdf', '-painters', '-bestfit');
    catch
        print(fig, pdfFile, '-dpdf', '-painters');
    end
end
end


% =========================================================================
% SMALL HELPERS
% =========================================================================
function labels = formatTickLabels(x)

labels = cell(size(x));
for i = 1:numel(x)
    labels{i} = sprintf('%.3g', x(i));
end
end


function names = cleanTaskNames(taskTypes)

names = cell(size(taskTypes));
for i = 1:numel(taskTypes)
    names{i} = cleanTaskName(taskTypes{i});
end
end


function name = cleanTaskName(taskType)

name = strrep(taskType, '_', ' ');
if ~isempty(name)
    name(1) = upper(name(1));
end
end

function cfg = extended_analysis_config()
%EXTENDED_ANALYSIS_CONFIG Configuration for mechanism, sensitivity, and graded-landscape analyses.
%
% Population size N = 30. Each condition is repeated across 100 independent
% simulation replicates. All updates are synchronous.

cfg = struct();

cfg.rootDir   = repository_root();
cfg.dataDir   = fullfile(cfg.rootDir, 'data');
cfg.figureDir = fullfile(cfg.rootDir, 'figures');
cfg.resultDir = fullfile(cfg.rootDir, 'results');
cfg.srcDir    = fullfile(cfg.rootDir, 'matlab');

projectDirs = {cfg.dataDir, cfg.figureDir, cfg.resultDir, cfg.srcDir};
for dd = 1:numel(projectDirs)
    if ~exist(projectDirs{dd}, 'dir')
        mkdir(projectDirs{dd});
    end
end

cfg.baseSeed      = 24001;
cfg.nAgents       = 30;
cfg.nGenerations  = 80;
cfg.nSeeds        = 100;

cfg.seqLength     = 10;
cfg.alphabetSize  = 5;
cfg.targetSeq     = ones(1, cfg.seqLength);

cfg.opaqueMix     = 0.90;
cfg.opaquePower   = 8;
cfg.strictPower   = 2;

cfg.muGrid        = [0.00 0.03 0.08 0.15];
cfg.phiGrid       = [0.45 0.65 0.80 0.92 0.98];
cfg.tauLevels     = [0.00 0.60];
cfg.taskTypes     = {'smooth','opaque','strict_sequence'};

cfg.kModels              = 5;
cfg.socialLearningProb   = 0.80;
cfg.successBiasBeta      = 5;

cfg.acceptanceRule       = 'softmax';
cfg.acceptanceBeta       = 10;
cfg.copyErrorMode        = 'loss_only';

cfg.highQualityThreshold = 0.95;
cfg.improvementEps       = 1e-12;

cfg.representativeMu     = 0.15;
cfg.representativePhi    = 0.98;

% Discrimination-sensitivity grids
cfg.betaSensitivityGrid       = [0 1 2 5 10];
cfg.gammaSensitivityGrid      = [2 5 10 20 Inf];

end

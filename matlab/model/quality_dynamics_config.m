function cfg = quality_dynamics_config()
%QUALITY_DYNAMICS_CONFIG Configuration for the quality-dynamics analysis.
%
% Population size is N = 30. Each parameter condition is repeated across
% 100 independent simulation replicates. All population updates are
% synchronous.

cfg = struct();

% Project folders
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

% Reproducibility and simulation size
cfg.baseSeed      = 24001;
cfg.nAgents       = 30;
cfg.nGenerations  = 80;
cfg.nSeeds        = 100;

% Behavioural representation
cfg.seqLength     = 10;
cfg.alphabetSize  = 5;
cfg.targetSeq     = ones(1, cfg.seqLength);

% Manuscript task classes
cfg.taskTypes     = {'smooth', 'opaque', 'strict_sequence'};

% Task-function parameters
cfg.opaqueMix     = 0.90;
cfg.opaquePower   = 8;
cfg.strictPower   = 2;

% Manuscript parameter grid
cfg.muGrid        = [0.00 0.03 0.08 0.15];
cfg.phiGrid       = [0.45 0.65 0.80 0.92 0.98];
cfg.tauLevels     = [0.00 0.60];

% Social learning
cfg.kModels              = 5;
cfg.socialLearningProb   = 0.80;
cfg.successBiasBeta      = 5;

% Candidate acceptance
cfg.acceptanceRule       = 'softmax';
cfg.acceptanceBeta       = 10;

% Copying errors
cfg.copyErrorMode        = 'loss_only';

% Outcome thresholds
cfg.highQualityThreshold = 0.95;
cfg.improvementEps       = 1e-12;

% Representative condition used for trajectory figures
cfg.representativeMu     = 0.15;
cfg.representativePhi    = 0.98;

end

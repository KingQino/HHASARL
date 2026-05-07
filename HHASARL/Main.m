close all;
clc;
clear all;

% RL:
% 0 Rand
% 1 Epsilon-greedy
% 2 Thomson Sampling
% 3 Upper Confidence Bound 1

RL = 2;
print = 0;
draw = 0;

Metodo = 'EVRPSATS'; %#ok<NASGU>
MAX_TRIALS = 10;

CollectionDirectory = 'EVRP/evrp-benchmark-set/Complete';
StatsRoot = 'stats';
AlgorithmName = 'HHASARL';

instanceNames = ListInstanceFiles(CollectionDirectory);

if isempty(instanceNames)
    error('Main:NoInstancesFound', ...
        'No .txt instances were found in %s.', CollectionDirectory);
end

disp(CollectionDirectory)

for t = 1:numel(instanceNames)
    instanceFile = instanceNames{t};
    instancePath = fullfile(CollectionDirectory,instanceFile);
    disp(instanceFile)
    RunInstanceExperiment(instancePath, RL, print, draw, MAX_TRIALS, 1, StatsRoot, AlgorithmName);
end

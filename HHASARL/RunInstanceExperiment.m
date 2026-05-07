function summary = RunInstanceExperiment(instancePath, RL, printFlag, drawFlag, maxTrials, numWorkers, statsRoot, algorithmName)
    if nargin < 6 || isempty(numWorkers)
        numWorkers = 1;
    end
    if nargin < 7 || isempty(statsRoot)
        statsRoot = 'stats';
    end
    if nargin < 8 || isempty(algorithmName)
        algorithmName = 'HHASARL';
    end

    [~, instanceName, ~] = fileparts(instancePath);
    instanceDir = fullfile(statsRoot, algorithmName, instanceName);
    if ~isfolder(instanceDir)
        mkdir(instanceDir);
    end

    useParallel = numWorkers > 1;
    if useParallel && ~HasParallelSupport()
        warning('RunInstanceExperiment:NoParallelSupport', ...
            ['Parallel Computing Toolbox support unavailable. ' ...
            'Falling back to serial execution.']);
        useParallel = false;
        numWorkers = 1;
    end

    if useParallel
        pool = EnsureLocalPool(numWorkers);
        fprintf('Running %s with %d worker(s).\n', instanceName, pool.NumWorkers);
    else
        fprintf('Running %s serially.\n', instanceName);
    end

    model = Model(instancePath);
    [bestSolCell, bestCosts, trialTimes, trialFlags, trialMemory, evolutionCell] = ...
        RunTrialsForInstance(model, RL, printFlag, drawFlag, maxTrials, useParallel);

    for seed = 1:maxTrials
        seedDir = fullfile(instanceDir, num2str(seed));
        if ~isfolder(seedDir)
            mkdir(seedDir);
        end

        WriteSolutionFile(fullfile(seedDir, ['solution.' instanceName '.txt']), ...
            bestSolCell{seed}, bestCosts(seed));
        WriteEvolutionFile(fullfile(seedDir, ['evols.' instanceName '.csv']), ...
            evolutionCell{seed});
    end

    WriteStatsFile(fullfile(instanceDir, ['stats.' instanceName '.txt']), bestCosts);

    summary = struct( ...
        'instance', instanceName, ...
        'instance_dir', instanceDir, ...
        'best_costs', bestCosts, ...
        'best', min(bestCosts), ...
        'worst', max(bestCosts), ...
        'mean', mean(bestCosts), ...
        'std', std(bestCosts), ...
        'mean_time', mean(trialTimes), ...
        'flags', trialFlags, ...
        'memory', {trialMemory});

    fprintf(['Completed %s | best=%.6f mean=%.6f std=%.6f ' ...
        'mean_time=%.6f sec\n'], ...
        instanceName, summary.best, summary.mean, summary.std, summary.mean_time);
end


function [bestSolCell, bestCosts, trialTimes, trialFlags, trialMemory, evolutionCell] = ...
    RunTrialsForInstance(model, RL, printFlag, drawFlag, maxTrials, useParallel)

    bestCosts = zeros(1, maxTrials);
    trialTimes = zeros(1, maxTrials);
    trialFlags = zeros(1, maxTrials);
    trialMemory = cell(1, maxTrials);
    evolutionCell = cell(1, maxTrials);
    bestSolCell = cell(1, maxTrials);

    if useParallel
        parfor seed = 1:maxTrials
            [bestSolCell{seed}, bestCosts(seed), trialTimes(seed), ...
                trialFlags(seed), trialMemory{seed}, evolutionCell{seed}] = ...
                RunSingleTrial(model, RL, printFlag, drawFlag, seed);
        end
    else
        for seed = 1:maxTrials
            [bestSolCell{seed}, bestCosts(seed), trialTimes(seed), ...
                trialFlags(seed), trialMemory{seed}, evolutionCell{seed}] = ...
                RunSingleTrial(model, RL, printFlag, drawFlag, seed);
        end
    end
end


function [trialBestSol, trialCost, trialTime, trialFlag, trialMemory, trialEvolution] = ...
    RunSingleTrial(model, RL, printFlag, drawFlag, seed)

    rng(seed, 'twister');
    tStart = tic;
    [trialBestSol, trialCost, trialFlag, trialMemory, ~, trialEvolution] = ...
        EVRPSARL(model, RL, printFlag, drawFlag);
    trialTime = toc(tStart);
end


function WriteSolutionFile(filePath, bestSol, bestCost)
    fileID = fopen(filePath, 'w');
    if fileID == -1
        error('RunInstanceExperiment:SolutionFileOpenError', ...
            'Could not open %s for writing.', filePath);
    end
    cleaner = onCleanup(@() fclose(fileID));

    fprintf(fileID, '%.8f\n', bestCost);
    route = bestSol.CRoute(:)';
    for k = 1:numel(route)
        fprintf(fileID, '%d,', route(k));
    end
    fprintf(fileID, '\n');
    clear cleaner;
end


function WriteEvolutionFile(filePath, evolution)
    fileID = fopen(filePath, 'w');
    if fileID == -1
        error('RunInstanceExperiment:EvolutionFileOpenError', ...
            'Could not open %s for writing.', filePath);
    end
    cleaner = onCleanup(@() fclose(fileID));

    fprintf(fileID, 'obj,evals,time\n');
    for k = 1:numel(evolution.obj)
        fprintf(fileID, '%.2f,%.2f,%.2f\n', ...
            evolution.obj(k), evolution.evals(k), evolution.time(k));
    end
    clear cleaner;
end


function WriteStatsFile(filePath, bestCosts)
    fileID = fopen(filePath, 'w');
    if fileID == -1
        error('RunInstanceExperiment:StatsFileOpenError', ...
            'Could not open %s for writing.', filePath);
    end
    cleaner = onCleanup(@() fclose(fileID));

    for k = 1:numel(bestCosts)
        fprintf(fileID, '%.2f\n', bestCosts(k));
    end
    fprintf(fileID, 'Mean %.2f\t \tStd Dev %.2f\t \n', mean(bestCosts), std(bestCosts));
    fprintf(fileID, 'Min: %.2f\t \n', min(bestCosts));
    fprintf(fileID, 'Max: %.2f\t \n', max(bestCosts));
    clear cleaner;
end


function tf = HasParallelSupport()
    tf = exist('gcp', 'file') == 2 && ...
        exist('parpool', 'file') == 2 && ...
        license('test', 'Distrib_Computing_Toolbox');
end


function pool = EnsureLocalPool(numWorkers)
    pool = gcp('nocreate');
    if isempty(pool)
        pool = parpool('local', numWorkers);
        return;
    end

    if pool.NumWorkers ~= numWorkers
        delete(pool);
        pool = parpool('local', numWorkers);
    end
end

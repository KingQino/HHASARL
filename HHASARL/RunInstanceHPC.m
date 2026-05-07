function RunInstanceHPC(arrayTaskId, numWorkers)
    if nargin < 1 || isempty(arrayTaskId)
        arrayTaskId = ReadIntegerEnv('SLURM_ARRAY_TASK_ID', []);
    end
    if isempty(arrayTaskId)
        error('RunInstanceHPC:MissingArrayTaskId', ...
            ['SLURM_ARRAY_TASK_ID is not set. Pass arrayTaskId explicitly, ' ...
            'for example RunInstanceHPC(0, 10).']);
    end

    if nargin < 2 || isempty(numWorkers)
        numWorkers = ReadIntegerEnv('SLURM_CPUS_PER_TASK', 1);
    end

    RL = ReadIntegerEnv('HHASARL_RL', 2);
    printFlag = ReadIntegerEnv('HHASARL_PRINT', 0);
    drawFlag = ReadIntegerEnv('HHASARL_DRAW', 0);
    maxTrials = ReadIntegerEnv('HHASARL_MAX_TRIALS', 10);
    collectionDirectory = ReadStringEnv('HHASARL_COLLECTION_DIR', 'EVRP/evrp-benchmark-set/Complete');
    statsRoot = ReadStringEnv('HHASARL_STATS_ROOT', 'stats');
    algorithmName = ReadStringEnv('HHASARL_ALGORITHM_NAME', 'HHASARL');

    if drawFlag ~= 0 && numWorkers > 1
        error('RunInstanceHPC:ParallelDrawUnsupported', ...
            'Set HHASARL_DRAW=0 when running parallel trials on HPC.');
    end

    instanceNames = ListInstanceFiles(collectionDirectory);
    if isempty(instanceNames)
        error('RunInstanceHPC:NoInstancesFound', ...
            'No .txt instances were found in %s.', collectionDirectory);
    end

    instanceIndex = arrayTaskId + 1;
    if instanceIndex < 1 || instanceIndex > numel(instanceNames)
        error('RunInstanceHPC:ArrayIndexOutOfRange', ...
            'Array task id %d is out of range for %d instances.', ...
            arrayTaskId, numel(instanceNames));
    end

    instanceFile = instanceNames{instanceIndex};
    instancePath = fullfile(collectionDirectory, instanceFile);
    fprintf('Task %d selected %s\n', arrayTaskId, instanceFile);
    RunInstanceExperiment(instancePath, RL, printFlag, drawFlag, ...
        maxTrials, numWorkers, statsRoot, algorithmName);
end


function value = ReadIntegerEnv(name, defaultValue)
    rawValue = getenv(name);
    if isempty(rawValue)
        value = defaultValue;
        return;
    end

    value = str2double(rawValue);
    if isnan(value) || ~isfinite(value)
        error('RunInstanceHPC:InvalidIntegerEnv', ...
            'Environment variable %s must be numeric.', name);
    end

    value = round(value);
end


function value = ReadStringEnv(name, defaultValue)
    rawValue = getenv(name);
    if isempty(rawValue)
        value = defaultValue;
    else
        value = rawValue;
    end
end

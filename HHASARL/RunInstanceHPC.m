function RunInstanceHPC(varargin)
    if nargin > 2
        warning('RunInstanceHPC:ExtraInputsIgnored', ...
            'Ignoring %d extra input argument(s).', nargin - 2);
    end

    arrayTaskId = [];
    numWorkers = [];
    if nargin >= 1
        arrayTaskId = ParseOptionalInteger(varargin{1}, 'arrayTaskId');
    end
    if nargin >= 2
        numWorkers = ParseOptionalInteger(varargin{2}, 'numWorkers');
    end

    if isempty(arrayTaskId)
        arrayTaskId = ReadIntegerEnv('SLURM_ARRAY_TASK_ID', []);
    end
    if isempty(arrayTaskId)
        error('RunInstanceHPC:MissingArrayTaskId', ...
            ['SLURM_ARRAY_TASK_ID is not set. Pass arrayTaskId explicitly, ' ...
            'for example RunInstanceHPC(0, 10).']);
    end

    if isempty(numWorkers)
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

    failedFile = getenv('HHASARL_FAILED_INSTANCES');
    if ~isempty(failedFile)
        if ~isfile(failedFile)
            error('RunInstanceHPC:FailedInstanceFileNotFound', ...
                'HHASARL_FAILED_INSTANCES points to a missing file: %s', failedFile);
        end
        fprintf('Rerun mode: reading failed instances from %s\n', failedFile);
        instanceNames = ReadInstanceList(failedFile);
    else
        instanceNames = ListInstanceFiles(collectionDirectory);
        if isempty(instanceNames)
            error('RunInstanceHPC:NoInstancesFound', ...
                'No .txt instances were found in %s.', collectionDirectory);
        end
    end

    instanceIndex = arrayTaskId + 1;
    if instanceIndex < 1 || instanceIndex > numel(instanceNames)
        error('RunInstanceHPC:ArrayIndexOutOfRange', ...
            'Array task id %d is out of range for %d instances.', ...
            arrayTaskId, numel(instanceNames));
    end

    instanceFile = instanceNames{instanceIndex};
    if isfile(instanceFile)
        instancePath = instanceFile;
    else
        instancePath = fullfile(collectionDirectory, instanceFile);
    end
    fprintf('Task %d selected %s\n', arrayTaskId, instanceFile);

    maxNumCompThreads(1);
    RunInstanceExperiment(instancePath, RL, printFlag, drawFlag, ...
        maxTrials, numWorkers, statsRoot, algorithmName);
end


function value = ParseOptionalInteger(rawValue, name)
    if isempty(rawValue)
        value = [];
        return;
    end

    if isnumeric(rawValue)
        value = round(rawValue);
        return;
    end

    if isstring(rawValue) || ischar(rawValue)
        value = str2double(rawValue);
    else
        error('RunInstanceHPC:InvalidOptionalInput', ...
            '%s must be numeric or text containing a number.', name);
    end

    if isnan(value) || ~isfinite(value)
        error('RunInstanceHPC:InvalidOptionalInput', ...
            '%s must be numeric.', name);
    end

    value = round(value);
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


function instanceNames = ReadInstanceList(filePath)
    fileID = fopen(filePath, 'r');
    if fileID == -1
        error('RunInstanceHPC:FailedInstanceFileOpenError', ...
            'Could not open failed instance list: %s', filePath);
    end
    cleaner = onCleanup(@() fclose(fileID));

    rawNames = textscan(fileID, '%s', 'Delimiter', '\n', 'Whitespace', '');
    instanceNames = rawNames{1};
    instanceNames = strtrim(instanceNames);
    instanceNames = instanceNames(~cellfun('isempty', instanceNames));
    instanceNames = instanceNames(cellfun(@(x) ~strncmp(x, '#', 1), instanceNames));

    if isempty(instanceNames)
        error('RunInstanceHPC:EmptyFailedInstanceFile', ...
            'No instance names were found in %s.', filePath);
    end

    clear cleaner;
end

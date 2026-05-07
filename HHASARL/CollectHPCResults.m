function CollectHPCResults(statsRoot, algorithmName)
    if nargin < 1 || isempty(statsRoot)
        statsRoot = ReadStringEnvLocal('HHASARL_STATS_ROOT', 'stats');
    end
    if nargin < 2 || isempty(algorithmName)
        algorithmName = ReadStringEnvLocal('HHASARL_ALGORITHM_NAME', 'HHASARL');
    end

    algorithmDir = fullfile(statsRoot, algorithmName);
    dirInfo = dir(algorithmDir);
    dirInfo = dirInfo([dirInfo.isdir]);
    dirInfo = dirInfo(~ismember({dirInfo.name}, {'.', '..'}));
    instanceNames = sort({dirInfo.name});

    if isempty(instanceNames)
        error('CollectHPCResults:NoInstanceDirs', ...
            'No instance directories were found in %s.', algorithmDir);
    end

    general = cell(numel(instanceNames), 6);
    for k = 1:numel(instanceNames)
        instanceName = instanceNames{k};
        instanceDir = fullfile(algorithmDir, instanceName);
        seedDirs = dir(instanceDir);
        seedDirs = seedDirs([seedDirs.isdir]);
        seedDirs = seedDirs(~ismember({seedDirs.name}, {'.', '..'}));
        seedNames = sort({seedDirs.name});

        costs = [];
        times = [];
        for s = 1:numel(seedNames)
            if isempty(regexp(seedNames{s}, '^\d+$', 'once'))
                continue;
            end
            solutionPath = fullfile(instanceDir, seedNames{s}, ...
                ['solution.' instanceName '.txt']);
            evolPath = fullfile(instanceDir, seedNames{s}, ...
                ['evols.' instanceName '.csv']);
            if ~isfile(solutionPath)
                continue;
            end
            fileID = fopen(solutionPath, 'r');
            if fileID == -1
                continue;
            end
            cleaner = onCleanup(@() fclose(fileID));
            firstLine = fgetl(fileID);
            clear cleaner;
            costValue = str2double(firstLine);
            if ~isnan(costValue)
                costs(end+1) = costValue; %#ok<AGROW>
            end
            timeValue = ReadLastEvolutionTime(evolPath);
            if ~isnan(timeValue)
                times(end+1) = timeValue; %#ok<AGROW>
            end
        end

        if isempty(costs)
            error('CollectHPCResults:NoSeedResults', ...
                'No solution files were found for %s.', instanceName);
        end

        if isempty(times)
            meanTime = NaN;
        else
            meanTime = mean(times);
        end

        general(k, :) = {instanceName, min(costs), max(costs), mean(costs), std(costs), meanTime};
    end

    save(fullfile(algorithmDir, 'general.mat'), 'general');
    writecell([{'instance', 'min', 'max', 'mean', 'std', 'mean_time'}; general], ...
        fullfile(algorithmDir, 'general.csv'));

    fprintf('Collected %d instance summaries into %s\n', ...
        numel(instanceNames), algorithmDir);
end


function value = ReadStringEnvLocal(name, defaultValue)
    rawValue = getenv(name);
    if isempty(rawValue)
        value = defaultValue;
    else
        value = rawValue;
    end
end


function timeValue = ReadLastEvolutionTime(evolPath)
    timeValue = NaN;
    if ~isfile(evolPath)
        return;
    end

    fileID = fopen(evolPath, 'r');
    if fileID == -1
        return;
    end
    cleaner = onCleanup(@() fclose(fileID));

    headerLine = fgetl(fileID); %#ok<NASGU>
    lastLine = '';
    while true
        currentLine = fgetl(fileID);
        if ~ischar(currentLine)
            break;
        end
        currentLine = strtrim(currentLine);
        if ~isempty(currentLine)
            lastLine = currentLine;
        end
    end
    clear cleaner;

    if isempty(lastLine)
        return;
    end

    parts = strsplit(lastLine, ',');
    if numel(parts) < 3
        return;
    end

    parsedValue = str2double(parts{3});
    if ~isnan(parsedValue)
        timeValue = parsedValue;
    end
end

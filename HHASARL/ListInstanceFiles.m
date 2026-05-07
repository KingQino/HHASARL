function instanceNames = ListInstanceFiles(collectionDirectory)
    fileInfo = dir(fullfile(collectionDirectory,'*.txt'));
    instanceNames = sort({fileInfo.name});
end

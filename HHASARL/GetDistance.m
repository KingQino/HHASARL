function values = GetDistance(model, fromIndex, toIndex)
    values = model.d(fromIndex, toIndex);
    EvalCounter('add_partial', numel(values));
end

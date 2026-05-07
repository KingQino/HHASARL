function tour_length=fitness_evaluation(routes,modelOrDistances)
    if isstruct(modelOrDistances)
        distances = modelOrDistances.d;
        shouldCountEval = true;
    else
        distances = modelOrDistances;
        shouldCountEval = false;
    end

    tour_length=0;
    for i=1:length(routes)-1
        tour_length=tour_length+distances(routes(i)+1,routes(i+1)+1);
    end

    if shouldCountEval
        EvalCounter('add_complete', 1);
    end
end

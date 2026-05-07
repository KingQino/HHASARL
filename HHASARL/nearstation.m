function [station,vv]=nearstation(stations,from,to,model)
    EvalCounter('add_partial', 1);
    problem_size=model.SIZE;
    stations2=stations;
    for i=1:length(stations)
        stations(i)=GetDistance(model,to,i+problem_size);%to
    end
    [vv]=min(stations);
    ind=find(stations==vv);
    if length(ind)==1
        station=ind; 
    else
        for i=1:length(stations)
            stations2(i)=GetDistance(model,from,i+problem_size);%from
        end
        if stations2(ind(1))<stations2(ind(2))
            station=ind(1);
        else
            station=ind(2);
        end
    end
end

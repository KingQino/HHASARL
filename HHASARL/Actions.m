function [Cq,q,permuta]=Actions(Cruta,ruta,action,model,permuta)
        EvalCounter('add_partial', 1);
        if action<=4
            a=permuta(1);
            permuta(1)=[];
            porce=round(model.n*0.20);
            A=GetDistance(model,a+1,2:model.SIZE);
            [~,indx]=sort(A);
            val=indx(2:min(porce+1,length(indx)));
            a=BuildDistinctPair(a,val,model.n);
        elseif action>=5 && action<=8
            a=permuta(1);
            permuta(1)=[];
            porce=round(model.n*0.50);
            A=GetDistance(model,a+1,2:model.SIZE);
            [~,indx]=sort(A);
            val=indx(2:min(porce+1,length(indx)));
            a=BuildDistinctPair(a,val,model.n);
        else
            a=permuta(1);
            permuta(1)=[];
            temp=ruta(ruta>0);
            temp(find(temp==a))=[];
            if isempty(temp)
                a=a;
            else
        	    a=sort([a temp(round(rand()*(length(temp)-1))+1)]);
            end
        end
   	c=ismember(ruta,a);
	indexes=find(c);
 	Cc=ismember(Cruta,a);
	Cindexes=find(Cc);
    if numel(indexes)<2 || numel(Cindexes)<2
        q=ruta;
        Cq=Cruta;
        return;
    end
    switch action      
        %IntraRoute Modificar la Cadena
        case 1  % Swap
            q=DoSwap(ruta,indexes(1),indexes(2));
            Cq=DoSwap(Cruta,Cindexes(1),Cindexes(2));
      	case 2  % Reversion  
            q=DoReversion(ruta,indexes(1),indexes(2));
            Cq=DoReversion(Cruta,Cindexes(1),Cindexes(2));
    	case 3  % 2OPT
            q=Do2Opt(ruta,indexes(1),indexes(2));
            Cq=Do2Opt(Cruta,Cindexes(1),Cindexes(2));
            if q(end)~=0
                q(end+1)=0;
                Cq(end+1)=0;
            end
     	case 4  % Insertion
            q=DoInsertion(ruta,indexes(1),indexes(2));
            Cq=DoInsertion(Cruta,Cindexes(1),Cindexes(2));
        case 5
             q=DoSwap(ruta,indexes(1),indexes(2));
            Cq=DoSwap(Cruta,Cindexes(1),Cindexes(2));
      	case 6  % Reversion  
            q=DoReversion(ruta,indexes(1),indexes(2));
            Cq=DoReversion(Cruta,Cindexes(1),Cindexes(2));
    	case 7  % 2OPT
            q=Do2Opt(ruta,indexes(1),indexes(2));
            Cq=Do2Opt(Cruta,Cindexes(1),Cindexes(2));
            if q(end)~=0
                q(end+1)=0;
                Cq(end+1)=0;
            end
     	case 8  % Insertion
            q=DoInsertion(ruta,indexes(1),indexes(2));
            Cq=DoInsertion(Cruta,Cindexes(1),Cindexes(2));
        case 9
             q=DoSwap(ruta,find(ruta==a(1)),find(ruta==a(2)));
            Cq=DoSwap(Cruta,Cindexes(1),Cindexes(2));
      	case 10  % Reversion  
            q=DoReversion(ruta,find(ruta==a(1)),find(ruta==a(2)));
            Cq=DoReversion(Cruta,find(Cruta==a(1)),find(Cruta==a(2)));
    	case 11  % 2OPT
            q=Do2Opt(ruta,find(ruta==a(1)),find(ruta==a(2)));
            Cq=Do2Opt(Cruta,find(Cruta==a(1)),find(Cruta==a(2)));
            if q(end)~=0
                q(end+1)=0;
                Cq(end+1)=0;
            end
     	case 12  % Insertion
            q=DoInsertion(ruta,find(ruta==a(1)),find(ruta==a(2))); 
            Cq=DoInsertion(Cruta,find(Cruta==a(1)),find(Cruta==a(2)));
        case 13
            va=round(model.n*0.3);
            v=randperm(model.n); 
            a=v(1:va);
            for l=1:length(a)
                u(l)=find(ruta==a(l));
            end
            [q,Cq]=DoDR(ruta,Cruta,u,0,model);
    end
end


function pair = BuildDistinctPair(anchor,candidates,numCustomers)
    candidates = candidates(:)';
    candidates = candidates(candidates ~= anchor);

    if isempty(candidates)
        fallback = setdiff(1:numCustomers, anchor, 'stable');
        if isempty(fallback)
            pair = anchor;
        else
            pair = sort([anchor fallback(1)]);
        end
        return;
    end

    partner = candidates(randi(numel(candidates)));
    pair = sort([anchor partner]);
end

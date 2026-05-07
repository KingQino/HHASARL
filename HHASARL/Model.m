function model=Model(name)
    instance = ReadInstanceSections(name);

    NUM_OF_DEPOTS = numel(instance.depot_ids);
    if NUM_OF_DEPOTS ~= 1
        error('Model:UnsupportedDepotCount', ...
            'Expected exactly one depot in %s, found %d.', name, NUM_OF_DEPOTS);
    end

    NUM_OF_CUSTOMERS = numel(instance.customer_ids);
    NUM_OF_STATIONS = numel(instance.station_ids);
    problem_size = NUM_OF_DEPOTS + NUM_OF_CUSTOMERS;
    ACTUAL_PROBLEM_SIZE = problem_size + NUM_OF_STATIONS;
    TERMINATION = 25000*ACTUAL_PROBLEM_SIZE;

    ordered_ids = [instance.depot_ids(:); instance.customer_ids(:); instance.station_ids(:)];
    [found_coords, coord_locs] = ismember(ordered_ids, instance.coord_ids(:));
    if any(~found_coords)
        missing_ids = ordered_ids(~found_coords);
        error('Model:MissingCoordinates', ...
            'Missing coordinates for node ids: %s in %s.', mat2str(missing_ids'), name);
    end

    node_list = [instance.coord_x(coord_locs), instance.coord_y(coord_locs)];
    x = node_list(:,1)';
    y = node_list(:,2)';

    cust_demand = zeros(ACTUAL_PROBLEM_SIZE,1);
    [found_demand, demand_locs] = ismember(instance.customer_ids(:), instance.demand_ids(:));
    if any(~found_demand)
        missing_ids = instance.customer_ids(~found_demand);
        error('Model:MissingDemand', ...
            'Missing demand for customer ids: %s in %s.', mat2str(missing_ids'), name);
    end
    cust_demand(NUM_OF_DEPOTS+1:problem_size) = instance.demand_values(demand_locs);

    charging_station = zeros(ACTUAL_PROBLEM_SIZE,1);
    charging_station(1:NUM_OF_DEPOTS) = 1;
    charging_station(problem_size+1:end) = 1;

    d = zeros(ACTUAL_PROBLEM_SIZE,ACTUAL_PROBLEM_SIZE);
    for i=1:ACTUAL_PROBLEM_SIZE
        for j=i:ACTUAL_PROBLEM_SIZE
            xd = node_list(i,1)-node_list(j,1);
            yd = node_list(i,2)-node_list(j,2);
            d(i,j) = sqrt(xd*xd + yd*yd);
            d(j,i) = d(i,j);
        end
    end

    xmin = min(x);
    xmax = max(x);
    ymin = min(y);
    ymax = max(y);

    model.n = NUM_OF_CUSTOMERS;
    model.x = x;
    model.y = y;
    model.d = d;
    model.MaxIter = TERMINATION;
    model.VEHICLES = instance.min_vehicles;
    model.CAPACITY = instance.max_capacity;
    model.DEMAND = cust_demand;
    model.ENERGY = instance.battery_capacity;
    model.STATIONS = NUM_OF_STATIONS;
    model.CONSUMPTION = instance.energy_consumption;
    model.SIZE = problem_size;
    model.DEPOTS = NUM_OF_DEPOTS;
    model.ACTUAL_PROBLEM_SIZE = ACTUAL_PROBLEM_SIZE;
    model.NODE_IDS = ordered_ids;
    model.OPTIMUM = instance.optimum;
    model.xmin = xmin;
    model.xmax = xmax;
    model.ymin = ymin;
    model.ymax = ymax;
    model.charging = charging_station;
end


function instance = ReadInstanceSections(filename)
    fileID = fopen(filename,'r');
    if fileID == -1
        error('Model:FileOpenError', 'Could not open instance file %s.', filename);
    end
    cleaner = onCleanup(@() fclose(fileID));

    coord_ids = [];
    coord_x = [];
    coord_y = [];
    demand_ids = [];
    demand_values = [];
    station_ids = [];
    depot_ids = [];

    section = 'header';
    min_vehicles = [];
    max_capacity = [];
    battery_capacity = [];
    energy_consumption = [];
    optimum = NaN;

    while true
        line = fgetl(fileID);
        if ~ischar(line)
            break;
        end

        line = strtrim(line);
        if isempty(line)
            continue;
        end

        switch section
            case 'header'
                if strcmpi(line,'NODE_COORD_SECTION')
                    section = 'coords';
                    continue;
                end

                [key, value] = ParseHeaderLine(line);
                switch upper(key)
                    case 'VEHICLES'
                        min_vehicles = ParseFirstNumber(value);
                    case 'CAPACITY'
                        max_capacity = ParseFirstNumber(value);
                    case 'ENERGY_CAPACITY'
                        battery_capacity = ParseFirstNumber(value);
                    case 'ENERGY_CONSUMPTION'
                        energy_consumption = ParseFirstNumber(value);
                    case 'OPTIMAL_VALUE'
                        optimum = ParseFirstNumber(value);
                end

            case 'coords'
                if strcmpi(line,'DEMAND_SECTION')
                    section = 'demand';
                    continue;
                end

                values = sscanf(line,'%f');
                if numel(values) >= 3
                    coord_ids(end+1,1) = values(1); %#ok<AGROW>
                    coord_x(end+1,1) = values(2); %#ok<AGROW>
                    coord_y(end+1,1) = values(3); %#ok<AGROW>
                end

            case 'demand'
                if strcmpi(line,'STATIONS_COORD_SECTION')
                    section = 'stations';
                    continue;
                elseif strcmpi(line,'DEPOT_SECTION')
                    section = 'depot';
                    continue;
                end

                values = sscanf(line,'%f');
                if numel(values) >= 2
                    demand_ids(end+1,1) = values(1); %#ok<AGROW>
                    demand_values(end+1,1) = values(2); %#ok<AGROW>
                end

            case 'stations'
                if strcmpi(line,'DEPOT_SECTION')
                    section = 'depot';
                    continue;
                end

                values = sscanf(line,'%f');
                if ~isempty(values)
                    station_ids(end+1,1) = values(1); %#ok<AGROW>
                end

            case 'depot'
                if strcmpi(line,'EOF')
                    section = 'done';
                    continue;
                end

                values = sscanf(line,'%f');
                if ~isempty(values) && values(1) ~= -1
                    depot_ids(end+1,1) = values(1); %#ok<AGROW>
                end
        end
    end

    clear cleaner;

    station_ids = unique(station_ids,'stable');
    depot_ids = unique(depot_ids,'stable');

    if isempty(coord_ids) || isempty(demand_ids) || isempty(depot_ids)
        error('Model:InvalidInstance', 'Incomplete section data in %s.', filename);
    end

    customer_mask = ~ismember(demand_ids, [depot_ids; station_ids]);
    customer_ids = demand_ids(customer_mask);

    instance.coord_ids = coord_ids;
    instance.coord_x = coord_x;
    instance.coord_y = coord_y;
    instance.demand_ids = demand_ids;
    instance.demand_values = demand_values;
    instance.station_ids = station_ids;
    instance.depot_ids = depot_ids;
    instance.customer_ids = customer_ids;
    instance.min_vehicles = min_vehicles;
    instance.max_capacity = max_capacity;
    instance.battery_capacity = battery_capacity;
    instance.energy_consumption = energy_consumption;
    instance.optimum = optimum;

    ValidateMetadata(instance, filename);
end


function [key, value] = ParseHeaderLine(line)
    tokens = regexp(line,'^\s*([A-Za-z_]+)\s*:?\s*(.*)$','tokens','once');
    if isempty(tokens)
        key = '';
        value = '';
    else
        key = tokens{1};
        value = tokens{2};
    end
end


function value = ParseFirstNumber(text_value)
    tokens = regexp(text_value,'[-+]?\d*\.?\d+','match','once');
    if isempty(tokens)
        value = NaN;
    else
        value = str2double(tokens);
    end
end


function ValidateMetadata(instance, filename)
    required_fields = {'min_vehicles','max_capacity','battery_capacity','energy_consumption'};
    for k = 1:numel(required_fields)
        field_name = required_fields{k};
        if isempty(instance.(field_name)) || isnan(instance.(field_name))
            error('Model:MissingMetadata', ...
                'Missing required header field %s in %s.', field_name, filename);
        end
    end

    ordered_ids = [instance.depot_ids(:); instance.customer_ids(:); instance.station_ids(:)];
    if numel(unique(ordered_ids)) ~= numel(ordered_ids)
        error('Model:DuplicateNodeIds', 'Duplicated node ids found in %s.', filename);
    end
end

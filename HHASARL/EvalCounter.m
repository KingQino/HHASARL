function value = EvalCounter(command, varargin)
    global HHASARL_EVAL_COUNTER HHASARL_PARTIAL_EVAL_STEP

    if isempty(HHASARL_EVAL_COUNTER)
        HHASARL_EVAL_COUNTER = 0;
    end
    if isempty(HHASARL_PARTIAL_EVAL_STEP)
        HHASARL_PARTIAL_EVAL_STEP = 1;
    end

    switch lower(command)
        case 'init'
            actualProblemSize = double(varargin{1});
            HHASARL_EVAL_COUNTER = 0;
            HHASARL_PARTIAL_EVAL_STEP = 1.0 / actualProblemSize;
            value = HHASARL_EVAL_COUNTER;

        case 'get'
            value = HHASARL_EVAL_COUNTER;

        case 'add_partial'
            amount = 1;
            if ~isempty(varargin)
                amount = double(varargin{1});
            end
            HHASARL_EVAL_COUNTER = HHASARL_EVAL_COUNTER + amount * HHASARL_PARTIAL_EVAL_STEP;
            value = HHASARL_EVAL_COUNTER;

        case 'add_complete'
            amount = 1;
            if ~isempty(varargin)
                amount = double(varargin{1});
            end
            HHASARL_EVAL_COUNTER = HHASARL_EVAL_COUNTER + amount;
            value = HHASARL_EVAL_COUNTER;

        case 'step'
            value = HHASARL_PARTIAL_EVAL_STEP;

        otherwise
            error('EvalCounter:UnknownCommand', ...
                'Unknown command %s.', command);
    end
end

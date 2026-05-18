function result = rademacher_experiment(varargin)
%RADERMACHER_EXPERIMENT Rademacher sketched least-squares experiment.
%
% RESULT = RADERMACHER_EXPERIMENT() runs the default experiment.
%
% RESULT = RADERMACHER_EXPERIMENT('name', value, ...) customizes the run.
% Supported options are the same as sketch_experiment, except method is
% fixed to 'rademacher'.

    opts = parse_rademacher_inputs(varargin{:});
    result = sketch_experiment(opts{:});
end


function pv = parse_rademacher_inputs(varargin)
    if mod(numel(varargin), 2) ~= 0
        error('Arguments must be provided as name/value pairs.');
    end

    has_method = false;
    for k = 1:2:numel(varargin)
        if strcmpi(varargin{k}, 'method')
            has_method = true;
        end
    end

    pv = [varargin(:)', {'method', 'rademacher'}];
    if has_method
        warning('rademacher_experiment:override', ...
            'method option ignored; forced to ''rademacher''.');
    end
end

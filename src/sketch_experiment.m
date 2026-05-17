function result = sketch_experiment(varargin)
%SKETCH_EXPERIMENT General sketched least-squares experiment for Octave/MATLAB.
%
% RESULT = SKETCH_EXPERIMENT() runs the default Gaussian experiment.
%
% RESULT = SKETCH_EXPERIMENT('name', value, ...) customizes the run.
% Supported options are:
%   n              number of rows of A (power of 2 for SRHT)
%   d              number of columns of A
%   trials         number of independent sketches per sketch size
%   s_vals         vector of sketch sizes
%   noise_level    standard deviation of additive Gaussian noise in b
%   method         sketch type: 'gaussian', 'rademacher', or 'srht'

    opts = parse_inputs(varargin{:});

    n = opts.n;
    if strcmpi(opts.method, 'srht')
        if (bitand(n, n - 1) ~= 0)
            n = 2^ceil(log2(n));
            warning('sketch_experiment:rounding', ...
                'SRHT requires n = power of 2; rounding up to %d.', n);
        end
    end

    A = randn(n, opts.d);
    x_true = ones(opts.d, 1);
    noise = opts.noise_level * randn(n, 1);
    b = A * x_true + noise;

    x_ref = A \ b;
    ref_residual = norm(A * x_ref - b);
    ref_norm = norm(x_ref);

    history = zeros(numel(opts.s_vals), 4);
    cond_history = zeros(numel(opts.s_vals), 2);

    for ii = 1:numel(opts.s_vals)
        s = opts.s_vals(ii);

        xhat_sum = zeros(opts.d, 1);
        residual_ratios = zeros(opts.trials, 1);
        solution_errors = zeros(opts.trials, 1);
        cond_values = zeros(opts.trials, 1);

        for j = 1:opts.trials
            S = build_sketch(s, n, opts.method);
            SA = S * A;
            Sb = S * b;

            xhat = SA \ Sb;
            xhat_sum = xhat_sum + xhat;

            residual_ratios(j) = norm(A * xhat - b) / ref_residual;
            solution_errors(j) = norm(xhat - x_ref) / ref_norm;
            cond_values(j) = cond(SA);
        end

        xhat_mean = xhat_sum / opts.trials;
        mean_abs_error = mean(abs(xhat_mean - x_true));

        history(ii, :) = [s, mean_abs_error, mean(residual_ratios), mean(solution_errors)];
        cond_history(ii, :) = [s, mean(cond_values)];
    end

    result.history = history;
    result.cond_history = cond_history;
    result.x_ref = x_ref;
    result.options = opts;
end


function S = build_sketch(s, n, method)
    switch lower(method)
        case 'gaussian'
            S = randn(s, n) / sqrt(s);
        case 'rademacher'
            S = (2 * randi([0,1], s, n) - 1) / sqrt(s);
        case 'srht'
            H = hadamard(n);
            idx = randperm(n, s);
            signs = 2 * randi([0,1], n, 1) - 1;
            S = H(idx, :) .* signs' ./ sqrt(s);
        otherwise
            error('Unknown method: %s', method);
    end
end


function opts = parse_inputs(varargin)
    opts.n = 128;
    opts.d = 10;
    opts.trials = 10;
    opts.s_vals = 20:10:120;
    opts.noise_level = 0;
    opts.method = 'gaussian';

    if mod(numel(varargin), 2) ~= 0
        error('Arguments must be provided as name/value pairs.');
    end

    for k = 1:2:numel(varargin)
        name = varargin{k};
        value = varargin{k + 1};

        switch lower(name)
            case 'n'
                opts.n = value;
            case 'd'
                opts.d = value;
            case 'trials'
                opts.trials = value;
            case 's_vals'
                opts.s_vals = value;
            case 'noise_level'
                opts.noise_level = value;
            case 'method'
                opts.method = value;
            otherwise
                error('Unknown option: %s', name);
        end
    end
end

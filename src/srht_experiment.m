function result = srht_experiment(varargin)
%SRHT_EXPERIMENT SRHT sketched least-squares experiment for Octave/MATLAB.
%
% RESULT = SRHT_EXPERIMENT() runs the default experiment.
%
% RESULT = SRHT_EXPERIMENT('name', value, ...) customizes the run.
% Supported options are:
%   n              number of rows of A (must be a power of 2)
%   d              number of columns of A
%   trials         number of independent sketches per sketch size
%   s_vals         vector of sketch sizes
%   noise_level    standard deviation of additive Gaussian noise in b

    opts = parse_inputs(varargin{:});

    n = opts.n;
    if (bitand(n, n - 1) ~= 0)
        n = 2^ceil(log2(n));
        warning('srht_experiment:rounding', ...
            'SRHT requires n = power of 2; rounding up to %d.', n);
    end

    A = randn(n, opts.d);
    x_true = ones(opts.d, 1);
    noise = opts.noise_level * randn(n, 1);
    b = A * x_true + noise;

    x_ref = A \ b;
    ref_residual = norm(A * x_ref - b);

    history = zeros(numel(opts.s_vals), 4);
    cond_history = zeros(numel(opts.s_vals), 2);

    for ii = 1:numel(opts.s_vals)
        s = opts.s_vals(ii);

        xhat_sum = zeros(opts.d, 1);
        residual_ratios = zeros(opts.trials, 1);
        solution_errors = zeros(opts.trials, 1);
        cond_values = zeros(opts.trials, 1);

        for j = 1:opts.trials
            S = build_srht(s, n);
            SA = S * A;
            Sb = S * b;

            xhat = SA \ Sb;
            xhat_sum = xhat_sum + xhat;

            residual_ratios(j) = norm(A * xhat - b) / ref_residual;
            solution_errors(j) = norm(xhat - x_ref) / norm(x_ref);
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

function S = build_srht(s, n)
    H = hadamard(n);
    idx = randperm(n, s);
    signs = 2 * randi([0, 1], n, 1) - 1;
    S = H(idx, :) .* signs' ./ sqrt(s);
end

function opts = parse_inputs(varargin)
    opts.n = 128;
    opts.d = 10;
    opts.trials = 10;
    opts.s_vals = 20:10:120;
    opts.noise_level = 0;

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
            otherwise
                error('Unknown option: %s', name);
        end
    end
end

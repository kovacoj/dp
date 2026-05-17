function result = randLS_experiment(varargin)
%RANDLS_EXPERIMENT Gaussian sketched least-squares experiment for Octave/MATLAB.
%
% RESULT = RANDLS_EXPERIMENT() runs the default experiment.
%
% RESULT = RANDLS_EXPERIMENT('name', value, ...) customizes the run.
% Supported options are:
%   n              number of rows of A
%   d              number of columns of A
%   trials         number of independent sketches per sketch size
%   s_vals         vector of sketch sizes
%   noise_level    standard deviation of additive Gaussian noise in b
%   use_symbolic   true/false to request higher precision when available

    opts = parse_inputs(varargin{:});

    [use_symbolic, cast_num, to_double] = configure_precision(opts.use_symbolic);

    A = cast_num(randn(opts.n, opts.d));
    x_true = cast_num(ones(opts.d, 1));
    noise = cast_num(opts.noise_level * randn(opts.n, 1));
    b = A * x_true + noise;

    x_ref = A \ b;
    ref_residual = norm(A * x_ref - b);

    history = zeros(numel(opts.s_vals), 4);

    for ii = 1:numel(opts.s_vals)
        s = opts.s_vals(ii);

        xhat_sum = cast_num(zeros(opts.d, 1));
        residual_ratios = zeros(opts.trials, 1);
        solution_errors = zeros(opts.trials, 1);
        cond_values = zeros(opts.trials, 1);
        inv_sqrt_s = 1 / sqrt(cast_num(s));

        for j = 1:opts.trials
            S = cast_num(randn(s, opts.n)) * inv_sqrt_s;
            SA = S * A;
            Sb = S * b;

            xhat = SA \ Sb;
            xhat_sum = xhat_sum + xhat;

            residual_ratios(j) = to_double(norm(A * xhat - b) / ref_residual);
            solution_errors(j) = to_double(norm(xhat - x_ref) / norm(x_ref));
            cond_values(j) = cond(to_double(SA));
        end

        xhat_mean = xhat_sum / cast_num(opts.trials);
        mean_abs_error = mean(abs(xhat_mean - x_true));

        history(ii, :) = [
            s,
            to_double(mean_abs_error),
            mean(residual_ratios),
            mean(solution_errors)
        ];

        result.cond_history(ii, :) = [s, mean(cond_values)]; %#ok<AGROW>
    end

    result.history = history;
    result.x_ref = x_ref;
    result.use_symbolic = use_symbolic;
    result.options = opts;
end

function opts = parse_inputs(varargin)
    opts.n = 100;
    opts.d = 10;
    opts.trials = 10;
    opts.s_vals = 1:99;
    opts.noise_level = 0;
    opts.use_symbolic = true;

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
            case 'use_symbolic'
                opts.use_symbolic = value;
            otherwise
                error('Unknown option: %s', name);
        end
    end
end

function [use_symbolic, cast_num, to_double] = configure_precision(request_symbolic)
    use_symbolic = false;

    if exist('OCTAVE_VERSION', 'builtin')
        rand('state', 0);
        randn('state', 0);

        if request_symbolic && (exist('pkg', 'builtin') || exist('pkg', 'file'))
            try
                pkg load symbolic;
                digits(30);
                use_symbolic = true;
            catch
                warning('Octave symbolic package not available; falling back to double precision.');
            end
        end
    else
        rng(0);
        if request_symbolic
            try
                digits(30);
                use_symbolic = true;
            catch
                warning('Higher-precision arithmetic unavailable; falling back to double precision.');
            end
        end
    end

    cast_num = @(z) z;
    to_double = @(z) z;

    if use_symbolic
        cast_num = @(z) vpa(z);
        to_double = @(z) double(z);
    end
end

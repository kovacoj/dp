function result = iterative_refine(A, b, s, varargin)
%ITERATIVE_REFINE Sketch-and-solve with optional iterative refinement.
%
% RESULT = ITERATIVE_REFINE(A, B, S) performs sketch-and-solve with
% Gaussian sketch of size S and no refinement.
%
% RESULT = ITERATIVE_REFINE(A, B, S, 'name', value, ...) customizes.
% Supported options are:
%   method       sketch type: 'gaussian', 'rademacher', 'srht'
%   ref_steps    number of refinement iterations (0 = sketch-and-solve only)
%   sketch_prec  precision for forming S, SA, Sb
%   solve_prec   precision for the initial sketch-and-solve
%   ref_prec     precision for computing refinement residuals

    opts = parse_inputs(varargin{:});

    n = size(A, 1);
    d = size(A, 2);

    S = build_sketch(s, n, opts.method);
    S = fl_round(S, opts.sketch_prec);

    SA = fl_round(S * A, opts.sketch_prec);
    Sb = fl_round(S * b, opts.sketch_prec);

    xhat = fl_solve(SA, Sb, opts.solve_prec);

    ref_history = zeros(opts.ref_steps + 1, 3);
    r0 = A * xhat - b;
    ref_history(1, :) = [0, norm(r0), norm(xhat)];

    for k = 1:opts.ref_steps
        r = fl_round(A * xhat - b, opts.ref_prec);

        Sr = fl_round(S * r, opts.sketch_prec);

        dx = fl_solve(SA, Sr, opts.solve_prec);

        xhat = xhat - dx;

        r_new = A * xhat - b;
        ref_history(k + 1, :) = [k, norm(r_new), norm(xhat)];
    end

    result.x = xhat;
    result.residual = A * xhat - b;
    result.residual_norm = norm(A * xhat - b);
    result.condition_number = cond(SA);
    result.ref_history = ref_history;
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


function x = fl_solve(SA, Sb, prec)
    if strcmpi(prec, 'double')
        x = SA \ Sb;
    else
        SA_r = fl_round(SA, prec);
        Sb_r = fl_round(Sb, prec);
        x = SA_r \ Sb_r;
    end
end


function opts = parse_inputs(varargin)
    opts.method = 'gaussian';
    opts.ref_steps = 0;
    opts.sketch_prec = 'double';
    opts.solve_prec = 'double';
    opts.ref_prec = 'double';

    if mod(numel(varargin), 2) ~= 0
        error('Arguments must be provided as name/value pairs.');
    end

    for k = 1:2:numel(varargin)
        name = varargin{k};
        value = varargin{k + 1};

        switch lower(name)
            case 'method'
                opts.method = value;
            case 'ref_steps'
                opts.ref_steps = value;
            case 'sketch_prec'
                opts.sketch_prec = value;
            case 'solve_prec'
                opts.solve_prec = value;
            case 'ref_prec'
                opts.ref_prec = value;
            otherwise
                error('Unknown option: %s', name);
        end
    end
end

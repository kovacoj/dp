function result = bench_sketch(A, b, s, method, trials)
%BENCH_SKETCH Time sketch formation and solve for one (s, method) pair.
%
%   RESULT = BENCH_SKETCH(A, B, S, METHOD, TRIALS) returns a struct with
%   timing statistics.
%
%   Fields:
%     sketch_time  - mean wall time for forming SA (seconds)
%     solve_time   - mean wall time for solving SA\x = Sb (seconds)
%     total_time   - sketch_time + solve_time
%     s            - sketch dimension
%     method       - sketch family name

    n = size(A, 1);
    sketch_times = zeros(trials, 1);
    solve_times = zeros(trials, 1);

    for j = 1:trials
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

        tic;
        SA = S * A;
        Sb = S * b;
        sketch_times(j) = toc;

        tic;
        xhat = SA \ Sb;
        solve_times(j) = toc;
    end

    result.sketch_time = mean(sketch_times);
    result.solve_time = mean(solve_times);
    result.total_time = result.sketch_time + result.solve_time;
    result.s = s;
    result.method = method;
end

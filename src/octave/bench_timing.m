% Driver script for timing benchmarks: Gaussian vs Rademacher vs SRHT.
% Measures wall-clock time for sketch formation and solve as functions of s.

clear; clc;

this_dir = fileparts(mfilename('fullpath'));
if ~isempty(this_dir)
    addpath(this_dir);
end

n = 1024; d = 20;
A = randn(n, d);
b = A * ones(d, 1);

s_vals = 40:40:500;
trials = 20;
methods = {'gaussian', 'rademacher', 'srht'};

results = {};
for mi = 1:numel(methods)
    method = methods{mi};
    for si = 1:numel(s_vals)
        s = s_vals(si);
        r = bench_sketch(A, b, s, method, trials);
        results{end+1} = r; %#ok<AGROW>
    end
end

% Collate into tables
sketch_tbl = zeros(numel(s_vals) * numel(methods), 4);
solve_tbl  = zeros(numel(s_vals) * numel(methods), 4);
total_tbl  = zeros(numel(s_vals) * numel(methods), 4);
for k = 1:numel(results)
    r = results{k};
    sketch_tbl(k, :) = [r.s, mi_lookup(r.method, methods), r.sketch_time, r.solve_time];
    solve_tbl(k, :)  = [r.s, mi_lookup(r.method, methods), r.solve_time, 0];
    total_tbl(k, :)  = [r.s, mi_lookup(r.method, methods), r.total_time, 0];
end

% --- Plot: total time vs s ---
figure;
cols = {'b', 'r', 'g'};
for mi = 1:numel(methods)
    idx = find(total_tbl(:, 2) == mi);
    plot(total_tbl(idx, 1), total_tbl(idx, 3) * 1e3, ['-' cols{mi}], ...
         'LineWidth', 1.5); hold on; grid on;
end
xlabel('s'); ylabel('total time (ms)');
legend(methods{:}, 'Location', 'best');
title('Sketch-and-solve timing: total');

% --- Plot: sketch formation time vs s ---
figure;
for mi = 1:numel(methods)
    idx = find(sketch_tbl(:, 2) == mi);
    plot(sketch_tbl(idx, 1), sketch_tbl(idx, 3) * 1e3, ['-' cols{mi}], ...
         'LineWidth', 1.5); hold on; grid on;
end
xlabel('s'); ylabel('sketch formation time (ms)');
legend(methods{:}, 'Location', 'best');
title('Sketch-and-solve timing: sketch formation');

% --- Plot: solve time vs s ---
figure;
for mi = 1:numel(methods)
    idx = find(sketch_tbl(:, 2) == mi);
    plot(sketch_tbl(idx, 1), sketch_tbl(idx, 4) * 1e3, ['-' cols{mi}], ...
         'LineWidth', 1.5); hold on; grid on;
end
xlabel('s'); ylabel('solve time (ms)');
legend(methods{:}, 'Location', 'best');
title('Sketch-and-solve timing: reduced system solve');

function idx = mi_lookup(method, methods)
    idx = find(strcmpi(methods, method));
end

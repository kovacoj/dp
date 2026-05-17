% Driver script for Experiment 5: iterative refinement recovery from
% low-precision sketch formation.

clear; clc;

n = 256; d = 10; s = 40; trials = 10;
x_true = ones(d, 1);

% Generate a well-conditioned problem
kappa = 1e2;
A = generate_conditional(n, d, kappa, 'logspace');
b = A * x_true;
x_ref = A \ b;
ref_res = norm(A * x_ref - b);

prec_configs = {
    'double',  'double',  'double';
    'single',  'double',  'double';
    'half',    'double',  'double';
    'bfloat16','double',  'double';
    'half',    'double',  'single';
};

ref_steps_max = 5;

fprintf('%-10s %-10s %-10s |', 'sketch', 'solve', 'ref_prec');
for k = 0:ref_steps_max
    fprintf(' step%d', k);
end
fprintf('\n');

for ci = 1:size(prec_configs, 1)
    sp = prec_configs{ci, 1};
    sv = prec_configs{ci, 2};
    rp = prec_configs{ci, 3};

    avg_res = zeros(trials, ref_steps_max + 1);

    for j = 1:trials
        r = iterative_refine(A, b, s, ...
            'method', 'gaussian', ...
            'sketch_prec', sp, ...
            'solve_prec', sv, ...
            'ref_prec', rp, ...
            'ref_steps', ref_steps_max);

        for k = 0:ref_steps_max
            avg_res(j, k + 1) = r.ref_history(k + 1, 2) / ref_res;
        end
    end

    fprintf('%-10s %-10s %-10s |', sp, sv, rp);
    for k = 0:ref_steps_max
        fprintf(' %8.2e', mean(avg_res(:, k + 1)));
    end
    fprintf('\n');
end

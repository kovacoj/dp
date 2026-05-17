% Driver script for Experiment 4: conditioning vs sketch quality and precision.
% Sweeps over prescribed condition numbers and measures how sketch accuracy
% and mixed-precision safety degrade.

clear; clc;

n = 1024; d = 20; s = 100; trials = 10;
kappa_vals = [1e2, 1e4, 1e6, 1e8];
modes = {'logspace', 'twocluster'};

x_true = ones(d, 1);

for mi = 1:numel(modes)
    mode = modes{mi};
    fprintf('=== mode: %s ===\n', mode);

    for ki = 1:numel(kappa_vals)
        kappa = kappa_vals(ki);

        % --- Double-precision sketch ---
        res_d = zeros(trials, 1);
        sol_d = zeros(trials, 1);
        cond_d = zeros(trials, 1);
        for j = 1:trials
            A = generate_conditional(n, d, kappa, mode);
            b = A * x_true;
            x_ref = A \ b;
            ref_res = norm(A * x_ref - b);
            ref_norm = norm(x_ref);

            S = randn(s, n) / sqrt(s);
            SA = S * A;
            Sb = S * b;
            xhat = SA \ Sb;

            res_d(j) = norm(A * xhat - b) / ref_res;
            sol_d(j) = norm(xhat - x_ref) / ref_norm;
            cond_d(j) = cond(SA);
        end

        % --- Single-precision sketch formation ---
        res_s = zeros(trials, 1);
        sol_s = zeros(trials, 1);
        cond_s = zeros(trials, 1);
        for j = 1:trials
            A = generate_conditional(n, d, kappa, mode);
            b = A * x_true;
            x_ref = A \ b;
            ref_res = norm(A * x_ref - b);
            ref_norm = norm(x_ref);

            S = fl_round(randn(s, n) / sqrt(s), 'single');
            SA = fl_round(S * A, 'single');
            Sb = fl_round(S * b, 'single');
            xhat = SA \ Sb;

            res_s(j) = norm(A * xhat - b) / ref_res;
            sol_s(j) = norm(xhat - x_ref) / ref_norm;
            cond_s(j) = cond(double(SA));
        end

        % --- Half-precision sketch formation ---
        res_h = zeros(trials, 1);
        sol_h = zeros(trials, 1);
        cond_h = zeros(trials, 1);
        for j = 1:trials
            A = generate_conditional(n, d, kappa, mode);
            b = A * x_true;
            x_ref = A \ b;
            ref_res = norm(A * x_ref - b);
            ref_norm = norm(x_ref);

            S = fl_round(randn(s, n) / sqrt(s), 'half');
            SA = fl_round(S * A, 'half');
            Sb = fl_round(S * b, 'half');
            xhat = double(SA) \ double(Sb);

            res_h(j) = norm(A * xhat - b) / ref_res;
            sol_h(j) = norm(xhat - x_ref) / ref_norm;
            cond_h(j) = cond(double(SA));
        end

        fprintf('kappa=%8.0e  | double: res=%8.2e sol=%8.2e kappa_SA=%8.2e | single: res=%8.2e sol=%8.2e kappa_SA=%8.2e | half: res=%8.2e sol=%8.2e kappa_SA=%8.2e\n', ...
            kappa, mean(res_d), mean(sol_d), mean(cond_d), ...
            mean(res_s), mean(sol_s), mean(cond_s), ...
            mean(res_h), mean(sol_h), mean(cond_h));
    end
end

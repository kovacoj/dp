% Driver script for mixed-precision sketched least-squares experiments.
% Compares double-precision baseline with single- and half-precision
% sketch formation, and with single-precision solve.

clear; clc;

n = 128; d = 10; s_vals = 20:10:120; trials = 10;

% --- Double-precision baseline ---
r_double = mixedprec_experiment('n', n, 'd', d, 's_vals', s_vals, ...
    'trials', trials, 'method', 'gaussian', ...
    'sketch_prec', 'double', 'solve_prec', 'double');

% --- Single-precision sketch formation ---
r_single = mixedprec_experiment('n', n, 'd', d, 's_vals', s_vals, ...
    'trials', trials, 'method', 'gaussian', ...
    'sketch_prec', 'single', 'solve_prec', 'double');

% --- Half-precision sketch formation ---
r_half = mixedprec_experiment('n', n, 'd', d, 's_vals', s_vals, ...
    'trials', trials, 'method', 'gaussian', ...
    'sketch_prec', 'half', 'solve_prec', 'double');

% --- Single-precision solve ---
r_solvesingle = mixedprec_experiment('n', n, 'd', d, 's_vals', s_vals, ...
    'trials', trials, 'method', 'gaussian', ...
    'sketch_prec', 'double', 'solve_prec', 'single');

% --- Mean absolute error ---
figure;
semilogy(s_vals, r_double.history(:,2), '-o', 'LineWidth', 1.5); hold on; grid on;
semilogy(s_vals, r_single.history(:,2), '-s', 'LineWidth', 1.5);
semilogy(s_vals, r_half.history(:,2), '-d', 'LineWidth', 1.5);
semilogy(s_vals, r_solvesingle.history(:,2), '-^', 'LineWidth', 1.5);
xline(2*(d+1), '--k');
xlabel('s'); ylabel('mean(|xhat\_mean - x|)');
legend('double/double', 'single/double', 'half/double', 'double/single', 'Location', 'best');
title('Mixed-precision sketched LS: mean absolute error');

% --- Residual ratio ---
figure;
semilogy(s_vals, r_double.history(:,3), '-o', 'LineWidth', 1.5); hold on; grid on;
semilogy(s_vals, r_single.history(:,3), '-s', 'LineWidth', 1.5);
semilogy(s_vals, r_half.history(:,3), '-d', 'LineWidth', 1.5);
semilogy(s_vals, r_solvesingle.history(:,3), '-^', 'LineWidth', 1.5);
xline(2*(d+1), '--k');
xlabel('s'); ylabel('mean residual ratio');
legend('double/double', 'single/double', 'half/double', 'double/single', 'Location', 'best');
title('Mixed-precision sketched LS: residual ratio');

% --- Solution error ---
figure;
semilogy(s_vals, r_double.history(:,4), '-o', 'LineWidth', 1.5); hold on; grid on;
semilogy(s_vals, r_single.history(:,4), '-s', 'LineWidth', 1.5);
semilogy(s_vals, r_half.history(:,4), '-d', 'LineWidth', 1.5);
semilogy(s_vals, r_solvesingle.history(:,4), '-^', 'LineWidth', 1.5);
xline(2*(d+1), '--k');
xlabel('s'); ylabel('mean relative solution error');
legend('double/double', 'single/double', 'half/double', 'double/single', 'Location', 'best');
title('Mixed-precision sketched LS: solution error');

% --- Conditioning ---
figure;
semilogy(s_vals, r_double.history(:,5), '-o', 'LineWidth', 1.5); hold on; grid on;
semilogy(s_vals, r_single.history(:,5), '-s', 'LineWidth', 1.5);
semilogy(s_vals, r_half.history(:,5), '-d', 'LineWidth', 1.5);
semilogy(s_vals, r_solvesingle.history(:,5), '-^', 'LineWidth', 1.5);
xline(2*(d+1), '--k');
xlabel('s'); ylabel('mean \kappa(SA)');
legend('double/double', 'single/double', 'half/double', 'double/single', 'Location', 'best');
title('Mixed-precision sketched LS: conditioning');

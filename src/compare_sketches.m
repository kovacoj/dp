% Driver script comparing Gaussian, Rademacher, and SRHT sketched least squares.
% Uses sketch_experiment for all three methods with identical problem data
% (same random seed per method) and plots results on shared axes.

clear; clc;

n = 128; d = 10; s_vals = 20:10:120; trials = 10;

r_gauss = sketch_experiment('n', n, 'd', d, 's_vals', s_vals, ...
    'trials', trials, 'method', 'gaussian');

r_rad = sketch_experiment('n', n, 'd', d, 's_vals', s_vals, ...
    'trials', trials, 'method', 'rademacher');

r_srht = sketch_experiment('n', n, 'd', d, 's_vals', s_vals, ...
    'trials', trials, 'method', 'srht');

% --- Mean absolute error ---
figure;
semilogy(s_vals, r_gauss.history(:,2), '-o', 'LineWidth', 1.5); hold on; grid on;
semilogy(s_vals, r_rad.history(:,2), '-s', 'LineWidth', 1.5);
semilogy(s_vals, r_srht.history(:,2), '-d', 'LineWidth', 1.5);
xline(2*(d+1), '--k');
xlabel('s'); ylabel('mean(|xhat\_mean - x|)');
legend('Gaussian', 'Rademacher', 'SRHT', 'Location', 'best');
title('Sketch comparison: mean absolute error');

% --- Residual ratio ---
figure;
semilogy(s_vals, r_gauss.history(:,3), '-o', 'LineWidth', 1.5); hold on; grid on;
semilogy(s_vals, r_rad.history(:,3), '-s', 'LineWidth', 1.5);
semilogy(s_vals, r_srht.history(:,3), '-d', 'LineWidth', 1.5);
xline(2*(d+1), '--k');
xlabel('s'); ylabel('mean residual ratio');
legend('Gaussian', 'Rademacher', 'SRHT', 'Location', 'best');
title('Sketch comparison: residual ratio');

% --- Solution error ---
figure;
semilogy(s_vals, r_gauss.history(:,4), '-o', 'LineWidth', 1.5); hold on; grid on;
semilogy(s_vals, r_rad.history(:,4), '-s', 'LineWidth', 1.5);
semilogy(s_vals, r_srht.history(:,4), '-d', 'LineWidth', 1.5);
xline(2*(d+1), '--k');
xlabel('s'); ylabel('mean relative solution error');
legend('Gaussian', 'Rademacher', 'SRHT', 'Location', 'best');
title('Sketch comparison: solution error');

% --- Conditioning ---
figure;
semilogy(s_vals, r_gauss.cond_history(:,2), '-o', 'LineWidth', 1.5); hold on; grid on;
semilogy(s_vals, r_rad.cond_history(:,2), '-s', 'LineWidth', 1.5);
semilogy(s_vals, r_srht.cond_history(:,2), '-d', 'LineWidth', 1.5);
xline(2*(d+1), '--k');
xlabel('s'); ylabel('mean \kappa(SA)');
legend('Gaussian', 'Rademacher', 'SRHT', 'Location', 'best');
title('Sketch comparison: conditioning of the sketched system');

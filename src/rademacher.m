% Driver script for the Rademacher sketched least-squares experiment.

clear; clc;

result = rademacher_experiment('n', 128, 'd', 10, 's_vals', 20:10:120, 'trials', 10);
history = result.history;

figure;
semilogy(history(:, 1), history(:, 2), 'LineWidth', 1.5); grid on; hold on;
xline(2 * (result.options.d + 1), '--k');
xlabel('s'); ylabel('mean(|xhat\_mean - x|)');
title('Rademacher sketched least squares: mean absolute error');

figure;
semilogy(history(:, 1), history(:, 3), 'LineWidth', 1.5); grid on; hold on;
xline(2 * (result.options.d + 1), '--k');
xlabel('s'); ylabel('mean relative residual');
title('Rademacher sketched least squares: residual ratio');

figure;
semilogy(result.cond_history(:, 1), result.cond_history(:, 2), 'LineWidth', 1.5); grid on; hold on;
xline(2 * (result.options.d + 1), '--k');
xlabel('s'); ylabel('mean \kappa(SA)');
title('Rademacher sketched least squares: conditioning of the sketched system');

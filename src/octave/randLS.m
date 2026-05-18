% Driver script for the Gaussian sketched least-squares experiment.

clear; clc;

this_dir = fileparts(mfilename('fullpath'));
if ~isempty(this_dir)
    addpath(this_dir);
end

result = randLS_experiment();
history = result.history;

figure;
semilogy(history(:, 1), history(:, 2), 'LineWidth', 1.5); grid on; hold on;
xline(2 * (result.options.d + 1), '--k');
xlabel('s'); ylabel('mean(|xhat\_mean - x|)');

if result.use_symbolic
    title('Randomized least squares: mean absolute error (symbolic/high precision)');
else
    title('Randomized least squares: mean absolute error (double precision)');
end

figure;
semilogy(history(:, 1), history(:, 3), 'LineWidth', 1.5); grid on; hold on;
xline(2 * (result.options.d + 1), '--k');
xlabel('s'); ylabel('mean relative residual');
title('Randomized least squares: residual ratio');

figure;
semilogy(result.cond_history(:, 1), result.cond_history(:, 2), 'LineWidth', 1.5); grid on; hold on;
xline(2 * (result.options.d + 1), '--k');
xlabel('s'); ylabel('mean \kappa(SA)');
title('Randomized least squares: conditioning of the sketched system');

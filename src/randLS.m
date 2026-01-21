% Randomized LS in MATLAB with higher precision (Symbolic Math Toolbox)
clear; clc;

digits(30);                 % increase precision (adjust as needed)
rng(0);

n = 100;
d = 10;

A = vpa(randn(n,d));
x = vpa(ones(d,1));
b = A*x;

k = 1e1;

s_vals = 1:(n-1);
history = zeros(numel(s_vals), 2);

for ii = 1:numel(s_vals)
    s = s_vals(ii);

    xhat_sum = vpa(zeros(d,1));
    inv_sqrt_s = 1/sqrt(vpa(s));

    for j = 1:k
        S  = vpa(randn(s,n)) * inv_sqrt_s;   % N(0, 1/s)
        As = S*A;
        bs = S*b;

        % least-squares solution of min ||As*x - bs||_2
        xhat = As \ bs;                      % tall system => LS via QR internally
        xhat_sum = xhat_sum + xhat;
    end

    xhat_mean = xhat_sum / vpa(k);
    err = mean(abs(xhat_mean - x));         % mean absolute error across coordinates

    history(ii,:) = [double(s), double(err)];  % convert for plotting
end

semilogy(history(:,1), history(:,2), 'LineWidth', 1.5); grid on; hold on;
xline(2*(d+1), '--k');
xlabel('s'); ylabel('mean(|xhat\_mean - x|)');
title('Randomized least squares: error vs sketch size s');

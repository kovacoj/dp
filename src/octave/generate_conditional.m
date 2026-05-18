function A = generate_conditional(n, d, kappa, mode)
%GENERATE_CONDITIONAL Random matrix with prescribed condition number.
%
%   A = GENERATE_CONDITIONAL(N, D, KAPPA) returns an N-by-D matrix with
%   singular values logarithmically spaced between 1 and KAPPA.
%
%   A = GENERATE_CONDITIONAL(N, D, KAPPA, MODE) selects the singular
%   value distribution:
%     'logspace'  - logarithmically spaced between 1 and KAPPA (default)
%     'geomspace' - same as 'logspace'
%     'twocluster'- d-1 singular values equal 1, one equal to KAPPA
%     'linspace'  - linearly spaced between 1 and KAPPA
%     'random'    - log-uniform random between 1 and KAPPA
%
%   The resulting matrix satisfies KAPPA_2(A) = KAPPA exactly for the
%   logspace/geomspace/twocluster modes, and approximately for random.

    if (nargin < 4)
        mode = 'logspace';
    end

    r = min(n, d);

    switch lower(mode)
        case {'logspace', 'geomspace'}
            if (r == 1)
                sv = kappa;
            else
                sv = logspace(0, log10(kappa), r);
            end
        case 'twocluster'
            sv = [ones(1, r - 1), kappa];
        case 'linspace'
            if (r == 1)
                sv = kappa;
            else
                sv = linspace(1, kappa, r);
            end
        case 'random'
            sv = 10.^(log10(kappa) * rand(1, r));
            sv = sort(sv, 'ascend');
            sv(1) = 1;
            sv(end) = kappa;
        otherwise
            error('Unknown mode: %s', mode);
    end

    [U_q, ~] = qr(randn(n, r));
    [V_q, ~] = qr(randn(d, r));
    U = U_q(:, 1:r);
    V = V_q(:, 1:r);

    A = U * diag(sv) * V';
end

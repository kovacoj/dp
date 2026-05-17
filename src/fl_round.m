function y = fl_round(x, prec)
%FL_ROUND Simulate reduced-precision rounding.
%
%   Y = FL_ROUND(X, PREC) rounds X to the nearest representable value
%   in the specified precision.  PREC is a string:
%     'double'  - no rounding (return X unchanged)
%     'single'  - round to IEEE 754 single precision (24-bit significand)
%     'half'    - round to IEEE 754 half precision  (11-bit significand)
%     'bfloat16'- round to bfloat16                 (8-bit significand)
%
%   The implementation uses the identity  fl(x) = float( int(x / 2^e) * 2^e )
%   applied to the significand bits, which is independent of the exponent
%   and therefore works element-wise on arrays.

    if (nargin < 2) || strcmpi(prec, 'double')
        y = x;
        return;
    end

    prec = lower(prec);

    switch prec
        case 'single'
            sig_bits = 24;
        case 'half'
            sig_bits = 11;
        case 'bfloat16'
            sig_bits = 8;
        otherwise
            error('fl_round:unknown', ...
                'Unknown precision ''%s''. Use double, single, half, or bfloat16.', prec);
    end

    y = x;

    idx = (x ~= 0);
    if ~any(idx(:))
        return;
    end

    abs_x = abs(x(idx));
    e = floor(log2(abs_x));

    scale = 2.^(sig_bits - 1 - e);
    rounded = round(abs_x .* scale) ./ scale;

    y(idx) = sign(x(idx)) .* rounded;
end

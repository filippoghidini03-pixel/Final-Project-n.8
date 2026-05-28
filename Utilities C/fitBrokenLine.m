function [tau_star, L_star] = fitBrokenLine(T, s)
%
% INPUTS:
%   T        - Vector of bond residual maturities/expiries [n x 1]. 
%              Must be sorted in strictly ascending order.
%   s        - Vector of observed spreads  [n x 1] 
%              corresponding to the maturities in T.
%
% OUTPUTS:
%   tau_star - The optimal breakpoint that minimizes the 
%              overall residual sum of squares.
%   L_star   - The minimum residual sum of squares achieved at tau_star.
%

% Force column vectors 
T = T(:);
s = s(:);
n = length(T);

tau_candidates = inf(n, 1);
L_candidates   = inf(n, 1);
L_min          = inf;

for k = 3 : n-3
    % Independent OLS on left segment [1..k] and right segment [k+1..n]
    XL = [ones(k,   1), T(1:k)];
    XR = [ones(n-k, 1), T(k+1:end)];

    bL = XL \ s(1:k);
    bR = XR \ s(k+1:end);

    Lk = sum((s(1:k)     - XL*bL).^2) + sum((s(k+1:end) - XR*bR).^2);

    % Skip if not a new minimum 
    if Lk >= L_min 
        continue; 
    end

    % Check if the two lines intersect inside [T(k), T(k+1))
    a1 = bL(1); b1 = bL(2);
    a2 = bR(1); b2 = bR(2);

    if abs(b1 - b2) > 1e-10
        tau_int = (a2 - a1) / (b1 - b2);
        if tau_int >= T(k) && tau_int < T(k+1)
            tau_candidates(k) = tau_int;
            L_candidates(k)   = Lk;
            L_min             = Lk;
            continue;
        end
    end

    % Constrained fit: continuous piecewise linear f(x) = a + b*x + c*(x-tau0)+
    XcL = [ones(n,1), T, max(T - T(k),   0)];
    XcR = [ones(n,1), T, max(T - T(k+1), 0)];

    LL = sum((s - XcL*(XcL\s)).^2);
    LR = sum((s - XcR*(XcR\s)).^2);

    if LL <= LR
        tau_candidates(k) = T(k);
        L_candidates(k)   = LL;
    else
        tau_candidates(k) = T(k+1);
        L_candidates(k)   = LR;
    end

    L_min = min(L_min, L_candidates(k));
end

[L_star, k_star] = min(L_candidates);
tau_star = tau_candidates(k_star);

% If no valid breakpoint was found (all candidates stayed at Inf),
% return NaN so the caller can identify and skip this day.
if isinf(tau_star)
    tau_star = NaN;
    L_star   = NaN;
end

end
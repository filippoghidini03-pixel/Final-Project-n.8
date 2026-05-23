function [tau_star, L_star] = fitBrokenLine(T, s)
% Segmented regression with one breakpoint 
% T : expiries (sorted ascending) [n x 1]
% s : ASW spreads                 [n x 1]
% tau_star : optimal breakpoint
% L_star   : minimum residual sum of squares

n = length(T);

tau_candidates = inf(n, 1);
L_candidates   = inf(n, 1);
L_min          = inf;   % running minimum

for k = 3 : n-3

    % --- Independent OLS on left and right segments ---
    XL = [ones(k,   1), T(1:k)];
    XR = [ones(n-k, 1), T(k+1:end)];

    bL = XL \ s(1:k);
    bR = XR \ s(k+1:end);

    RSS_L = sum((s(1:k)     - XL*bL).^2);
    RSS_R = sum((s(k+1:end) - XR*bR).^2);
    Lk    = RSS_L + RSS_R;

    % Skip if not a new minimum (footnote 16)
    if Lk >= L_min
        continue;
    end

    % --- Check if the two lines intersect at a unique point ---
    a1 = bL(1); b1 = bL(2);
    a2 = bR(1); b2 = bR(2);

    if abs(b1 - b2) > 1e-10
        tau_int = (a2 - a1) / (b1 - b2);

        if tau_int >= T(k) && tau_int < T(k+1)
            % Intersection falls inside [T(k), T(k+1)): use it directly
            tau_candidates(k) = tau_int;
            L_candidates(k)   = Lk;
            L_min = Lk;
            continue;
        end
    end

    % --- Constrained fit: continuous piecewise linear at T(k) ---
    Xc = [ones(n,1), T, max(T - T(k), 0)];
    LL = sum((s - Xc*(Xc\s)).^2);

    % --- Constrained fit: continuous piecewise linear at T(k+1) ---
    Xc = [ones(n,1), T, max(T - T(k+1), 0)];
    LR = sum((s - Xc*(Xc\s)).^2);

    % Keep the better constrained fit
    if LL <= LR
        tau_candidates(k) = T(k);
        L_candidates(k)   = LL;
    else
        tau_candidates(k) = T(k+1);
        L_candidates(k)   = LR;
    end

    L_min = min(L_min, L_candidates(k));
end

% --- Select optimal k* ---
[L_star, k_star] = min(L_candidates);
tau_star = tau_candidates(k_star);

end
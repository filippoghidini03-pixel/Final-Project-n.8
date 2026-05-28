function [slopeSign, spread10y] = computeSlopeAndSpread(SpreadsFilt, datesFilt, tau_star)

nDays     = length(SpreadsFilt);
slopeSign = ones(nDays, 1);
spread10y = nan(nDays, 1);

for i = 1:nDays
    if isnan(tau_star(i)) || isinf(tau_star(i)), continue; end

    T_dates = SpreadsFilt(i).ExpiryDates(:);
    s       = SpreadsFilt(i).ASWSpreads(:);
    tau     = (T_dates - datesFilt(i)) / 365.25;

    [tau, idx] = sort(tau);
    s  = s(idx);
    ts = tau_star(i);

    left  = tau <= ts;
    right = tau >  ts;

    if sum(left) >= 2 && sum(right) >= 2
        pL = polyfit(tau(left),  s(left),  1);
        pR = polyfit(tau(right), s(right), 1);
    else
        pL = polyfit(tau, s, 1);
        pR = pL;
        ts = tau(end);
    end

    % Evaluate at 10y but do not extrapolate beyond available data
    eval_point = min(10, max(tau));

    if eval_point <= ts
        spread10y(i) = polyval(pL, eval_point);
    else
        spread10y(i) = polyval(pR, eval_point);
    end

    % Slope sign: inverted if s(0.5y) > s(10y)
    if 0.5 <= ts
        s_short = polyval(pL, 0.5);
    else
        s_short = polyval(pR, 0.5);
    end

    if s_short > spread10y(i)
        slopeSign(i) = -1;
    end
end
end
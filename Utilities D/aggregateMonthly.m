function [months, slope_out, time_out, spread_out] = aggregateMonthly(eon_t0, Spreads)
%AGGREGATEMONTHLY  For each calendar month, runs fitBrokenLine on each day.
%
%  Inversion detection: compare the fitted broken line evaluated at 0.5y
%  vs 10y. If s(0.5y) > s(10y) the curve is inverted -> dailySlope = -1.

dv      = datevec(eon_t0);
yearMon = dv(:,1)*100 + dv(:,2);
uMonths = unique(yearMon);
M       = length(uMonths);

months     = zeros(M, 1);
time_out   = zeros(M, 1);
slope_out  = struct('dailySign', cell(M,1));
spread_out = struct('mean', cell(M,1), 'startVal', cell(M,1), 'endVal', cell(M,1));

for m = 1 : M
    idx   = find(yearMon == uMonths(m));
    nDays = length(idx);
    months(m) = datenum(floor(uMonths(m)/100), mod(uMonths(m),100), 1);

    daily10y   = NaN(nDays, 1);
    dailySlope = ones(nDays, 1);
    dailyTau   = NaN(nDays, 1);

    for di = 1 : nDays
        ii = idx(di);
        T  = Spreads(ii).ExpiryDates;
        s  = Spreads(ii).ASWSpreads;
        if isempty(T) || isempty(s), continue; end

        t0  = eon_t0(ii);
        tau = (T - t0) / 365;

        [tau, isrt] = sort(tau);
        s = s(isrt);

        if length(tau) < 6, continue; end

        % --- Broken-line fit -> tau_star ---
        [tau_d, ~] = fitBrokenLine(tau, s);
        if ~isinf(tau_d) && ~isnan(tau_d)
            dailyTau(di) = tau_d;
        end

        % --- Fit two segments for evaluation ---
        if ~isinf(tau_d) && ~isnan(tau_d) && ...
           sum(tau <= tau_d) >= 2 && sum(tau > tau_d) >= 2
            left  = tau <= tau_d;
            right = tau >  tau_d;
            pL = polyfit(tau(left),  s(left),  1);
            pR = polyfit(tau(right), s(right), 1);
        else
            pL = polyfit(tau, s, 1);
            pR = pL;
            tau_d = tau(end);
        end

        % Evaluate broken line at 0.5y and 10y
        if 0.5 <= tau_d
            s_short = polyval(pL, 0.5);
        else
            s_short = polyval(pR, 0.5);
        end
        if 10 <= tau_d
            s_long = polyval(pL, 10);
        else
            s_long = polyval(pR, 10);
        end

        daily10y(di) = s_long;

        % Inverted if short-end spread exceeds long-end spread
        if s_short > s_long
            dailySlope(di) = -1;
        else
            dailySlope(di) = +1;
        end
    end

    % --- Monthly aggregates ---
    valid10y = daily10y(~isnan(daily10y));
    if isempty(valid10y)
        sp_mean = 0; sp_start = 0; sp_end = 0;
    else
        sp_mean  = mean(valid10y);
        sp_start = valid10y(1);
        sp_end   = valid10y(end);
    end
    spread_out(m).mean     = sp_mean;
    spread_out(m).startVal = sp_start;
    spread_out(m).endVal   = sp_end;

    slope_out(m).dailySign = dailySlope;

    validTau = dailyTau(~isnan(dailyTau));
    if isempty(validTau)
        time_out(m) = NaN;
    else
        time_out(m) = mean(validTau);
    end
end
end
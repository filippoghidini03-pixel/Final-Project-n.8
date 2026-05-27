function [months, slope_out, time_out, spread_out] = aggregateMonthly(eon_t0, Spreads)
% For every calendar month in the dataset:
%   1. Collect all daily (tau, ASW) pairs.
%   2. Compute daily slope sign = sign of left-segment slope from fitBrokenLine.
%      Negative slope = inverted curve = potential Red signal (Baviera-Lebovitz).
%   3. Run fitBrokenLine on the full month pool -> monthly tau_star.
%   4. Compute monthly 10y-spread statistics for computeFSI.
 
dv      = datevec(eon_t0);
yearMon = dv(:,1)*100 + dv(:,2);
uMonths = unique(yearMon);
M       = length(uMonths);
 
months     = zeros(M, 1);
time_out   = zeros(M, 1);
slope_out  = struct('dailySign', cell(M,1));
spread_out = struct('mean', cell(M,1), 'startVal', cell(M,1), 'endVal', cell(M,1));
 
for m = 1 : M
    idx = find(yearMon == uMonths(m));
    months(m) = datenum(floor(uMonths(m)/100), mod(uMonths(m),100), 1);
 
    nDays      = length(idx);
    T_all      = [];
    s_all      = [];
    daily10y   = NaN(nDays, 1);
    dailySlope = ones(nDays, 1);   % default: positive (non-inverted)
 
    for di = 1 : nDays
        ii  = idx(di);
        T   = Spreads(ii).ExpiryDates;
        s   = Spreads(ii).ASWSpreads;
        if isempty(T) || isempty(s), continue; end
 
        t0  = eon_t0(ii);
        tau = (T - t0) / 365;   % years to expiry
 
        % Sort by tau (required by fitBrokenLine)
        [tau, isrt] = sort(tau);
        s = s(isrt);
 
        T_all = [T_all; tau];   %#ok<AGROW>
        s_all = [s_all; s];     %#ok<AGROW>
 
        % 10y spread proxy: bond closest to 10y maturity
        [~, i10]     = min(abs(tau - 10));
        daily10y(di) = s(i10);
 
        % --- Daily slope sign (key for Red detection) ---
        % Fit broken line; sign of left-segment slope signals curve inversion.
        % Negative left slope = short-end spreads > long-end = inverted curve.
        if length(tau) >= 6
            [tau_d, ~] = fitBrokenLine(tau, s);
            if ~isinf(tau_d) && ~isnan(tau_d)
                left  = tau <= tau_d;
                right = tau >  tau_d;
                if sum(left) >= 2 && sum(right) >= 2
                    pL = polyfit(tau(left), s(left), 1);
                    dailySlope(di) = sign(pL(1));
                else
                    % Breakpoint at an extreme: use global slope
                    pg = polyfit(tau, s, 1);
                    dailySlope(di) = sign(pg(1));
                end
            else
                % No valid breakpoint: use global slope
                pg = polyfit(tau, s, 1);
                dailySlope(di) = sign(pg(1));
            end
        end
    end
 
    % Monthly 10y spread statistics (ignore NaN days with no bonds)
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
 
    % Monthly tau_star: fitBrokenLine on the full month pool
    if length(T_all) >= 6
        [tau_star, ~] = fitBrokenLine(T_all, s_all);
        time_out(m)   = tau_star;
    else
        time_out(m) = NaN;
    end
end
end
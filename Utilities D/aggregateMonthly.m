function [months, slope_out, time_out, spread_out] = aggregateMonthly(eon_t0, Spreads)
% For every calendar month in the dataset:
%   1. Collect all daily ASW spreads (all bonds, all days in that month).
%   2. Run fitBrokenLine -> tau_star (time-to-slope-change) and slope.
%   3. Build the structs consumed by computeFSI.
% runs fitbrokenline on each month and builds the structs expected by
% computeFSI / compute eurofsi

nDates = length(eon_t0);

% Identify unique months
dv       = datevec(eon_t0);
yearMon  = dv(:,1)*100 + dv(:,2);
uMonths  = unique(yearMon);
M        = length(uMonths);

months     = zeros(M, 1);
time_out   = zeros(M, 1);
slope_out  = struct('dailySign', cell(M,1));
spread_out = struct('mean', cell(M,1), 'startVal', cell(M,1), 'endVal', cell(M,1));

for m = 1 : M
    idx = find(yearMon == uMonths(m));

    % First day of this month as reference date
    months(m) = datenum(floor(uMonths(m)/100), mod(uMonths(m),100), 1);

    % Collect all (expiry, ASW) pairs for every day in the month
    T_all = [];
    s_all = [];
    daily10y  = zeros(length(idx), 1);  % 10y spread proxy per day
    dailySlope = zeros(length(idx), 1); % slope sign per day

    for di = 1 : length(idx)
        ii = idx(di);
        T  = Spreads(ii).ExpiryDates;
        s  = Spreads(ii).ASWSpreads;
        if isempty(T) || isempty(s), continue; end

        t0 = eon_t0(ii);
        tau = (T - t0) / 365;  % years to expiry

        T_all = [T_all; tau];   %#ok<AGROW>
        s_all = [s_all; s];     %#ok<AGROW>

        % 10y spread proxy: ASW of the bond closest to 10y
        [~, i10] = min(abs(tau - 10));
        daily10y(di) = s(i10);

        % Daily slope sign: from the broken-line fit on that single day
        if length(T) >= 6
            [tau_d, ~] = fitBrokenLine(tau, s);
            % Slope before breakpoint: positive if ASW rises toward tau_star
            left_mask = tau <= tau_d;
            if sum(left_mask) >= 2 && sum(~left_mask) >= 2
                p = polyfit(tau(left_mask), s(left_mask), 1);
                dailySlope(di) = sign(p(1));
            else
                dailySlope(di) = 1;  % default positive
            end
        else
            dailySlope(di) = 1;
        end
    end

    % Monthly mean 10y spread
    sp_mean = mean(daily10y(daily10y ~= 0), 'omitnan');
    if isnan(sp_mean), sp_mean = 0; end

    spread_out(m).mean     = sp_mean;
    spread_out(m).startVal = daily10y(find(daily10y ~= 0, 1, 'first'));
    spread_out(m).endVal   = daily10y(find(daily10y ~= 0, 1, 'last'));
    if isnan(spread_out(m).startVal), spread_out(m).startVal = sp_mean; end
    if isnan(spread_out(m).endVal),   spread_out(m).endVal   = sp_mean; end

    slope_out(m).dailySign = dailySlope;

    % fitBrokenLine on the full month's (tau, s) pool
    if length(T_all) >= 6
        [tau_star, ~] = fitBrokenLine(T_all, s_all);
        time_out(m)   = tau_star;
    else
        time_out(m) = NaN;
    end
end
end
function [months, slope_out, time_out, spread_out] = buildMonthlyIndicators(eon_t0, datesFilt, tau_star, slopeSign, spread10y)
% Maps filtered results to all dates. Quiet months (not in datesFilt)
% get NaN spread → mean=0 → forced Green in computeFSI.

nAll = length(eon_t0);
tau_all       = nan(nAll, 1);
slope_all     = ones(nAll, 1);
spread10y_all = nan(nAll, 1);

[~, loc] = ismember(datesFilt, eon_t0);
tau_all(loc)       = tau_star;
slope_all(loc)     = slopeSign;
spread10y_all(loc) = spread10y;

dv  = datevec(eon_t0);
ym  = dv(:,1)*100 + dv(:,2);
uYM = unique(ym);
M   = length(uYM);

months     = zeros(M, 1);
time_out   = zeros(M, 1);
slope_out  = struct('dailySign', cell(M,1));
spread_out = struct('mean', cell(M,1), 'startVal', cell(M,1), 'endVal', cell(M,1));

for m = 1:M
    idx = (ym == uYM(m));
    months(m)              = datenum(floor(uYM(m)/100), mod(uYM(m),100), 1);
    time_out(m)            = mean(tau_all(idx), 'omitnan');
    slope_out(m).dailySign = slope_all(idx);

    s = spread10y_all(idx);
    s = s(~isnan(s));
    if isempty(s)
        spread_out(m).mean = 0; spread_out(m).startVal = 0; spread_out(m).endVal = 0;
    else
        spread_out(m).mean = mean(s); spread_out(m).startVal = s(1); spread_out(m).endVal = s(end);
    end
end
end
function ai = computeAccrual(dates, firstCpnDate, cpnValue, cpnFreq)
% COMPUTEACCRUAL Accrued interest using native MATLAB yearfrac (30/360).
% Fully vectorized and safe against empty masks.

monthsPerPeriod = 12 / cpnFreq;
settle = dates + 2; % T+2 settlement convention

% 1. Approximate previous and next coupon dates
approxK = floor((settle - firstCpnDate) ./ (365.25 / cpnFreq));
prevCpn = datemnth(firstCpnDate, approxK * monthsPerPeriod);
nextCpn = datemnth(prevCpn, monthsPerPeriod);

% 2. Adjust backward if prevCpn overshot settle
mask = prevCpn > settle;
if any(mask)
    prevCpn(mask) = datemnth(prevCpn(mask), -monthsPerPeriod);
end

% 3. Adjust forward if nextCpn is still before or on settle
mask = nextCpn <= settle;
if any(mask)
    prevCpn(mask) = datemnth(prevCpn(mask), monthsPerPeriod);
end

% 4. Calculate 30/360 European year fraction (Basis = 6)
frac = yearfrac(prevCpn, settle, 6);

% 5. Final accrued interest calculation
ai = cpnValue .* frac;

end
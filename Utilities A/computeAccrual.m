function ai = computeAccrual(dates, firstCpnDate, cpnValue, cpnFreq)
%
% INPUTS:
%   settle       - Settlement dates of the trade 
%   firstCpnDate - Date of the bond's very first coupon 
%   cpnValue     - Annual coupon value 
%   cpnFreq      - Coupon payments per year 
%
% OUTPUT:
%   ai           - Vector of calculated accrued interest values.

monthsPerPeriod = 12 / cpnFreq;
% We have to shift the date 
settle = dates(:) + 2;
wd = weekday(dates(:));
% We have to avoid weekend
settle(wd == 5) = settle(wd == 5) + 2;   
settle(wd == 6) = settle(wd == 6) + 2;   

% Generate coupon dates covering all settle dates.
% We need to ensure coverage in both directions
% relative to the very first coupon date
% We use an approximation for the leap year ( (366 + 3x365 )/4 = 365.25)
kMin = floor((min(settle) - firstCpnDate) / (365.25/cpnFreq)) - 2;
kMax = ceil((max(settle)  - firstCpnDate) / (365.25/cpnFreq)) + 2;

% Create the grid of exact coupon dates
cpnDates = datemnth(firstCpnDate, (kMin:kMax)' * monthsPerPeriod);


% Discretize returns the index 'i' for each settle date such that:
% cpnDates(i) <= settle < cpnDates(i+1)
idx     = discretize(settle, cpnDates);
prevCpn = cpnDates(idx);
nextCpn = cpnDates(idx + 1);

% Accrued interest calculation (Actual/Actual ICMA convention)
ai = (cpnValue / cpnFreq) * (settle - prevCpn) ./ (nextCpn - prevCpn);

end
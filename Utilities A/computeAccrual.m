function ai = computeAccrual(settle, firstCpnDate, cpnValue, cpnFreq)
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
   
% Generate coupon dates covering all settle dates.
% We need to ensure coverage in both directions
% relative to the very first coupon date
kMin = floor(yearfrac(firstCpnDate, min(settle), 2) * cpnFreq) - 2;
kMax = ceil( yearfrac(firstCpnDate, max(settle), 2) * cpnFreq) + 2;

% Create the grid of exact coupon dates
cpnDates = datemnth(firstCpnDate, (kMin:kMax)' * monthsPerPeriod);


% Discretize returns the index 'i' for each settle date such that:
% cpnDates(i) <= settle < cpnDates(i+1)
idx     = discretize(settle, cpnDates);
prevCpn = cpnDates(idx);

% Accrued interest calculation (Actual/360 convention)
ai = cpnValue * yearfrac(prevCpn, settle, 2);

end
function ai = computeAccrual(dates, firstCpnDate, cpnValue, cpnFreq)
% COMPUTEACCRUAL Calculates the accrued interest using the 30/360 European convention.
%
% INPUTS:
%   dates        - Vector of market trade dates (datenum).
%   firstCpnDate - Date of the bond's very first coupon (datenum).
%   cpnValue     - Annual coupon value (e.g., 4 for 4%).
%   cpnFreq      - Coupon payments per year (e.g., 2 for semi-annual).
%
% OUTPUT:
%   ai           - Vector of calculated accrued interest values.

% Apply the T+2 settlement rule. By shifting the dates, some might 
% land on a weekend (1=Sunday, 7=Saturday). If so, we adjust them 
% by adding 2 more days to reach the next business days
settle = dates; % + 2; 
%wd = weekday(settle); 
%settle(wd == 1 | wd == 7) = settle(wd == 1 | wd == 7) + 2;

% Calculate the total time passed since the first coupon and the duration 
% of a single period in years. This allows us to compute the fraction 
% of a year passed since the last coupon
totalYears = yearfrac(firstCpnDate, settle, 6);
periodYears = 1 / cpnFreq;
fracPassed = mod(totalYears, periodYears);

% Actual accrued interest calculation
ai = cpnValue .* fracPassed;

end
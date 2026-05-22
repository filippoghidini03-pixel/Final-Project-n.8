function ai = computeAccrual(dates, firstCpnDate, cpnValue, cpnFreq)
% COMPUTEACCRUAL 30/360 accrued interest calculation with T+2 Business Days and Modulo.

% 1. Calculate T+2 Settlement (skips weekend for Thursday and Friday)
settle = dates + 2; 
wd = weekday(dates); % 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
settle(wd == 5 | wd == 6) = settle(wd == 5 | wd == 6) + 2;

% 2. Extract years, months, and days for 30/360 base
[y1, m1, d1] = datevec(firstCpnDate);
[y2, m2, d2] = datevec(settle);

% European 30/360 rule: cap day 31 to day 30
d1(d1 == 31) = 30;
d2(d2 == 31) = 30;

% 3. TOTAL days passed since the very first coupon
totalDays = 360 .* (y2 - y1) + 30 .* (m2 - m1) + (d2 - d1);

% 4. Days in a single coupon period (e.g., 180 for semi-annual)
periodDays = 360 / cpnFreq;

% 5. Days passed since the LAST coupon (the remainder of the division)
daysPassed = mod(totalDays, periodDays);

% 6. PURE FORMULA: Accrued = Coupon * (Days Passed / 360)
ai = cpnValue .* (daysPassed / 360);

end
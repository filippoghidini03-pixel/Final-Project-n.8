function cpnDates = buildCouponDates(firstCpn, expDate, freq, t0)
%BUILDCOUPONDATES  Generate coupon dates strictly after t0 up to expDate.
%
%   Advances from firstCpn by (12/freq) calendar months using datemnth,
%   consistent with how bootstrapEONIA generates OIS pay dates.
%   The last date is snapped to expDate (standard bond convention).

monthsPer = round(12 / freq);

% Step forward from firstCpn until strictly past t0
d = firstCpn;
while d <= t0
    d = datemnth(d, monthsPer);
end

% Collect all coupon dates up to expiry (3-day tolerance for calendar rounding)
cpnDates = zeros(0, 1);
while d <= expDate + 3
    cpnDates(end+1, 1) = d;  %#ok<AGROW>
    if d >= expDate - 3
        break
    end
    d = datemnth(d, monthsPer);
end

% Snap last date exactly to the bond expiry date
if ~isempty(cpnDates)
    cpnDates(end) = expDate;
end
end

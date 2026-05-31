function d = shiftDate(d, n, type)
%SHIFTDATE  Add business days or calendar months to a date, with Mod-Following.
%
%   d = shiftDate(d, n, 'busdays')  adds n business days (scalar d only)
%   d = shiftDate(d, n, 'months')   adds n calendar months (vectorized),
%                                   then applies Modified Following convention.
%
%   Modified Following: if the resulting date is a weekend, roll to the next
%   Monday. If that Monday falls in the next calendar month, roll back to the
%   preceding Friday instead.
%
%   Extracted from bootstrapEONIA.m for shared use across the project.
%   Identical logic; now callable as a standalone utility.

if strcmp(type, 'busdays')
    % Scalar loop: advance one business day at a time
    for i = 1:n
        d = d + 1;
        wd = weekday(d);
        if wd == 7, d = d + 2; end   % Saturday -> Monday
        if wd == 1, d = d + 1; end   % Sunday   -> Monday
    end

elseif strcmp(type, 'months')
    % Vectorized: add n calendar months then apply Modified Following
    d = datemnth(d, n);
    [~, m0] = datevec(d);          % month of target date (pre-adjustment)
    wd = weekday(d);
    d(wd == 1) = d(wd == 1) + 1;  % Sunday  -> Monday
    d(wd == 7) = d(wd == 7) + 2;  % Saturday -> Monday
    [~, m1] = datevec(d);         % month after adjustment
    d(m0 ~= m1) = d(m0 ~= m1) - 3; % rolled into next month -> back to Friday
end
end

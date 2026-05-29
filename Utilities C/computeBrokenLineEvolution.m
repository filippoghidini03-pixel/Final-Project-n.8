function [tau_star, L_star] = computeBrokenLineEvolution(SpreadsFilt, datesFilt, spreadField)

if nargin < 3, spreadField = 'ASWSpreads'; end

nDays    = length(SpreadsFilt);
tau_star = nan(nDays, 1);
L_star   = nan(nDays, 1);

for i = 1:nDays
    t0      = datesFilt(i);
    T_dates = SpreadsFilt(i).ExpiryDates;
    s       = SpreadsFilt(i).(spreadField);

    tau = (T_dates - t0) / 365.25;

    [tau_sorted, sortIdx] = sort(tau);
    s_sorted = s(sortIdx);

    if length(tau_sorted) >= 7
        [ts, Ls]    = fitBrokenLine(tau_sorted, s_sorted);
        tau_star(i) = ts;
        L_star(i)   = Ls;
    end
end
end
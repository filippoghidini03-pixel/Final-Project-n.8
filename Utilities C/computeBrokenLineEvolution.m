function [tau_star, L_star, dates] = computeBrokenLineEvolution(SpreadsFilt)
% COMPUTEBROKENLINEEVOLUTION Fits the broken line model day-by-day.
%
% INPUT:
%   SpreadsFilt - Filtered structural array from filterMonths.
%
% OUTPUTs:
%   tau_star    - Vector of optimal breakpoints (in years) per day.
%   L_star      - Vector of minimum residual sum of squares per day.
%   dates       - Vector of datenums corresponding to each row.

nDays = length(SpreadsFilt);
dates = [SpreadsFilt.date]';
tau_star = nan(nDays, 1);
L_star   = nan(nDays, 1);

for i = 1:nDays
    t0      = SpreadsFilt(i).date;
    T_dates = SpreadsFilt(i).ExpiryDates;
    s       = SpreadsFilt(i).ASWSpreads;
    
    % Calcolo della vita residua (residual maturity) in anni
    tau = (T_dates - t0) / 365.25; 
    
    % Ordinamento per scadenze crescenti (necessario per fitBrokenLine)
    [tau_sorted, sortIdx] = sort(tau);
    s_sorted = s(sortIdx);
    
    % Verifichiamo di avere abbastanza bond per far girare i segmenti (almeno 7)
    if length(tau_sorted) >= 7
        [ts, Ls] = fitBrokenLine(tau_sorted, s_sorted);
        tau_star(i) = ts;
        L_star(i)   = Ls;
    end
end

end
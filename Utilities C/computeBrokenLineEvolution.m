function [tau_star, L_star] = computeBrokenLineEvolution(SpreadsFilt, datesFilt)
% COMPUTEBROKENLINEEVOLUTION Fits the broken line model day-by-day.
%
% INPUTs:
%   SpreadsFilt - Filtered structural array from filterMonths.
%   datesFilt   - Vector of datenums corresponding to each kept day.
%
% OUTPUTs:
%   tau_star    - Vector of optimal breakpoints (in years) per day.
%   L_star      - Vector of minimum residual sum of squares per day.

nDays = length(SpreadsFilt);
tau_star = nan(nDays, 1);
L_star   = nan(nDays, 1);

for i = 1:nDays
    t0      = datesFilt(i); % Uses the standalone vector directly
    T_dates = SpreadsFilt(i).ExpiryDates;
    s       = SpreadsFilt(i).ASWSpreads;
    
    % Residual maturity in years: Act/365 Fixed (basis=1),
    % consistent with the tau calculation in computeSpreadsForBonds.m.
    tau = yearfrac(t0, T_dates, 1);
    
    % Sort by ascending maturities (required by fitBrokenLine)
    [tau_sorted, sortIdx] = sort(tau);
    s_sorted = s(sortIdx);
    
    % Need at least 6 points: k runs from 3 to n-3, so n>=6 guarantees
    % at least one split with 3 points on each side (as required by the paper).
    if length(tau_sorted) >= 6
        [ts, Ls] = fitBrokenLine(tau_sorted, s_sorted);
        % fitBrokenLine returns NaN when no valid breakpoint exists
        tau_star(i) = ts;
        L_star(i)   = Ls;
    end
end

end
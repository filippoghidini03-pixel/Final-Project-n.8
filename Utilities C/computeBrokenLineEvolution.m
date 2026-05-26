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
    
    % Calculate residual maturity in years
    tau = (T_dates - t0) / 365.25; 
    
    % Sort by ascending maturities (required by fitBrokenLine)
    [tau_sorted, sortIdx] = sort(tau);
    s_sorted = s(sortIdx);
    
    % Check if we have enough bonds to perform the segmented regression (at least 7)
    if length(tau_sorted) >= 7
        [ts, Ls] = fitBrokenLine(tau_sorted, s_sorted);
        tau_star(i) = ts;
        L_star(i)   = Ls;
    end
end

end
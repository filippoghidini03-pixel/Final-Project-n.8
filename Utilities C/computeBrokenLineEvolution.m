function [tau_star, L_star] = computeBrokenLineEvolution(SpreadsFilt, datesFilt, spreadField)
%
%   INPUTS:
%       SpreadsFilt - A struct array containing filtered bond data. 
%                     Must contain the field 'ExpiryDates' and the field 
%                     specified by spreadField.
%       datesFilt   - A numeric vector of evaluation dates 
%                     corresponding to each day in SpreadsFilt.
%       spreadField - (Optional) String or char array specifying the name of 
%                     the field in SpreadsFilt to use for the spread values. 
%                     Default is 'ASWSpreads'.
%
%   OUTPUTS:
%       tau_star    - A column vector of optimal breakpoints 
%                     (in years) for each day. Returns NaN if data is insufficient.
%       L_star      - A column vector of minimum residual sum 
%                     of squares for each day. Returns NaN if data is insufficient.

    if nargin < 3, spreadField = 'ASWSpreads'; end
    
    nDays    = length(SpreadsFilt);
    tau_star = nan(nDays, 1);
    L_star   = nan(nDays, 1);
    
    for i = 1:nDays
        t0      = datesFilt(i);
        T_dates = SpreadsFilt(i).ExpiryDates;
        s       = SpreadsFilt(i).(spreadField);
        
        % Check for the days without bonds
        if isempty(T_dates), continue; end
        
        tau = yearfrac(repmat(t0, size(T_dates)), T_dates, 3);
        
        [tau_sorted, sortIdx] = sort(tau);
        s_sorted = s(sortIdx);
        
        if length(tau_sorted) >= 7
            [ts, Ls]    = fitBrokenLine(tau_sorted, s_sorted);
            tau_star(i) = ts;
            L_star(i)   = Ls;
        end
    end
end
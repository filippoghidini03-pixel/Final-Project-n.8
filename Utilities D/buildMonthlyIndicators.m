function [months, slope_out, time_out, spread_out] = buildMonthlyIndicators(eon_t0, datesFilt, tau_star, slopeSign, spread10y)
%
%   INPUTS:
%       eon_t0    - Complete vector of all daily evaluation dates (datenums).
%       datesFilt - Vector of filtered dates (datenums) that survived the monthly filter.
%       tau_star  - Vector of optimal breakpoints (in years) corresponding to datesFilt.
%       slopeSign - Vector of slope signs (+1 or -1) corresponding to datesFilt.
%       spread10y - Vector of evaluated 10-year spreads corresponding to datesFilt.
%
%   OUTPUTS:
%       months     - Vector (M x 1) of datenums representing the first day of each month.
%       slope_out  - Struct array (M x 1) containing the daily slope signs for each month.
%       time_out   - Vector (M x 1) of the monthly average of the optimal breakpoint (tau*).
%       spread_out - Struct array (M x 1) containing the 'mean', 'startVal', and 
%                    'endVal' of the 10Y spread for each month.

    nAll = length(eon_t0);
    
    % Initialize full-timeline arrays with default values (NaNs or 1 for slope)
    tau_all       = nan(nAll, 1);
    slope_all     = ones(nAll, 1);
    spread10y_all = nan(nAll, 1);
    
    % Map the filtered (stressed) daily results back to their correct positions 
    % in the full timeline
    [~, loc] = ismember(datesFilt, eon_t0);
    tau_all(loc)       = tau_star;
    slope_all(loc)     = slopeSign;
    spread10y_all(loc) = spread10y;
    
    % Extract Year-Month combinations to group days into months
    dv  = datevec(eon_t0);
    ym  = dv(:,1) * 100 + dv(:,2);
    uYM = unique(ym);
    M   = length(uYM);
    
    % Initialize output structures
    months     = zeros(M, 1);
    time_out   = zeros(M, 1);
    slope_out  = struct('dailySign', cell(M,1));
    spread_out = struct('mean', cell(M,1), 'startVal', cell(M,1), 'endVal', cell(M,1));
    
    for m = 1:M
        % Find all days belonging to the current month
        idx = (ym == uYM(m));
        
        % Save the first day of the month as a reference date
        months(m)              = datenum(floor(uYM(m)/100), mod(uYM(m),100), 1);
        
        % Calculate the monthly average of tau* (ignoring NaNs)
        time_out(m)            = mean(tau_all(idx), 'omitnan');
        
        % Store the daily slope signs for the consecutive negative days check
        slope_out(m).dailySign = slope_all(idx);
        
        % Extract the spreads for the current month and remove NaNs
        s = spread10y_all(idx);
        s = s(~isnan(s));
        
        if isempty(s)
            % If the month is empty (it was filtered out as a quiet month),
            % force values to 0 to trigger a Green FSI state later.
            spread_out(m).mean = 0; 
            spread_out(m).startVal = 0; 
            spread_out(m).endVal = 0;
        else
            % Calculate monthly mean, and extract the first and last spread values
            spread_out(m).mean = mean(s); 
            spread_out(m).startVal = s(1); 
            spread_out(m).endVal = s(end);
        end
    end
end
function FSI = computeFSI(months, slope, time, spread)
%
%   INPUTS:
%       months - Vector (M x 1) of datenums representing the evaluated months.
%       slope  - Struct array (M x 1) containing the field 'dailySign' (vector 
%                of +1/-1 indicating the daily slope direction of the spread curve).
%       time   - Vector (M x 1) containing the monthly average of the optimal 
%                breakpoint (tau*) in years.
%       spread - Struct array (M x 1) containing the fields 'mean', 'startVal', 
%                and 'endVal' representing the 10Y spread metrics for the month.
%
%   OUTPUT:
%       FSI    - A struct array (M x 1) containing the FSI evaluation:
%                * month : The reference date (datenum).
%                * value : The numeric stress level (0 = Green, 1 = Yellow, 2 = Red).
%                * color : A string representing the stress state.

    % --- FSI Thresholds and Parameters ---
    SPREAD_QUIET    = 20;    % bps
    SPREAD_RED      = 100;   % bps
    TIME_YELLOW     = 2.0;   % years
    CONSEC_NEG_DAYS = 5;     % consecutive negative slope days
    
    M   = length(months);
    FSI = struct('month', cell(M,1), 'value', cell(M,1), 'color', cell(M,1));
    
    % Initialize the reference spread for the Yellow state evaluation
    lastGreenStartSpread = spread(1).startVal;
    
    for m = 1 : M
        FSI(m).month = months(m);
        
        sp_mean  = spread(m).mean;
        sp_start = spread(m).startVal;
        sp_end   = spread(m).endVal;
        t_mean   = time(m);
        
        % Default State: Green
        FSI(m).value = 0;
        FSI(m).color = 'Green';
        
        if sp_mean <= SPREAD_QUIET
            % Period of relative quiet: Green is forced, no further tests needed
            
        elseif sp_mean > SPREAD_RED && ...
               maxConsecutiveNegative(slope(m).dailySign) >= CONSEC_NEG_DAYS
            % Severe stress criteria met
            FSI(m).value = 2;
            FSI(m).color = 'Red';
            
        elseif t_mean < TIME_YELLOW && ...
               ~isnan(lastGreenStartSpread) && sp_end > lastGreenStartSpread
            % Warning criteria met: short tau* and widening spread vs last Green state
            FSI(m).value = 1;
            FSI(m).color = 'Yellow';
            
        end
        
        % Update the reference start spread only if the evaluated month is Green
        if FSI(m).value == 0
            lastGreenStartSpread = sp_start;
        end
    end
end 

% --- Local Helper Function ---
function n = maxConsecutiveNegative(signs)
% MAXCONSECUTIVENEGATIVE Counts the maximum number of consecutive negative values.
%   Used to determine if the spread curve was inverted for at least 
%   CONSEC_NEG_DAYS consecutively within a given month.
    n       = 0;
    current = 0;
    for i = 1 : length(signs)
        if signs(i) < 0
            current = current + 1;
            n = max(n, current);
        else
            current = 0;
        end
    end
end
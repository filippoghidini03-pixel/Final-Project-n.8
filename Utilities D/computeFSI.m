function FSI = computeFSI(months, slope, time, spread)
% COMPUTEFSI  Compute the Financial Stress Index for a single country.

SPREAD_QUIET    = 20;    % bps
SPREAD_RED      = 100;   % bps
TIME_YELLOW     = 2.0;   % years
CONSEC_NEG_DAYS = 5;     % consecutive negative slope days

M   = length(months);
FSI = struct('month', cell(M,1), 'value', cell(M,1), 'color', cell(M,1));

lastGreenStartSpread = NaN;

for m = 1 : M

    FSI(m).month = months(m);

    sp_mean  = spread(m).mean;
    sp_start = spread(m).startVal;
    sp_end   = spread(m).endVal;
    t_mean   = time(m);

    % Default: Green
    FSI(m).value = 0;
    FSI(m).color = 'Green';

    if sp_mean <= SPREAD_QUIET
        % Period of relative quiet: Green forced, no further test

    elseif sp_mean > SPREAD_RED && ...
           maxConsecutiveNegative(slope(m).dailySign) >= CONSEC_NEG_DAYS
        FSI(m).value = 2;
        FSI(m).color = 'Red';

    elseif t_mean < TIME_YELLOW && ...
           ~isnan(lastGreenStartSpread) && sp_end > lastGreenStartSpread
        FSI(m).value = 1;
        FSI(m).color = 'Yellow';

    end

    % Update lastGreenStartSpread only if month ended up Green
    if FSI(m).value == 0
        lastGreenStartSpread = sp_start;
    end

end 
end 


%% helper function

function n = maxConsecutiveNegative(signs)
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
function [allDatesOut, PDout, ratesOut] = bootstrapEONIA(OIS_raw, settleLag)
% BOOTSTRAPEONIA Bootstraps the EONIA discount curve from Overnight Indexed Swap (OIS) quotes.
%
% INPUTS:
%   OIS_raw   - Struct array containing the daily market data. Expected fields:
%               * valueDate: The observation trade date (datenum).
%               * rates: Vector of OIS rates in percentage (e.g., 0.5 for 0.5%).
%               * tenors: Vector of corresponding tenors in years (e.g., 0.5, 1, 2).
%   settleLag - Integer representing the settlement lag in business days (e.g., 2).
%
% OUTPUTS:
%   allDatesOut - Cell array (nDates x 1), each cell contains the vector of 
%                 node dates starting from the settlement date (t0).
%   PDout       - Cell array (nDates x 1), each cell contains the vector of 
%                 bootstrapped Discount Factors corresponding to the node dates.
%   ratesOut    - Cell array (nDates x 1), each cell contains the original 
%                 OIS rates (in percentage) used for the curve.

nDates      = length(OIS_raw);
allDatesOut = cell(nDates, 1);
PDout       = cell(nDates, 1);
ratesOut    = cell(nDates, 1);

for i = 1 : nDates
    vd       = OIS_raw(i).valueDate;
    rates    = OIS_raw(i).rates / 100;
    tenorsYr = OIS_raw(i).tenors;
    
    % Use the unified shiftDate function to calculate the settlement date (t0)
    t0     = shiftDate(vd, settleLag, 'busdays');
    nKnots = length(tenorsYr);
    
    % Use the unified shiftDate function to calculate maturity dates (Modified Following)
    knotDates = shiftDate(t0, round(tenorsYr * 12), 'months');
    allDates  = [t0; knotDates];
    
    PD    = nan(nKnots + 1, 1);
    PD(1) = 1.0; % Discount factor at t0 is exactly 1
    
    idxShort = find(tenorsYr < 0.999);
    idxLong  = find(tenorsYr >= 0.999);
    
    % Short tenors (OIS < 1y): Simple compounding formulation
    if ~isempty(idxShort)
        te    = knotDates(idxShort);
        % yearfrac parameter 2 applies the Actual/360 convention
        delta = yearfrac(t0, te, 2);
        PD(idxShort + 1) = 1 ./ (1 + delta .* rates(idxShort));
    end
    
    % Long tenors (OIS >= 1y): Annual compounding with zero-rate interpolation
    for ki = idxLong'
        nYears = round(tenorsYr(ki));
        t_i    = knotDates(ki);
        r_i    = rates(ki);
        
        % Generate the annual payment schedule for the underlying swap
        payDates      = shiftDate(t0, (1:nYears)' * 12, 'months');
        payDates(end) = t_i;
        allPayDates = [t0; payDates];
        
        % Calculate the year fractions between consecutive payment dates
        deltas      = yearfrac(allPayDates(1:end-1), allPayDates(2:end), 2);
        
        % Interpolate the discount factors for intermediate payment dates
        pdVec       = interpolateDF(allDates, PD, payDates(1:end-1));
        
        % Bootstrapping formula for the final discount factor
        sumTerm    = sum(deltas(1:end-1) .* pdVec);
        PD(ki + 1) = (1 - r_i * sumTerm) / (1 + deltas(end) * r_i);
    end
    
    % Store the results in the pre-allocated cell arrays
    allDatesOut{i} = allDates;
    PDout{i}       = PD;
    ratesOut{i}    = rates * 100;
end
end

% =========================================================================
%  LOCAL HELPERS
% =========================================================================

function df = interpolateDF(knownDates, knownPD, queryDates)
% INTERPOLATEDF Linearly interpolates the zero rates to compute intermediate DFs.
    t0    = knownDates(1);
    valid = ~isnan(knownPD) & ~isnan(knownDates);
    
    % Convert to years (using Act/365 purely for mathematical interpolation)
    tauVec  = max((knownDates(valid) - t0) / 365, 1e-6);
    
    % Compute the continuous zero rates from the known discount factors
    zVec    = -log(knownPD(valid)) ./ tauVec;
    zVec(1) = zVec(2); % Flatten the curve at the short end to avoid infinity
    
    tauQ = (queryDates - t0) / 365;
    zQ   = interp1(tauVec, zVec, tauQ, 'linear', 'extrap');
    
    % Convert the interpolated zero rates back to discount factors
    df   = exp(-zQ .* tauQ);
    df(tauQ <= 0) = 1.0;
end

function d = shiftDate(d, n, type)
% SHIFTDATE Unified helper to add business days or months (with Mod-Following).
    if strcmp(type, 'busdays')
        for i = 1:n
            d = d + 1;
            wd = weekday(d);
            if wd == 7, d = d + 2; end % Saturday -> Monday
            if wd == 1, d = d + 1; end % Sunday -> Monday
        end
    elseif strcmp(type, 'months')
        d = datemnth(d, n);
        [~, m0] = datevec(d);
        wd = weekday(d);
        d(wd == 1) = d(wd == 1) + 1; % Sunday -> Monday
        d(wd == 7) = d(wd == 7) + 2; % Saturday -> Monday
        [~, m1] = datevec(d);
        % Modified Following: if the shift jumps to the next month, pull it back to Friday
        d(m0 ~= m1) = d(m0 ~= m1) - 3; 
    end
end
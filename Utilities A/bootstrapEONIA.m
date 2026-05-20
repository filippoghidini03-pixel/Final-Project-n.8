function EONIA = bootstrapEONIA(OIS_raw, settleLag)

nDates = length(OIS_raw);
EONIA  = struct('valueDate',       cell(nDates, 1), ...
                't0',              cell(nDates, 1), ...
                'Dates',           cell(nDates, 1), ...
                'Rates',           cell(nDates, 1), ...
                'DiscountFactors', cell(nDates, 1));

for i = 1 : nDates
    vd       = OIS_raw(i).valueDate;
    rates    = OIS_raw(i).rates / 100;   % Convert % to decimal
    tenorsYr = OIS_raw(i).tenors;        % Tenors in years

    t0 = addBusinessDays(vd, settleLag);

    nKnots    = length(tenorsYr);
    knotDates = zeros(nKnots, 1);

    % --- Generate knot dates -------------------------------------------
    for k = 1 : nKnots
        if tenorsYr(k) < 0.999   
            knotDates(k) = addMonths(t0, round(tenorsYr(k) * 12));
        else             
            knotDates(k) = addYears(t0, round(tenorsYr(k)));
        end
    end

    % --- Vector setup and tenors separation ----------------------------
    isShort  = (tenorsYr < 0.999);
    idxShort = find(isShort);
    idxLong  = find(~isShort);

    allDates = [t0; knotDates];
    PD       = nan(nKnots + 1, 1);
    PD(1)    = 1.0;

    % --- Bootstrap short tenors (OIS <= 1y) ----------------------------
    if ~isempty(idxShort)
        te = knotDates(idxShort);
        % USE NATIVE MATLAB FUNCTION (Basis = 2 for Act/360)
        delta = yearfrac(t0, te, 2);
        PD(idxShort + 1) = 1 ./ (1 + delta .* rates(idxShort));
    end

    % --- Bootstrap long tenors (OIS > 1y) ------------------------------
    for ki = idxLong'
        nYears = round(tenorsYr(ki));
        t_i    = knotDates(ki);
        r_i    = rates(ki);

        % Payment dates 
        payDates = zeros(nYears, 1);
        for ny = 1 : nYears
            payDates(ny) = addYears(t0, ny);
        end
        payDates(end) = t_i; % Ensure exact match with the knot date

        % Compute deltas (Act/360) WITH NATIVE FUNCTION
        allPayDates = [t0; payDates];
        deltas      = yearfrac(allPayDates(1:end-1), allPayDates(2:end), 2);

        % Interpolate discount factors 
        pdVec = interpolateDF(allDates, PD, payDates(1:end-1));

        % Recursive formula Eq.(3)
        sumTerm    = sum(deltas(1:end-1) .* pdVec);
        PD(ki + 1) = (1 - r_i * sumTerm) / (1 + deltas(end) * r_i);
    end

    % --- Save into struct ----------------------------------------------
    EONIA(i).valueDate       = vd;
    EONIA(i).t0              = t0;
    EONIA(i).Dates           = allDates;          
    EONIA(i).Rates           = [NaN; rates * 100]; % NaN for t0, revert to %
    EONIA(i).DiscountFactors = PD;                

end 
end 


%% =========================================================================
%  LOCAL HELPERS
%% =========================================================================

function df = interpolateDF(knownDates, knownPD, queryDates)
% INTERPOLATEDF log-linear interpolation. Supports vectorized queryDates.
    t0 = knownDates(1);

    % Remove NaNs
    valid = ~isnan(knownPD) & ~isnan(knownDates);
    d = knownDates(valid);
    p = knownPD(valid);

    if length(d) < 2
        df = nan(size(queryDates));
        return;
    end

    % Compute zero-rates (Act/365). yearfrac(..., 3) could be used here too
    tauVec    = (d - t0) / 365;   
    tauVec(1) = eps;              % Avoid division by zero at t0
    zVec      = -log(p) ./ tauVec;
    zVec(1)   = zVec(2);          % Flat extrapolation at t0

    % Vectorized interpolation
    tauQ = (queryDates - t0) / 365;
    zQ   = interp1(tauVec, zVec, tauQ, 'linear', 'extrap');
    df   = exp(-zQ .* tauQ);
    
    % Handle case where tauQ <= 0 (t0)
    df(tauQ <= 0) = 1.0;
end

function result = addBusinessDays(startDate, n)
% ADDBUSINESSDAYS  Add n business days (Mon-Fri) to startDate.
    d = startDate;
    added = 0;
    while added < n
        d = d + 1;
        dow = weekday(d);   
        if dow ~= 1 && dow ~= 7
            added = added + 1;
        end
    end
    result = d;
end

function result = addMonths(startDate, n)
% ADDMONTHS  Add n calendar months with modified-following convention.
    dv = datevec(startDate);
    dv(2) = dv(2) + n;
    while dv(2) > 12
        dv(2) = dv(2) - 12;
        dv(1) = dv(1) + 1;
    end
    lastDay = eomday(dv(1), dv(2));
    dv(3) = min(dv(3), lastDay);
    result = modifiedFollowing(datenum(dv));
end

function result = addYears(startDate, n)
% ADDYEARS  Add n years with modified-following convention.
    dv = datevec(startDate);
    dv(1) = dv(1) + n;
    lastDay = eomday(dv(1), dv(2));
    dv(3) = min(dv(3), lastDay);
    result = modifiedFollowing(datenum(dv));
end

function result = modifiedFollowing(d)
% MODIFIEDFOLLOWING  Apply modified-following business day convention.
    dow = weekday(d);
    if dow == 1       % Sunday -> Monday
        candidate = d + 1;
    elseif dow == 7   % Saturday -> Monday
        candidate = d + 2;
    else
        result = d;
        return;
    end
    
    % Check for month change
    dvOrig = datevec(d);
    dvCand = datevec(candidate);
    if dvCand(2) ~= dvOrig(2)
        if dow == 1
            candidate = d - 2;   % Sunday -> Friday
        else
            candidate = d - 1;   % Saturday -> Friday
        end
    end
    result = candidate;
end
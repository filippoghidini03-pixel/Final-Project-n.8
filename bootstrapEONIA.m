function EONIA = bootstrapEONIA(OIS_raw, settleLag)

nDates = length(OIS_raw);
EONIA  = struct('valueDate',       cell(nDates, 1), ...
                't0',              cell(nDates, 1), ...
                'Dates',           cell(nDates, 1), ...
                'Rates',           cell(nDates, 1), ...
                'DiscountFactors', cell(nDates, 1));

for i = 1 : nDates
    vd    = OIS_raw(i).valueDate;
    rates = OIS_raw(i).rates / 100;   % convert % to decimal
    tenorsYr = OIS_raw(i).tenors;     % approximate tenors in years

    t0 = addBusinessDays(vd, settleLag);

    nKnots  = length(tenorsYr);
    knotDates = zeros(nKnots, 1);

    for k = 1 : nKnots
        tyr = tenorsYr(k);
        if tyr < 0.999   % monthly tenor (< 1 year)
            nMonths = round(tyr * 12);
            knotDates(k) = addMonths(t0, nMonths);
        else             % annual tenor (>= 1 year)
            nYears = round(tyr);
            knotDates(k) = addYears(t0, nYears);
        end
    end

    % --- Separate short tenors (<1y) from long tenors (>=1y) -----------
    isShort = (tenorsYr < 0.999);
    isLong  = ~isShort;
    idxShort = find(isShort);
    idxLong  = find(isLong);

    % --- Initialise discount factor array (including t0 as index 1) ----
    allDates = [t0; knotDates];
    PD       = nan(nKnots + 1, 1);
    PD(1)    = 1.0;

    % --- Bootstrap short tenors (OIS <= 1y), Eq.(2) of [1] -------------
    for ki = idxShort'
        te    = knotDates(ki);
        delta = act360(t0, te);
        r     = rates(ki);
        PD(ki + 1) = 1 / (1 + delta * r);
    end

    % --- Bootstrap long tenors (OIS > 1y), Eq.(3) of [1] ---------------

    for ki = idxLong'
        nYears  = round(tenorsYr(ki));
        t_i     = knotDates(ki);
        r_i     = rates(ki);

        payDates = zeros(nYears, 1);
        for ny = 1 : nYears
            payDates(ny) = addYears(t0, ny);
        end
        % Ensure last date matches knot date exactly
        payDates(end) = t_i;

        % delta_k for each annual period (Act/360)
        prevDate = t0;
        deltas   = zeros(nYears, 1);
        for p = 1 : nYears
            deltas(p) = act360(prevDate, payDates(p));
            prevDate  = payDates(p);
        end

        pdVec = zeros(nYears, 1);
        for p = 1 : nYears - 1
            pdVec(p) = interpolateDF(allDates, PD, payDates(p));
        end

        % Recursive formula Eq.(3)
        sumTerm = sum(deltas(1:end-1) .* pdVec(1:end-1));
        PD(ki + 1) = (1 - r_i * sumTerm) / (1 + deltas(end) * r_i);
    end

    EONIA(i).valueDate       = vd;
    EONIA(i).t0              = t0;
    EONIA(i).Dates           = allDates;          % [N+1 x 1], starts at t0
    EONIA(i).Rates           = [NaN;rates * 100];       % back to %
    EONIA(i).DiscountFactors = PD;                % [N+1 x 1], PD(1)=1

end 

end 

%Some helper functions

function df = interpolateDF(knownDates, knownPD, queryDate)
    t0 = knownDates(1);

    % Remove NaN entries
    valid = ~isnan(knownPD) & ~isnan(knownDates);
    d = knownDates(valid);
    p = knownPD(valid);

    if length(d) < 2
        df = NaN;
        return;
    end

    % Compute zero-rates (Act/365) at each known date
    tauVec = (d - t0) / 365;   % Act/365 year fractions
    tauVec(1) = eps;            % avoid division by zero at t0
    zVec = -log(p) ./ tauVec;
    zVec(1) = zVec(2);          % flat extrapolation at t0

    % Interpolate at query date
    tauQ = (queryDate - t0) / 365;
    if tauQ <= 0
        df = 1.0;
        return;
    end

    zQ = interp1(tauVec, zVec, tauQ, 'linear', 'extrap');
    df = exp(-zQ * tauQ);

end % interpolateDF


function d = act360(d1, d2)
% ACT360  Compute Act/360 year fraction between two Matlab datenums.
    d = (d2 - d1) / 360;
end


function result = addBusinessDays(startDate, n)
% ADDBUSINESSDAYS  Add n business days (Mon-Fri) to startDate.
    d = startDate;
    added = 0;
    while added < n
        d = d + 1;
        dow = weekday(d);   % 1=Sun, 2=Mon, ..., 7=Sat
        if dow ~= 1 && dow ~= 7
            added = added + 1;
        end
    end
    result = d;
end


function result = addMonths(startDate, n)
% ADDMONTHS  Add n calendar months with modified-following convention.
%   If the resulting date falls on a weekend, move to next Monday.
    dv = datevec(startDate);
    dv(2) = dv(2) + n;
    % Handle month overflow
    while dv(2) > 12
        dv(2) = dv(2) - 12;
        dv(1) = dv(1) + 1;
    end
    % Clamp to end of month if needed
    lastDay = eomday(dv(1), dv(2));
    dv(3) = min(dv(3), lastDay);
    result = modifiedFollowing(datenum(dv));
end


function result = addYears(startDate, n)
% ADDYEARS  Add n years with modified-following convention.
    dv = datevec(startDate);
    dv(1) = dv(1) + n;
    % Handle Feb 29 leap year issue
    lastDay = eomday(dv(1), dv(2));
    dv(3) = min(dv(3), lastDay);
    result = modifiedFollowing(datenum(dv));
end


function result = modifiedFollowing(d)
% MODIFIEDFOLLOWING  Apply modified-following business day convention.
%   If d is a weekend, move forward to Monday, but if that crosses
%   into the next month, move backward to Friday instead.
    dow = weekday(d);
    if dow == 1       % Sunday -> Monday
        candidate = d + 1;
    elseif dow == 7   % Saturday -> Monday
        candidate = d + 2;
    else
        result = d;
        return;
    end
    % Check if month changed (modified = go back if so)
    dvOrig = datevec(d);
    dvCand = datevec(candidate);
    if dvCand(2) ~= dvOrig(2)
        % Move backward to Friday
        if dow == 1
            candidate = d - 2;   % Sunday -> Friday
        else
            candidate = d - 1;   % Saturday -> Friday
        end
    end
    result = candidate;
end

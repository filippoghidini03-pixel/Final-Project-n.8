function EONIA = bootstrapEONIA(OIS_raw, settleLag)
% BOOTSTRAPEONIA  Builds the EONIA discount curve using OIS rates.

nDates = length(OIS_raw);
EONIA = struct('Dates', cell(nDates, 1), 'Rates', cell(nDates, 1), 'DiscountFactors', cell(nDates, 1));

for i = 1 : nDates
    vd       = OIS_raw(i).valueDate;
    rates    = OIS_raw(i).rates / 100;   
    tenorsYr = OIS_raw(i).tenors;        

    t0 = addBusinessDays(vd, settleLag);
    nKnots = length(tenorsYr);

    % --- 1. Generate knot dates [VECTORIZED FOR SPEED] ---
    % Instead of looping one by one, we calculate all knot dates simultaneously
    knotDates = addMonths(t0, round(tenorsYr * 12));

    allDates = [t0; knotDates];
    PD       = nan(nKnots + 1, 1);
    PD(1)    = 1.0; 

    isShort  = (tenorsYr < 0.999);
    idxShort = find(isShort);
    idxLong  = find(~isShort);

    % --- 2. Bootstrap short tenors (OIS <= 1y) ---
    if ~isempty(idxShort)
        te = knotDates(idxShort);
        delta = yearfrac(t0, te, 2); 
        PD(idxShort + 1) = 1 ./ (1 + delta .* rates(idxShort));
    end

    % --- 3. Bootstrap long tenors (OIS > 1y) ---
    for ki = idxLong'
        nYears = round(tenorsYr(ki));
        t_i    = knotDates(ki);
        r_i    = rates(ki);

        % Generate all annual payment dates simultaneously [VECTORIZED]
        monthsToAdd = (1:nYears)' * 12; 
        payDates    = addMonths(t0, monthsToAdd);
        payDates(end) = t_i; % Override last payment to match expiry

        allPayDates = [t0; payDates];
        deltas      = yearfrac(allPayDates(1:end-1), allPayDates(2:end), 2);
        pdVec       = interpolateDF(allDates, PD, payDates(1:end-1));

        sumTerm    = sum(deltas(1:end-1) .* pdVec);
        PD(ki + 1) = (1 - r_i * sumTerm) / (1 + deltas(end) * r_i);
    end

    % --- 4. Store Results ---
    EONIA(i).Dates           = allDates;          
    EONIA(i).Rates           = [NaN; rates * 100]; 
    EONIA(i).DiscountFactors = PD;                
end 
end 

%% =========================================================================
%  LOCAL HELPERS (Vectorized & Optimized)
%% =========================================================================

function df = interpolateDF(knownDates, knownPD, queryDates)
% INTERPOLATEDF Log-linear interpolation
    t0 = knownDates(1);
    valid = ~isnan(knownPD) & ~isnan(knownDates);
    
    tauVec = max((knownDates(valid) - t0) / 365, 1e-6); 
    zVec = -log(knownPD(valid)) ./ tauVec;
    zVec(1) = zVec(2); 
    
    tauQ = (queryDates - t0) / 365;
    zQ   = interp1(tauVec, zVec, tauQ, 'linear', 'extrap');
    
    df = exp(-zQ .* tauQ);
    df(tauQ <= 0) = 1.0; 
end

function d = addBusinessDays(d, n)
% ADDBUSINESSDAYS Add 'n' days skipping weekends
    for i = 1:n
        d = d + 1;
        wd = weekday(d);
        if wd == 7, d = d + 2; end % If Saturday, skip to Monday
        if wd == 1, d = d + 1; end % If Sunday, skip to Monday
    end
end

function d = addMonths(startDate, n)
% ADDMONTHS Supports both scalars and arrays for 'n' to process dates in bulk
    d = datemnth(startDate, n);
    d = modifiedFollowing(d);
end

function d = modifiedFollowing(d)
% MODIFIEDFOLLOWING Push to Monday, rollback to Friday if month changes.
% Completely vectorized: it can process a single date or an entire array instantly.
    [~, m0] = datevec(d);
    
    wd = weekday(d);
    d(wd == 1) = d(wd == 1) + 1; % Sunday -> Monday
    d(wd == 7) = d(wd == 7) + 2; % Saturday -> Monday
    
    [~, m1] = datevec(d);
    
    % If the forward shift caused a month change, rollback to Friday (-3 days)
    idxChanged = (m0 ~= m1);
    d(idxChanged) = d(idxChanged) - 3; 
end
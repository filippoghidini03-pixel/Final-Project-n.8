function [allDatesOut, PDout, ratesOut] = bootstrapEONIA(OIS_raw, settleLag)
% BOOTSTRAPEONIA  Bootstraps the EONIA discount curve for every business day.

nDates      = length(OIS_raw);
allDatesOut = cell(nDates, 1);
PDout       = cell(nDates, 1);
ratesOut    = cell(nDates, 1);

for i = 1 : nDates
    vd       = OIS_raw(i).valueDate;
    rates    = OIS_raw(i).rates / 100;
    tenorsYr = OIS_raw(i).tenors;

    % Usa la nuova funzione unificata shiftDate per i giorni
    t0     = shiftDate(vd, settleLag, 'busdays');
    nKnots = length(tenorsYr);

    % Usa la nuova funzione unificata shiftDate per i mesi
    knotDates = shiftDate(t0, round(tenorsYr * 12), 'months');
    allDates  = [t0; knotDates];

    PD    = nan(nKnots + 1, 1);
    PD(1) = 1.0;

    idxShort = find(tenorsYr < 0.999);
    idxLong  = find(tenorsYr >= 0.999);

    % Short tenors (OIS <= 1y)
    if ~isempty(idxShort)
        te    = knotDates(idxShort);
        delta = yearfrac(t0, te, 2);
        PD(idxShort + 1) = 1 ./ (1 + delta .* rates(idxShort));
    end

    % Long tenors (OIS > 1y)
    for ki = idxLong'
        nYears = round(tenorsYr(ki));
        t_i    = knotDates(ki);
        r_i    = rates(ki);

        % Usa la nuova funzione unificata shiftDate per i mesi
        payDates      = shiftDate(t0, (1:nYears)' * 12, 'months');
        payDates(end) = t_i;

        allPayDates = [t0; payDates];
        deltas      = yearfrac(allPayDates(1:end-1), allPayDates(2:end), 2);
        pdVec       = interpolateDF(allDates, PD, payDates(1:end-1));

        sumTerm    = sum(deltas(1:end-1) .* pdVec);
        PD(ki + 1) = (1 - r_i * sumTerm) / (1 + deltas(end) * r_i);
    end

    allDatesOut{i} = allDates;
    PDout{i}       = PD;
    ratesOut{i}    = rates * 100;
end

end

% =========================================================================
%  LOCAL HELPERS
% =========================================================================

function df = interpolateDF(knownDates, knownPD, queryDates)
    t0    = knownDates(1);
    valid = ~isnan(knownPD) & ~isnan(knownDates);
    tauVec  = max((knownDates(valid) - t0) / 365, 1e-6);
    zVec    = -log(knownPD(valid)) ./ tauVec;
    zVec(1) = zVec(2);
    tauQ = (queryDates - t0) / 365;
    zQ   = interp1(tauVec, zVec, tauQ, 'linear', 'extrap');
    df   = exp(-zQ .* tauQ);
    df(tauQ <= 0) = 1.0;
end

function d = shiftDate(d, n, type)
% SHIFTDATE Single helper to add business days or months (with Mod-Following)
    if strcmp(type, 'busdays')
        for i = 1:n
            d = d + 1;
            wd = weekday(d);
            if wd == 7, d = d + 2; end 
            if wd == 1, d = d + 1; end 
        end
    elseif strcmp(type, 'months')
        d = datemnth(d, n);
        [~, m0] = datevec(d);
        wd = weekday(d);
        d(wd == 1) = d(wd == 1) + 1; 
        d(wd == 7) = d(wd == 7) + 2; 
        [~, m1] = datevec(d);
        d(m0 ~= m1) = d(m0 ~= m1) - 3; 
    end
end
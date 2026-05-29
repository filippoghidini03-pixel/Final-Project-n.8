function [SpreadsFilt, datesFilt] = filterMonths(Spreads, eon_t0, threshold, spikeThresh, spreadField)

if nargin < 3, threshold   = 20;           end
if nargin < 4, spikeThresh = 50;           end
if nargin < 5, spreadField = 'ASWSpreads'; end

nDays       = length(Spreads);
uniqueBonds = unique(vertcat(Spreads.ExpiryDates));
nBonds      = length(uniqueBonds);

spreadMat = nan(nDays, nBonds);
posMat    = zeros(nDays, nBonds);

for i = 1:nDays
    [found, pos] = ismember(uniqueBonds, Spreads(i).ExpiryDates);
    spreadMat(i, found) = Spreads(i).(spreadField)(pos(found));
    posMat(i, :)        = pos;
end

for b = 1:nBonds
    col   = spreadMat(:, b);
    valid = ~isnan(col);
    if sum(valid) >= 3
        col(valid)      = filter_prices(col(valid), spikeThresh);
        spreadMat(:, b) = col;
    end
end

for i = 1:nDays
    ok = posMat(i,:) > 0;
    Spreads(i).(spreadField)(posMat(i, ok)) = spreadMat(i, ok);
end

dates = eon_t0(:);
dv    = datevec(dates);
ym    = dv(:,1) * 100 + dv(:,2);

spreads10Y = nan(nDays, 1);
for i = 1:nDays
    if ~isempty(Spreads(i).(spreadField))
        [~, maxIdx]    = max(Spreads(i).ExpiryDates);
        spreads10Y(i)  = Spreads(i).(spreadField)(maxIdx);
    end
end

[uniqueYM, ~, grp] = unique(ym);
monthMeans  = accumarray(grp, spreads10Y, [], @(x) mean(x, 'omitnan'));
keepYM      = uniqueYM(monthMeans >= threshold);
keepMask    = ismember(ym, keepYM);

SpreadsFilt = Spreads(keepMask);
datesFilt   = dates(keepMask);

fprintf('  Months removed : %d / %d\n', length(uniqueYM)-length(keepYM), length(uniqueYM));
fprintf('  Days kept      : %d / %d\n', sum(keepMask), nDays);
end
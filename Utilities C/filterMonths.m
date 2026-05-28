function [SpreadsFilt, datesFilt] = filterMonths(Spreads, eon_t0, threshold, spikeThresh)
%
% INPUTS:
%   Spreads     - Struct array of length nDays containing bond data. 
%                 Expected fields: ExpiryDates, ASWSpreads.
%   eon_t0      - Vector of EONIA settlement dates (length nDays).
%   threshold   - Minimum required monthly mean for the 10Y spread 
%                 (default = 20).
%   spikeThresh - Threshold in bps for the price/spread spike filter 
%                 (default = 50).
%
% OUTPUTS:
%   SpreadsFilt - Filtered struct array containing only the kept days.
%   datesFilt   - Vector of filtered datenums corresponding to the kept days.

if nargin < 3, threshold   = 20; end
if nargin < 4, spikeThresh = 50; end

nDays       = length(Spreads);
uniqueBonds = unique(vertcat(Spreads.ExpiryDates));
nBonds      = length(uniqueBonds);

% STEP 1: Build [nDays x nBonds] matrix, filter column-wise, put back
spreadMat = nan(nDays, nBonds);
posMat    = zeros(nDays, nBonds);

% Extract: one ismember per day finds all bond positions at once
for i = 1:nDays
    [found, pos] = ismember(uniqueBonds, Spreads(i).ExpiryDates);
    spreadMat(i, found) = Spreads(i).ASWSpreads(pos(found));
    posMat(i, :)        = pos;
end

% Spike filter column-wise: each column represents one bond's time series
for b = 1:nBonds
    col   = spreadMat(:, b);
    valid = ~isnan(col);
    if sum(valid) >= 3
        col(valid)      = filter_prices(col(valid), spikeThresh);
        spreadMat(:, b) = col;
    end
end

% Put back: one loop over days only to reconstruct the struct array
for i = 1:nDays
    ok = posMat(i,:) > 0;
    Spreads(i).ASWSpreads(posMat(i, ok)) = spreadMat(i, ok);
end

% STEP 2: Month filter
% Create a local vector of dates directly from the input vector
dates = eon_t0(:);
dv    = datevec(dates);
ym    = dv(:,1) * 100 + dv(:,2);

% Per Baviera-Lebovitz: "average 10year spread constantly below 20 bps".
% The filter is on the LONG END of the curve (the 10Y benchmark), not on a
% cross-maturity average (which would have no clear financial interpretation).
% We use the spread of the longest-maturity bond available each day as a
% proxy for the 10Y spread, then average those values within each month.
dailyLongEnd = nan(nDays, 1);
for i = 1:nDays
    if ~isempty(Spreads(i).ExpiryDates)
        [~, idx]        = max(Spreads(i).ExpiryDates);   % bond closest to 10Y
        dailyLongEnd(i) = Spreads(i).ASWSpreads(idx);
    end
end

[uniqueYM, ~, grp] = unique(ym);

% Monthly mean of the daily long-end proxy (ignoring days with no bonds)
monthMeans = accumarray(grp, dailyLongEnd, [], @(x) mean(x(~isnan(x))));

% Apply the threshold
keepYM      = uniqueYM(monthMeans >= threshold);
keepMask    = ismember(ym, keepYM);

% Filter the original structure and the local dates vector simultaneously
SpreadsFilt = Spreads(keepMask);
datesFilt   = dates(keepMask);

fprintf('  Months removed : %d / %d\n', length(uniqueYM)-length(keepYM), length(uniqueYM));
fprintf('  Days kept      : %d / %d\n', sum(keepMask), nDays);
end
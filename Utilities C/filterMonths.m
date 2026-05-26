function [SpreadsFilt, datesFilt] = filterMonths(Spreads, eon_t0, threshold, spikeThresh)
% FILTERMONTHS Filters out spikes and removes months with low 10Y spreads.
%
% This function performs a two-step cleaning process on the bond spreads:
%   1. Spike Filter: Analyzes the time series of each individual bond and 
%      replaces isolated jumps exceeding a specified threshold with the 
%      average of adjacent days.
%   2. Monthly Filter: Calculates the monthly average of the 10-year bond
%      spread (the longest maturity, assumed to be the last element of the 
%      daily vector). It discards all data for months where this average 
%      falls below a specified threshold.
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

% =========================================================================
% STEP 1: Build [nDays x nBonds] matrix, filter column-wise, put back
% =========================================================================
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

% =========================================================================
% STEP 2: Month filter (Based ONLY on the 10-year bond)
% =========================================================================
% Create a local vector of dates directly from the input vector
dates = eon_t0(:);
dv    = datevec(dates);
ym    = dv(:,1) * 100 + dv(:,2);

% Extract ONLY the last spread (10Y maturity) for each business day
spreads10Y = nan(nDays, 1);
for i = 1:nDays
    if ~isempty(Spreads(i).ASWSpreads)
        spreads10Y(i) = Spreads(i).ASWSpreads(end);
    end
end

% Since we have exactly 1 value per day, the month-to-day mapping is 1:1
[uniqueYM, ~, grp] = unique(ym);

% Calculate the monthly mean using only the 10Y spreads (ignoring NaNs)
monthMeans  = accumarray(grp, spreads10Y, [], @(x) mean(x, 'omitnan'));

% Apply the threshold
keepYM      = uniqueYM(monthMeans >= threshold);
keepMask    = ismember(ym, keepYM);

% Filter the original structure and the local dates vector simultaneously
SpreadsFilt = Spreads(keepMask);
datesFilt   = dates(keepMask);

fprintf('  Months removed : %d / %d\n', length(uniqueYM)-length(keepYM), length(uniqueYM));
fprintf('  Days kept      : %d / %d\n', sum(keepMask), nDays);
end
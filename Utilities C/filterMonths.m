function [SpreadsFilt, datesFilt] = filterMonths(Spreads, eon_t0, threshold, spikeThresh, spreadField)
%
%   INPUTS:
%       Spreads     - A struct array containing bond data.
%                     Must contain the field 'ExpiryDates' and the field 
%                     specified by spreadField.
%       eon_t0      - A numeric vector of evaluation dates 
%                     (datenums) corresponding to each day in Spreads.
%       threshold   - (Optional) Minimum required monthly mean for the longest 
%                     maturity spread (default = 20 bps).
%       spikeThresh - (Optional) Threshold in bps for the price/spread 
%                     spike filter (default = 50 bps).
%       spreadField - (Optional) String or char array specifying the name of 
%                     the field in Spreads to use for the spread values. 
%                     Default is 'ASWSpreads'.
%
%   OUTPUTS:
%       SpreadsFilt - Filtered struct array containing only the days that 
%                     belong to the valid (stressed) months.
%       datesFilt   - Vector of datenums corresponding to the kept days.

    if nargin < 3, threshold   = 20;           end
    if nargin < 4, spikeThresh = 50;           end
    if nargin < 5, spreadField = 'ASWSpreads'; end
    
    nDays       = length(Spreads);
    uniqueBonds = unique(vertcat(Spreads.ExpiryDates));
    nBonds      = length(uniqueBonds);
    
    % --- STEP 1: Column-wise Spike Filtering ---
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
    
    % --- STEP 2: Monthly Filtering based on Longest Maturity ---
    dates = eon_t0(:);
    dv    = datevec(dates);
    ym    = dv(:,1) * 100 + dv(:,2);
    
    spreads10Y = nan(nDays, 1);
    for i = 1:nDays
        if ~isempty(Spreads(i).(spreadField))
            % Find the longest maturity bond available on this day
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
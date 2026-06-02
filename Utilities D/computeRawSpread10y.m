function spread10y = computeRawSpread10y(Spreads, spreadField)
%
%   INPUTS:
%       Spreads     - A struct array (length nDays) containing bond data.
%                     Must contain the field 'ExpiryDates' and the field 
%                     specified by spreadField.
%       spreadField - (Optional) String or char array specifying the name of 
%                     the field in Spreads to use for the spread values. 
%                     Default is 'ASWSpreads'.
%
%   OUTPUT:
%       spread10y   - A numeric column vector (nDays x 1) containing the 
%                     filtered 10-year spreads. Days with no data will 
%                     contain NaN.

    if nargin < 2, spreadField = 'ASWSpreads'; end
    
    n         = length(Spreads);
    spread10y = nan(n, 1);
    
    % Extract the longest maturity spread for each day
    for i = 1:n
        if ~isempty(Spreads(i).ExpiryDates)
            % Find the index of the bond with the furthest expiration date
            [~, idx]     = max(Spreads(i).ExpiryDates);
            spread10y(i) = Spreads(i).(spreadField)(idx);
        end
    end
    
    % Apply the spike filter only to valid (non-NaN) observations
    % using a default threshold of 50 bps
    valid            = ~isnan(spread10y);
    if any(valid)
        spread10y(valid) = filter_prices(spread10y(valid), 50);
    end
end
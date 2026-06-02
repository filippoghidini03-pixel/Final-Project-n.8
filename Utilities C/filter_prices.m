function g = filter_prices(prices, threshold)
%
%   INPUTS:
%       prices    - A numeric vector representing a time series of prices or spreads.
%       threshold - A scalar defining the minimum absolute jump required 
%                   to trigger the filter.
%               
%   OUTPUT:
%       g         - The filtered numeric vector where isolated spikes have 
%                   been smoothed out.

    g = prices;
    d = diff(prices); 
    
    d1 = d(1:end-1);
    d2 = d(2:end);
    
    % Find spikes: jump > threshold in both directions and with opposite signs
    spike_idx = find(abs(d1) > threshold & abs(d2) > threshold & (d1 .* d2 < 0)) + 1;
    
    % Interpolate using the average of the neighboring points
    g(spike_idx) = (prices(spike_idx - 1) + prices(spike_idx + 1)) / 2;
end
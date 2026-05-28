function g = filter_prices(prices, threshold)
%
% INPUTS:
%   prices    - A numeric vector representing a time series of prices or spreads.
%   threshold - The minimum absolute change required to trigger the filter.
%               
% OUTPUT:
%   g         - The filtered numeric vector where isolated spikes have been 
%               smoothed out using the arithmetic mean of adjacent points.

g = prices;

for i = 2:length(prices)-1
    d1 = prices(i)   - prices(i-1);
    d2 = prices(i+1) - prices(i);
    
    % Check if both jumps exceed the threshold and are in opposite directions
    if abs(d1) > threshold && abs(d2) > threshold && d1*d2 < 0
        g(i) = (prices(i+1) + prices(i-1)) / 2;
    end
end
end
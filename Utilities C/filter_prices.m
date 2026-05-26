function g = filter_prices(prices, threshold)
% FILTER_PRICES  Spike filter: isolated jumps replaced by average of neighbours.
%   threshold = 0.5  for clean prices (default)
%   threshold = 50   for ASW spreads (bps)

g = prices;

for i = 2:length(prices)-1
    d1 = prices(i)   - prices(i-1);
    d2 = prices(i+1) - prices(i);
    if abs(d1) > threshold && abs(d2) > threshold && d1*d2 < 0
        g(i) = (prices(i+1) + prices(i-1)) / 2;
    end
end
end
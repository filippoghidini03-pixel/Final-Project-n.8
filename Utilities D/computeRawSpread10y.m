function spread10y = computeRawSpread10y(Spreads, spreadField)

if nargin < 2, spreadField = 'ASWSpreads'; end

n         = length(Spreads);
spread10y = nan(n, 1);

for i = 1:n
    if ~isempty(Spreads(i).ExpiryDates)
        [~, idx]     = max(Spreads(i).ExpiryDates);
        spread10y(i) = Spreads(i).(spreadField)(idx);
    end
end

valid            = ~isnan(spread10y);
spread10y(valid) = filter_prices(spread10y(valid), 50);

end
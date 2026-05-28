function g = filter_prices(prices, threshold)
    g = prices;
    d = diff(prices); 
    d1 = d(1:end-1);
    d2 = d(2:end);
    % Trova i picchi: salto > threshold in entrambe le direzioni e con segno opposto
    spike_idx = find(abs(d1) > threshold & abs(d2) > threshold & (d1 .* d2 < 0)) + 1;
    % Interpola con la media dei vicini
    g(spike_idx) = (prices(spike_idx - 1) + prices(spike_idx + 1)) / 2;
end
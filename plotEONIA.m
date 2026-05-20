function plotEONIA(EONIA, datesToPlot)
% PLOTEONIA  Plots EONIA zero-rate curves for selected dates.

% Extract all settlement dates (t0) using vectorized arrayfun
allSettleDates = arrayfun(@(x) x.Dates(1), EONIA);

% Default: plot up to 5 evenly spaced dates from the dataset
if nargin < 2 || isempty(datesToPlot)
    idxDefault  = round(linspace(1, length(EONIA), min(5, length(EONIA))));
    datesToPlot = allSettleDates(idxDefault);
end

colors = lines(length(datesToPlot));
figure('Name', 'EONIA Zero-Rate Curves', 'NumberTitle', 'off');
hold on; grid on;

for i = 1:length(datesToPlot)
    % Find the index of the closest available settlement date
    [~, idx] = min(abs(allSettleDates - datesToPlot(i)));
    e = EONIA(idx);
    t0 = e.Dates(1); 

    % Vectorized calculation of zero rates (Act/365)
    taus = (e.Dates(2:end) - t0) / 365;
    zr   = -log(e.DiscountFactors(2:end)) ./ taus * 100; % Rate in %

    % Plot the curve
    plot(taus, zr, '-o', 'Color', colors(i,:), 'LineWidth', 1.2, ...
         'MarkerSize', 4, 'DisplayName', datestr(t0, 'dd-mmm-yyyy'));
end

hold off;
xlabel('Maturity (years)');
ylabel('Zero Rate (%)');
title('EONIA Discount Curve');
legend('Location', 'best');

end
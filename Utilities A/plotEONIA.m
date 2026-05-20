function plotEONIA(EONIA, datesToPlot)

% If dates are not specified, select 5 equally spaced dates from the sample
if nargin < 2 || isempty(datesToPlot)
    idxDefault  = round(linspace(1, length(EONIA), 5));
    datesToPlot = [EONIA(idxDefault).valueDate];
end

allValueDates = [EONIA.valueDate];
colors = lines(length(datesToPlot));

figure('Name', 'EONIA Zero-Rate Curves', 'NumberTitle', 'off');
hold on; grid on;

for i = 1 : length(datesToPlot)
    % Find the index of the closest available date to the requested one
    [~, idx] = min(abs(allValueDates - datesToPlot(i)));
    e = EONIA(idx);

    % Calculation of zero rates (Act/365) for all knots except t0
    taus = (e.Dates(2:end) - e.t0) / 365;
    PD   = e.DiscountFactors(2:end);
    zr   = -log(PD) ./ taus * 100;   % Rate in percentage (%)

    % Plot the curve
    plot(taus, zr, '-o', 'Color', colors(i,:), ...
         'LineWidth', 1.2, 'MarkerSize', 4, ...
         'DisplayName', datestr(e.valueDate, 'dd-mmm-yyyy'));
end

hold off;
xlabel('Maturity (years)');
ylabel('Zero rate (%)');
title('EONIA Discount Curve — Zero Rates');
legend('Location', 'best');

end
function plotEONIA(EONIA, datesToPlot)

if nargin < 2 || isempty(datesToPlot)
    n = length(EONIA);
    datesToPlot = [EONIA(1).valueDate, ...
                   EONIA(round(n/4)).valueDate, ...
                   EONIA(round(n/2)).valueDate, ...
                   EONIA(round(3*n/4)).valueDate, ...
                   EONIA(n).valueDate];
end

allValueDates = [EONIA.valueDate];
colors = lines(length(datesToPlot));

figure('Name', 'EONIA Zero-Rate Curves', 'NumberTitle', 'off');
hold on;

for i = 1 : length(datesToPlot)
    % Find closest available date
    [~, idx] = min(abs(allValueDates - datesToPlot(i)));
    e  = EONIA(idx);
    t0 = e.t0;

    % Compute zero rates (Act/365) for all knots except t0
    taus = (e.Dates(2:end) - t0) / 365;
    PD   = e.DiscountFactors(2:end);
    zr   = -log(PD) ./ taus * 100;   % in %

    plot(taus, zr, '-o', 'Color', colors(i,:), 'MarkerSize', 4, ...
         'DisplayName', datestr(e.valueDate, 'dd-mmm-yyyy'));
end

hold off;
grid on;
xlabel('Maturity (years)');
ylabel('Zero rate (%)');
title('EONIA Discount Curve — Zero Rates');
legend('Location', 'best');

end % function plotEONIA
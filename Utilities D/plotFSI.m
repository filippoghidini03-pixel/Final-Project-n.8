function plotFSI(FSI_italy, FSI_spain, FSI_euro)
% PLOTFSI  Plot the Financial Stress Index as a colour-coded timeline.

colorRGB = struct('Green',  [0.18 0.63 0.18], ...
                  'Yellow', [1.00 0.85 0.00], ...
                  'Red',    [0.85 0.10 0.10]);

figure('Name', 'Financial Stress Index', 'NumberTitle', 'off', ...
       'Position', [100 100 1100 300]);

labels   = {'ITALY', 'SPAIN', 'EUROZONE'};
FSI_list = {FSI_italy, FSI_spain, FSI_euro};
nRows    = 3;

for row = 1 : nRows
    FSI = FSI_list{row};
    M   = length(FSI);

    for m = 1 : M
        x1  = FSI(m).month;
        % Width = days until next month (or 30 for last)
        if m < M
            x2 = FSI(m+1).month;
        else
            x2 = x1 + 30;
        end

        col = colorRGB.(FSI(m).color);
        % Draw filled rectangle for this month
        patch([x1 x2 x2 x1], ...
              [row-1 row-1 row row], ...
              col, 'EdgeColor', 'none');
        hold on;
    end
end

% Axes formatting 
xlim([FSI_italy(1).month, FSI_italy(end).month + 30]);
ylim([0, nRows]);
set(gca, 'YTick', 0.5:1:nRows-0.5, 'YTickLabel', fliplr(labels));

% X-axis: yearly ticks
allMonths = [FSI_italy.month];
years = unique(year(datetime(datevec(allMonths))));
yearTicks = datenum(years, 1, 1);
set(gca, 'XTick', yearTicks);
datetick('x', 'yyyy', 'keepticks');

% Grid
set(gca, 'XGrid', 'on', 'GridAlpha', 0.3);

title('Financial Stress Index — Eurozone (ASW spread)');
xlabel('Date');

% Legend
patch(NaN, NaN, colorRGB.Green,  'DisplayName', 'Green (0) — Open market');
patch(NaN, NaN, colorRGB.Yellow, 'DisplayName', 'Yellow (1) — Dysfunctional');
patch(NaN, NaN, colorRGB.Red,    'DisplayName', 'Red (2) — Severe disruption');
legend('Location', 'southoutside', 'Orientation', 'horizontal');

hold off;

end 
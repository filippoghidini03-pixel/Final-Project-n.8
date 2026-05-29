function plotFSI(FSI_italy, FSI_spain, FSI_euro, dates_BTP, spread10y_BTP, dates_BON, spread10y_BON, spreadName)

if nargin < 8, spreadName = 'ASW'; end

FSI_list   = {FSI_italy, FSI_spain, FSI_euro};
titles     = {'Italy (BTP)', 'Spain (BONO)', 'Eurozone'};
colorNames = {'Green', 'Yellow', 'Red'};
colors     = {'g', 'y', 'r'};

sp_dates_all = {dates_BTP, dates_BON, [dates_BTP; dates_BON]};
sp_vals_all  = {spread10y_BTP, spread10y_BON, [spread10y_BTP; spread10y_BON]};

dv        = datevec([FSI_italy.month]');
yearTicks = datenum(unique(dv(:,1)), 1, 1);

figure('Name', ['Financial Stress Index — ' spreadName], 'Position', [100 50 1200 700]);

for row = 1:3
    subplot(3, 1, row);
    hold on;

    FSI      = FSI_list{row};
    x1       = [FSI.month]';
    x2       = [x1(2:end); x1(end)+31];
    sp_dates = sp_dates_all{row};
    sp_vals  = sp_vals_all{row};

    [sp_dates, idx] = sort(sp_dates);
    sp_vals = sp_vals(idx);

    valid = sp_vals(~isnan(sp_vals));
    ymin  = min(0,   min(valid));
    ymax  = max(100, max(valid));

    for c = 1:3
        mask = strcmp({FSI.color}, colorNames{c});
        if ~any(mask), continue; end
        Xp = [x1(mask)'; x2(mask)'; x2(mask)'; x1(mask)'];
        Yp = repmat([ymin; ymin; ymax; ymax], 1, sum(mask));
        patch(Xp, Yp, colors{c}, 'EdgeColor','none', 'FaceAlpha',0.35, ...
              'HandleVisibility','off');
    end

    plot(sp_dates, sp_vals, 'k-', 'LineWidth', 1, 'HandleVisibility','off');

    xlim([x1(1), x2(end)]);
    ylim([ymin ymax]);
    set(gca, 'XTick', yearTicks);
    datetick('x', 'yyyy', 'keepticks');
    ylabel('[bps]');
    title([titles{row} ' — ' spreadName]);
    grid on;
    hold off;
end

subplot(3, 1, 1);
hold on;
patch(NaN,NaN,'g','FaceAlpha',0.35,'DisplayName','Green — Open market');
patch(NaN,NaN,'y','FaceAlpha',0.35,'DisplayName','Yellow — Dysfunctional');
patch(NaN,NaN,'r','FaceAlpha',0.35,'DisplayName','Red — Severe disruption');
plot(NaN,NaN,'k-','DisplayName',['10y ' spreadName ' spread']);
legend('Location','northwest','FontSize',8);
hold off;
end
function plotASWvsZeta(dates_BTP, spread10y_BTP, dates_BTP_z, spread10y_BTP_z, ...
                       dates_BON, spread10y_BON, dates_BON_z, spread10y_BON_z)
% PLOTASWVSZETA Compares the 10-year ASW Spread vs Zeta Spread over time.
%
%   Generates a 2-panel figure (Italy and Spain) showing the historical 
%   evolution of the 10-year Asset Swap Spread (ASW) alongside the 
%   10-year Zeta Spread.
%
%   INPUTS:
%       dates_BTP, spread10y_BTP     - Dates and 10y ASW spreads for Italy
%       dates_BTP_z, spread10y_BTP_z - Dates and 10y Zeta spreads for Italy
%       dates_BON, spread10y_BON     - Dates and 10y ASW spreads for Spain
%       dates_BON_z, spread10y_BON_z - Dates and 10y Zeta spreads for Spain

    figure('Name', 'ASW vs Zeta Spread', 'Position', [100 50 1200 500]);
    
    % --- Top Panel: Italy (BTP) ---
    subplot(2,1,1);
    plot(dates_BTP, spread10y_BTP, 'b-', 'LineWidth', 1, 'DisplayName', 'ASW');
    hold on;
    plot(dates_BTP_z, spread10y_BTP_z, 'r-', 'LineWidth', 1, 'DisplayName', 'Zeta');
    datetick('x', 'yyyy', 'keepticks');
    ylabel('[bps]'); 
    title('Italy (BTP)');
    legend('Location', 'northwest'); 
    grid on;
    hold off;
    
    % --- Bottom Panel: Spain (BONO) ---
    subplot(2,1,2);
    plot(dates_BON, spread10y_BON, 'b-', 'LineWidth', 1, 'DisplayName', 'ASW');
    hold on;
    plot(dates_BON_z, spread10y_BON_z, 'r-', 'LineWidth', 1, 'DisplayName', 'Zeta');
    datetick('x', 'yyyy', 'keepticks');
    ylabel('[bps]'); 
    title('Spain (BONO)');
    legend('Location', 'northwest'); 
    grid on;
    hold off;
    
end
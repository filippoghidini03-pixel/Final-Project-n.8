function plotBreakpointEvolution(dates_BTP, tau_star_BTP, dates_BON, tau_star_BON)
% PLOTBREAKPOINTEVOLUTION Generates the final scatter plot of Tau* over time.

figure('Name', 'Optimal Breakpoint (Tau*) Evolution', 'NumberTitle', 'off', 'Color', 'w');
plot(dates_BTP, tau_star_BTP, '.', 'DisplayName', 'BTP \tau^*', 'MarkerSize', 10);
hold on; grid on;
plot(dates_BON, tau_star_BON, '.', 'DisplayName', 'BONO \tau^*', 'MarkerSize', 10);

datetick('x', 'mm-yyyy', 'keepticks');
xlabel('Date');
ylabel('Optimal Breakpoint \tau^* (Years)');
title('Evolution of the Optimal Breakpoint (\tau^*) over Time');
legend('Location', 'best');

end
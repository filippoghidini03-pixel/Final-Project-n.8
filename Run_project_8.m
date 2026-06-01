%% Run_project_8.m
clear all; 
close all; 
clc;

addpath('Data')
addpath('Utilities A')
addpath('Utilities B')
addpath('Utilities C')
addpath('Utilities D')
addpath('Other Utilities')

%% PARAMETERS
param = initParameters();

%% PART A
fprintf('=== PART A ===\n');
OIS_raw  = readOISdata(param.fileOIS, param.t1, param.tN, param.maxTenorYears);
[Dates, Discounts, Rates] = bootstrapEONIA(OIS_raw, param.settleLag);
EONIA    = buildEONIAstruct(Dates, Discounts, Rates);
bond_BTP = buildBondStruct(param.fileBTP, param.t1, param.tN);
bond_BON = buildBondStruct(param.fileBON, param.t1, param.tN);
plotEONIA(EONIA, []);
save('Part_A.mat', 'EONIA', 'bond_BTP', 'bond_BON');
fprintf('BTPs: %d | BONOs: %d\n=== Part A Complete ===\n\n', length(bond_BTP), length(bond_BON));

%% PART B
fprintf('=== PART B ===\n');
[Spreads_BTP, Spreads_BON] = computeASWspreads(EONIA, bond_BTP, bond_BON);
save('Part_B.mat', 'Spreads_BTP', 'Spreads_BON');
fprintf('=== Part B Complete ===\n\n');

%% PART C
fprintf('=== PART C ===\n');
eon_t0 = arrayfun(@(x) x.Dates(1), EONIA);

[Spreads_BTP_filt, dates_BTP] = filterMonths(Spreads_BTP, eon_t0, 20, 50);
[Spreads_BON_filt, dates_BON] = filterMonths(Spreads_BON, eon_t0, 20, 50);

[tau_star_BTP, L_star_BTP] = computeBrokenLineEvolution(Spreads_BTP_filt, dates_BTP);
[tau_star_BON, L_star_BON] = computeBrokenLineEvolution(Spreads_BON_filt, dates_BON);

plotBreakpointEvolution(dates_BTP, tau_star_BTP, dates_BON, tau_star_BON);
fprintf('=== Part C Complete ===\n\n');

%% PART D
fprintf('=== PART D ===\n');
[slopeSign_BTP, spread10y_BTP] = computeSlopeAndSpread(Spreads_BTP_filt, dates_BTP, tau_star_BTP, 'ASWSpreads');
[slopeSign_BON, spread10y_BON] = computeSlopeAndSpread(Spreads_BON_filt, dates_BON, tau_star_BON, 'ASWSpreads');

[months_IT, slope_IT, time_IT, spread_IT] = buildMonthlyIndicators(eon_t0, dates_BTP, tau_star_BTP, slopeSign_BTP, spread10y_BTP);
[months_ES, slope_ES, time_ES, spread_ES] = buildMonthlyIndicators(eon_t0, dates_BON, tau_star_BON, slopeSign_BON, spread10y_BON);

[FSI_euro, FSI_italy, FSI_spain] = computeEuroFSI(months_IT, slope_IT, time_IT, spread_IT, months_ES, slope_ES, time_ES, spread_ES);

spread10y_plot_BTP = computeRawSpread10y(Spreads_BTP, 'ASWSpreads');
spread10y_plot_BON = computeRawSpread10y(Spreads_BON, 'ASWSpreads');
plotFSI(FSI_italy, FSI_spain, FSI_euro, eon_t0, spread10y_plot_BTP, eon_t0, spread10y_plot_BON, 'ASW');
save('Part_D.mat', 'FSI_euro', 'FSI_italy', 'FSI_spain');
fprintf('=== Part D Complete ===\n');
%% PART E
fprintf('=== PART E ===\n');

[Spreads_BTP_filt_z, dates_BTP_z] = filterMonths(Spreads_BTP, eon_t0, 20, 50, 'ZetaSpreads');
[Spreads_BON_filt_z, dates_BON_z] = filterMonths(Spreads_BON, eon_t0, 20, 50, 'ZetaSpreads');

[tau_star_BTP_z, ~] = computeBrokenLineEvolution(Spreads_BTP_filt_z, dates_BTP_z, 'ZetaSpreads');
[tau_star_BON_z, ~] = computeBrokenLineEvolution(Spreads_BON_filt_z, dates_BON_z, 'ZetaSpreads');

[slopeSign_BTP_z, spread10y_BTP_z] = computeSlopeAndSpread(Spreads_BTP_filt_z, dates_BTP_z, tau_star_BTP_z, 'ZetaSpreads');
[slopeSign_BON_z, spread10y_BON_z] = computeSlopeAndSpread(Spreads_BON_filt_z, dates_BON_z, tau_star_BON_z, 'ZetaSpreads');

[months_IT_z, slope_IT_z, time_IT_z, spread_IT_z] = buildMonthlyIndicators(eon_t0, dates_BTP_z, tau_star_BTP_z, slopeSign_BTP_z, spread10y_BTP_z);
[months_ES_z, slope_ES_z, time_ES_z, spread_ES_z] = buildMonthlyIndicators(eon_t0, dates_BON_z, tau_star_BON_z, slopeSign_BON_z, spread10y_BON_z);

[FSI_euro_z, FSI_italy_z, FSI_spain_z] = computeEuroFSI(months_IT_z, slope_IT_z, time_IT_z, spread_IT_z, months_ES_z, slope_ES_z, time_ES_z, spread_ES_z);

spread10y_plot_BTP_z = computeRawSpread10y(Spreads_BTP, 'ZetaSpreads');
spread10y_plot_BON_z = computeRawSpread10y(Spreads_BON, 'ZetaSpreads');

plotFSI(FSI_italy_z, FSI_spain_z, FSI_euro_z, eon_t0, spread10y_plot_BTP_z, eon_t0, spread10y_plot_BON_z, 'Zeta');
save('Part_E.mat', 'FSI_euro_z', 'FSI_italy_z', 'FSI_spain_z');
fprintf('=== Part E Complete ===\n');
%% Comparison ASW vs Zeta spread
plotASWvsZeta(dates_BTP, spread10y_BTP, dates_BTP_z, spread10y_BTP_z, dates_BON, spread10y_BON, dates_BON_z, spread10y_BON_z);
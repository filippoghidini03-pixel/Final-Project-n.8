%% Run_project_8.m
% The purpose of this project is to build a Financial Stress Index
% successively with ASW spread and Zeta spread over EONIA from italian and spanish bonds.
% We will proceed in 4 steps:
%   1. Bootstrap the EONIA curve and filter the data for bonds.
%   2. Compute ASW spread and Zeta spread over EONIA for the 2 countries.
%   3. Construct the best fit of ASW and Zeta spreads for a straight line broken in one point.
%   4. Build the FSI.

clear all; 
close all; 
clc;

% Importing paths for our functions
addpath('Data')
addpath('Utilities A')
addpath('Utilities B')
addpath('Utilities C')
addpath('Utilities D')
addpath('Other Utilities')

%% PARAMETERS
param = initParameters();

%% PART A - Boostrap and data filtering.
fprintf('=== PART A ===\n');

%Bootstrap of EONIA curve
OIS_raw  = readOISdata(param.fileOIS, param.t1, param.tN, param.maxTenorYears);
[Dates, Discounts, Rates] = bootstrapEONIA(OIS_raw, param.settleLag);

% Builds the EONIA and bond vectors. A first bond selection was done
% manually, just keeping those with fixed coupons and in range [01/01/1999,tN].
EONIA    = buildEONIAstruct(Dates, Discounts, Rates);
bond_BTP = buildBondStruct(param.fileBTP, param.t1, param.tN);
bond_BON = buildBondStruct(param.fileBON, param.t1, param.tN);

% Plots EONIA discount curve from OIS dataset. Since we compute around 2300 curves, 
% we only plot 5 of them to have a first impression on how the curve evolves over time.
plotEONIA(EONIA, []);
save('Part_A.mat', 'EONIA', 'bond_BTP', 'bond_BON');
fprintf('BTPs: %d | BONOs: %d\n=== Part A Complete ===\n\n', length(bond_BTP), length(bond_BON));

%% PART B - Compute the ASW spreads over time from italian (BTP) and spanish (BONOS) bond. 
fprintf('=== PART B ===\n');
[Spreads_BTP, Spreads_BON] = computeASWspreads(EONIA, bond_BTP, bond_BON);
save('Part_B.mat', 'Spreads_BTP', 'Spreads_BON');
fprintf('=== Part B Complete ===\n\n');

%% PART C - Best fit of ASW Spreads for a straight line broken in one point.  
fprintf('=== PART C ===\n');
eon_t0 = arrayfun(@(x) x.Dates(1), EONIA);

% Filter the months when ASW spread is constantly below 20 bps.
[Spreads_BTP_filt, dates_BTP] = filterMonths(Spreads_BTP, eon_t0, 20, 50);
[Spreads_BON_filt, dates_BON] = filterMonths(Spreads_BON, eon_t0, 20, 50);

% Compute the broken line evolution with least square methods.
[tau_star_BTP, L_star_BTP] = computeBrokenLineEvolution(Spreads_BTP_filt, dates_BTP);
[tau_star_BON, L_star_BON] = computeBrokenLineEvolution(Spreads_BON_filt, dates_BON);

plotBreakpointEvolution(dates_BTP, tau_star_BTP, dates_BON, tau_star_BON);
fprintf('=== Part C Complete ===\n\n');

%% PART D - Builds and plots the Financial Stress Index with the ASW spread.
fprintf('=== PART D ===\n');

% Computes for italian and spanish bonds the slope and spread.
[slopeSign_BTP, spread10y_BTP] = computeSlopeAndSpread(Spreads_BTP_filt, dates_BTP, tau_star_BTP, 'ASWSpreads');
[slopeSign_BON, spread10y_BON] = computeSlopeAndSpread(Spreads_BON_filt, dates_BON, tau_star_BON, 'ASWSpreads');

% Builds for italian and spanish bonds the monthly indicator.
[months_IT, slope_IT, time_IT, spread_IT] = buildMonthlyIndicators(eon_t0, dates_BTP, tau_star_BTP, slopeSign_BTP, spread10y_BTP);
[months_ES, slope_ES, time_ES, spread_ES] = buildMonthlyIndicators(eon_t0, dates_BON, tau_star_BON, slopeSign_BON, spread10y_BON);

% Aggregates the previous results to build the FSI on the euro area, with the ASW spread.
[FSI_euro, FSI_italy, FSI_spain] = computeEuroFSI(months_IT, slope_IT, time_IT, spread_IT, months_ES, slope_ES, time_ES, spread_ES);

% Compute 10y spreads and plots the FSI.
spread10y_plot_BTP = computeRawSpread10y(Spreads_BTP, 'ASWSpreads');
spread10y_plot_BON = computeRawSpread10y(Spreads_BON, 'ASWSpreads');
plotFSI(FSI_italy, FSI_spain, FSI_euro, eon_t0, spread10y_plot_BTP, eon_t0, spread10y_plot_BON, 'ASW');
save('Part_D.mat', 'FSI_euro', 'FSI_italy', 'FSI_spain');
fprintf('=== Part D Complete ===\n');
%% PART E - Aggregates parts C and D for Zeta spread.
fprintf('=== PART E ===\n');

% Filter the months when ASW spread is constantly below 20 bps.
[Spreads_BTP_filt_z, dates_BTP_z] = filterMonths(Spreads_BTP, eon_t0, 20, 50, 'ZetaSpreads');
[Spreads_BON_filt_z, dates_BON_z] = filterMonths(Spreads_BON, eon_t0, 20, 50, 'ZetaSpreads');

% Compute the broken line evolution with least square methods.
[tau_star_BTP_z, ~] = computeBrokenLineEvolution(Spreads_BTP_filt_z, dates_BTP_z, 'ZetaSpreads');
[tau_star_BON_z, ~] = computeBrokenLineEvolution(Spreads_BON_filt_z, dates_BON_z, 'ZetaSpreads');

% Computes for italian and spanish bonds the slope and spread.
[slopeSign_BTP_z, spread10y_BTP_z] = computeSlopeAndSpread(Spreads_BTP_filt_z, dates_BTP_z, tau_star_BTP_z, 'ZetaSpreads');
[slopeSign_BON_z, spread10y_BON_z] = computeSlopeAndSpread(Spreads_BON_filt_z, dates_BON_z, tau_star_BON_z, 'ZetaSpreads');

% Builds for italian and spanish bonds the monthly indicator.
[months_IT_z, slope_IT_z, time_IT_z, spread_IT_z] = buildMonthlyIndicators(eon_t0, dates_BTP_z, tau_star_BTP_z, slopeSign_BTP_z, spread10y_BTP_z);
[months_ES_z, slope_ES_z, time_ES_z, spread_ES_z] = buildMonthlyIndicators(eon_t0, dates_BON_z, tau_star_BON_z, slopeSign_BON_z, spread10y_BON_z);

% Aggregates the previous results to build the FSI on the euro area, with the ASW spread.
[FSI_euro_z, FSI_italy_z, FSI_spain_z] = computeEuroFSI(months_IT_z, slope_IT_z, time_IT_z, spread_IT_z, months_ES_z, slope_ES_z, time_ES_z, spread_ES_z);

% Compute 10y spreads and plots the FSI.
spread10y_plot_BTP_z = computeRawSpread10y(Spreads_BTP, 'ZetaSpreads');
spread10y_plot_BON_z = computeRawSpread10y(Spreads_BON, 'ZetaSpreads');
plotFSI(FSI_italy_z, FSI_spain_z, FSI_euro_z, eon_t0, spread10y_plot_BTP_z, eon_t0, spread10y_plot_BON_z, 'Zeta');
save('Part_E.mat', 'FSI_euro_z', 'FSI_italy_z', 'FSI_spain_z');
fprintf('=== Part E Complete ===\n');

%% Comparison ASW vs Zeta spread and analyzing the 2011-2012 crisis period
plotASWvsZeta(eon_t0, spread10y_plot_BTP, eon_t0, spread10y_plot_BTP_z, eon_t0, spread10y_plot_BON, eon_t0, spread10y_plot_BON_z);

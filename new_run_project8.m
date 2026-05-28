%% Run_project_8.m
% Main script for Project 8
clear;
close all;
clc;

addpath('Data')
addpath('Utilities A')
addpath('Utilities B')
addpath('Utilities C')
addpath('Utilities D')

%% GLOBAL PARAMETERS INITIALIZATION
param = initParameters();

%% PART A
fprintf('=== PART A.1: Reading OIS data & Bootstrapping EONIA curve ===\n');
OIS_raw = readOISdata(param.fileOIS, param.t1, param.tN, param.maxTenorYears);
fprintf('Read %d business days of OIS rates.\n', length(OIS_raw));
[Dates, Discounts, Rates] = bootstrapEONIA(OIS_raw, param.settleLag);

fprintf('=== PART A.4: Building EONIA struct ===\n');
EONIA = buildEONIAstruct(Dates, Discounts, Rates);
plotEONIA(EONIA, []);

fprintf('=== PART A.4: Building BTP struct ===\n');
bond_BTP = buildBondStruct(param.fileBTP, param.t1, param.tN);
fprintf('BTPs kept: %d\n', length(bond_BTP));

fprintf('=== PART A.4: Building BONO struct ===\n');
bond_BON = buildBondStruct(param.fileBON, param.t1, param.tN);
fprintf('BONOs kept: %d\n', length(bond_BON));

fprintf('=== PART A.4: Saving results ===\n');
save('Part_A.mat', 'EONIA', 'bond_BTP', 'bond_BON');
fprintf('=== Part A Complete ===\n\n');

%% PART B
fprintf('=== PART B: Computing ASW and Zeta spreads ===\n');
[Spreads_BTP, Spreads_BON] = computeASWspreads(EONIA, bond_BTP, bond_BON);

fprintf('=== PART B: Saving results ===\n');
save('Part_B.mat', 'Spreads_BTP', 'Spreads_BON');
fprintf('=== Part B Complete ===\n\n');

%% PART C
fprintf('=== PART C: Segmented regression on ASW spreads ===\n');
 
nDates = length(EONIA);
eon_t0 = arrayfun(@(x) x.Dates(1), EONIA);
 
[months_IT, slope_IT, time_IT, spread_IT] = aggregateMonthly(eon_t0, Spreads_BTP);
[months_ES, slope_ES, time_ES, spread_ES] = aggregateMonthly(eon_t0, Spreads_BON);
 
fprintf('=== PART C: Saving results ===\n');
save('Part_C.mat', 'months_IT', 'slope_IT', 'time_IT', 'spread_IT', ...
                   'months_ES', 'slope_ES', 'time_ES', 'spread_ES');
fprintf('=== Part C Complete ===\n\n');
 
%% PART D — Financial Stress Index
fprintf('=== PART D: Computing Financial Stress Index ===\n');
[FSI_euro, FSI_italy, FSI_spain] = computeEuroFSI( ...
    months_IT, slope_IT, time_IT, spread_IT, ...
    months_ES, slope_ES, time_ES, spread_ES);
 
fprintf('=== PART D: Plotting FSI ===\n');
plotFSI(FSI_italy, FSI_spain, FSI_euro);
 
fprintf('=== PART D: Saving results ===\n');
save('Part_D.mat', 'FSI_euro', 'FSI_italy', 'FSI_spain');
fprintf('=== Part D Complete ===\n\n');
 
fprintf('=== PROJECT 8 COMPLETE ===\n');

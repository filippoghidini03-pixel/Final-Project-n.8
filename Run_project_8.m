%% Run_project_8.m
% Main script for Project 8 
clear; 
close all; 
clc;

addpath('Data')
addpath('Utilities A')
%% GLOBAL PARAMETERS INITIALIZATION
param = initParameters();

%% PART A
%  A.1: Read OIS data and bootstrap EONIA curve
fprintf('=== PART A.1: Reading OIS data & Bootstrapping EONIA curve ===\n');
OIS_raw = readOISdata(param.fileOIS, param.t1, param.tN, param.maxTenorYears);
fprintf('Read %d business days of OIS rates.\n', length(OIS_raw));
[Dates, Discounts, Rates] = bootstrapEONIA(OIS_raw, param.settleLag);

% Part A.3-A.4: Filtering and building the struct
fprintf('=== PART A.4: Building EONIA struct ===\n');
EONIA = buildEONIAstruct(Dates, Discounts, Rates);
fprintf('Bootstrap complete for %d dates.\n', length(EONIA));
plotEONIA(EONIA, []);

fprintf('=== PART A.4: Building BTP struct ===\n');
bond_BTP = buildBondStruct(param.fileBTP, param.t1, param.tN);
fprintf('BTPs kept: %d\n', length(bond_BTP));
 
fprintf('=== PART A.4: Building BONO struct ===\n');
bond_BON = buildBondStruct(param.fileBON, param.t1, param.tN);
fprintf('BONOs kept: %d\n', length(bond_BON));
 
% Save compiled database
fprintf('=== PART A.4: Saving results ===\n');
save('project8_data.mat', 'EONIA', 'bond_BTP', 'bond_BON');
fprintf('Saved to project8_data.mat\n\n=== Part A Complete ===\n');
vector=bond_BTP(end-1).pricesCleanValues;

%% PART B
%  B.1-B.2: Compute ASW spread and Zeta spread over EONIA for each bond/date
fprintf('\n=== PART B: Computing ASW and Zeta spreads ===\n');
addpath('Utilities A')

[Spreads_BTP, Spreads_BON] = computeASWspreads(EONIA, bond_BTP, bond_BON);

% B.3: Save results
fprintf('=== PART B: Saving spread results ===\n');
save('project8_spreads.mat', 'Spreads_BTP', 'Spreads_BON');
fprintf('Saved to project8_spreads.mat\n\n=== Part B Complete ===\n');

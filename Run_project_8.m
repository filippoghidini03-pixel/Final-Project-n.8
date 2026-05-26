%% Run_project_8.m
% Main script for Project 8 
clear all; 
close all; 
clc;

addpath('Data')
addpath('Utilities A')
addpath('Utilities B')
addpath('Utilities C')
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
plotEONIA(EONIA, []);

fprintf('=== PART A.4: Building BTP struct ===\n');
bond_BTP = buildBondStruct(param.fileBTP, param.t1, param.tN);
fprintf('BTPs kept: %d\n', length(bond_BTP));
 
fprintf('=== PART A.4: Building BONO struct ===\n');
bond_BON = buildBondStruct(param.fileBON, param.t1, param.tN);
fprintf('BONOs kept: %d\n', length(bond_BON));
 
% Save compiled database
fprintf('=== PART A.4: Saving results ===\n');
save('Part_A.mat', 'EONIA', 'bond_BTP', 'bond_BON');
fprintf('=== Part A Complete ===\n');
vector=bond_BTP(end-1).pricesDates;

%% PART B
%  B.1-B.2: Compute ASW spread and Zeta spread over EONIA for each bond/date
fprintf('\n=== PART B: Computing ASW and Zeta spreads ===\n');

[Spreads_BTP, Spreads_BON] = computeASWspreads(EONIA, bond_BTP, bond_BON);

% B.3: Save results
fprintf('=== PART B: Saving spread results ===\n');
save('project8_spreads.mat', 'Spreads_BTP', 'Spreads_BON');
fprintf('Saved to project8_spreads.mat\n\n=== Part B Complete ===\n');

%% PART C
fprintf('\n=== PART C: Data Filtering and Broken Line Fitting ===\n');

% Estraiamo il vettore dei t0 di riferimento da EONIA
eon_t0 = arrayfun(@(x) x.Dates(1), EONIA);

% 1. DATA FILTERING (Il patch ora agisce internamente alla funzione)
fprintf('Filtering BTP spreads...\n');
Spreads_BTP_filt = filterMonths(Spreads_BTP, eon_t0, 20, 50);

fprintf('Filtering BONO spreads...\n');
Spreads_BON_filt = filterMonths(Spreads_BON, eon_t0, 20, 50);

% 2. TIME-SERIES BROKEN LINE FITTING (Tramite la nuova funzione dedicata)
fprintf('Fitting Broken Line for BTPs...\n');
[tau_star_BTP, L_star_BTP, dates_BTP] = computeBrokenLineEvolution(Spreads_BTP_filt);

fprintf('Fitting Broken Line for BONOs...\n');
[tau_star_BON, L_star_BON, dates_BON] = computeBrokenLineEvolution(Spreads_BON_filt);

% 3. PLOTTING (Grafica finale isolata)
fprintf('Plotting results...\n');
plotBreakpointEvolution(dates_BTP, tau_star_BTP, dates_BON, tau_star_BON);

fprintf('=== Part C Complete ===\n');
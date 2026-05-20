%% Run_project_8.m
% Main script for Project 8 - ASW Spread on BTPs and BONOs
% Financial Engineering - Politecnico di Milano
clear; close all; clc;

%%  PARAMETERS

% Date range for the analysis
t1 = datenum('01/01/2007', 'dd/mm/yyyy');
tN = datenum('31/12/2015', 'dd/mm/yyyy');

% Settlement lag (in business days)
settleLag = 2;

% OIS bootstrap: use tenors up to 10y only 
maxTenorYears = 10;

% File paths
fileOIS   = 'INPUT_OIS_curves.xlsx';
fileBTP   = 'INPUT_BTP_Dirty.xlsx';
fileBON   = 'INPUT_BON.xlsx';

%% PART A.1 — Read OIS data and bootstrap EONIA curve

fprintf('=== PART A.1: Reading OIS data ===\n');
OIS_raw = readOISdata(fileOIS, t1, tN, maxTenorYears);
fprintf('  Read %d business days of OIS rates.\n', length(OIS_raw));

fprintf('=== PART A.1: Bootstrapping EONIA curve ===\n');
EONIA = bootstrapEONIA(OIS_raw, settleLag);
fprintf('  Bootstrap complete for %d dates.\n', length(EONIA));

plotEONIA(EONIA, []);


%% =========================================================
%  PART A.2-A.4 — Read and build bond struct arrays
%=========================================================
 
fprintf('=== PART A.2-A.4: Building BTP struct ===\n');
bond_BTP = buildBondStruct(fileBTP, t1, tN);
fprintf('  BTPs kept: %d\n', length(bond_BTP));
 
fprintf('=== PART A.2-A.4: Building BONO struct ===\n');
bond_BON = buildBondStruct(fileBON, t1, tN);
fprintf('  BONOs kept: %d\n', length(bond_BON));
 
%% =========================================================
%  PART A.4 — Save .mat file
% =========================================================
 
fprintf('=== PART A.4: Saving results ===\n');
save('project8_data.mat', 'EONIA', 'bond_BTP', 'bond_BON');
fprintf('  Saved to project8_data.mat\n');

%%
load('project8_data.mat');
for i = 1 : length(bond_BTP)
    bond_BTP(i).pricesCleanValues = filter_prices(bond_BTP(i).pricesCleanValues);
end
%%
vector=bond_BTP(end - 1).pricesCleanValues;

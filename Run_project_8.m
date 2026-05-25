%% Run_project_8.m
% Main script for Project 8 
clear; 
close all; 
clc;

addpath('Data')
addpath('Utilities A')
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
vector=bond_BTP(end-1).pricesDirtyValues;
%% PART C
% Prov per la parte C

s = [ ...
  12.34, 15.67, 18.91, 14.22, 11.45, 19.88, 21.34, 17.56, 13.78, 16.90, ...
  20.11, 22.45, 18.67, 14.89, 12.01, 15.23, 17.45, 19.67, 21.89, 23.10, ...
  16.32, 14.54, 13.76, 15.98, 18.20, 20.42, 22.64, 24.86, 19.08, 17.30, ...
  15.52, 13.74, 11.96, 14.18, 16.40, 18.62, 20.84, 23.06, 25.28, 21.50, ...
  19.72, 17.94, 16.16, 14.38, 12.60, 10.82, 13.04, 15.26, 17.48, 19.70, ...
  21.92, 24.14, 26.36, 22.58, 20.80, 19.02, 17.24, 15.46, 13.68, 11.90, ...
  14.12, 16.34, 18.56, 20.78, 23.00, 25.22, 27.44, 23.66, 21.88, 20.10, ...
  18.32, 16.54, 14.76, 12.98, 15.20, 17.42, 19.64, 21.86, 24.08, 26.30, ...
  28.52, 24.74, 22.96, 21.18, 19.40, 17.62, 15.84, 14.06, 16.28, 18.50, ...
  20.72, 22.94, 25.16, 27.38, 29.60, 25.82, 24.04, 22.26, 20.48, 18.70, ...
  16.92, 15.14, 17.36, 19.58, 21.80, 24.02, 26.24 ];
nDates = length(EONIA);
% Genera numeri casuali (es. spread tra 10 e 150 basis points) lunghi quanto T
% Pre-allochiamo il vettore per la massima velocità


for i = 1 : nDates
    % Entra nel giorno 'i', va nel vettore 'Dates' e prende solo la riga 1
    T(i) = EONIA(i).Dates(1); 
end
s = 10 + 140 * rand(size(T))/100; 
[tau_star, L_star] = fitBrokenLine(T, s)
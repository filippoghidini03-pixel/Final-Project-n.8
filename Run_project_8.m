%% Run_project_8.m
% Main script for Project 8 - ASW Spread on BTPs and BONOs
% Financial Engineering - Politecnico di Milano
%
% References:
%   [1] Baviera & Cassaro (2015), Mr. Crab's Bootstrap, AMF 22, 105-132
%   [2] Baviera & Lebovitz (2015), A sovereign bond based index for
%       financial instability in the euro zone, Mimeo

clear; close all; clc;

%%  PARAMETERS


% Date range for the analysis
t1 = datenum('01/01/2007', 'dd/mm/yyyy');
tN = datenum('31/12/2015', 'dd/mm/yyyy');

% Settlement lag (in business days)
settleLag = 2;

% OIS bootstrap: use tenors up to 10y only (as per project specs)
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

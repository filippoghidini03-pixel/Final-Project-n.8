function param = initParameters()
% INITPARAMETERS  Initializes all global evaluation parameters and file paths.
%
%   OUTPUT:
%     param : A structure containing dates, lags, limits, and filenames.

    % --- Analysis Date Range ---
    param.t1 = datenum('01/01/2007', 'dd/mm/yyyy');
    param.tN = datenum('31/12/2015', 'dd/mm/yyyy');

    % --- Market Conventions & Limits ---
    param.settleLag     = 2;   % Settlement lag in business days
    param.maxTenorYears = 10;  % Maximum OIS tenor maturity used in bootstrap

    % --- Input File Paths ---
    param.fileOIS = 'INPUT_OIS_curves.xlsx';
    param.fileBTP = 'INPUT_BTP_Dirty.xlsx';
    param.fileBON = 'INPUT_BON.xlsx';

end
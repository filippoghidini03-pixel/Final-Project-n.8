function [FSI_euro, FSI_italy, FSI_spain] = computeEuroFSI( ...
    months_IT, slope_IT, time_IT, spread_IT, ...
    months_ES, slope_ES, time_ES, spread_ES)
%
%   INPUTS:
%       months_IT, months_ES - Vectors of datenums representing the months.
%       slope_IT, slope_ES   - Struct arrays containing daily slope signs.
%       time_IT, time_ES     - Vectors of monthly average optimal breakpoints (tau*).
%       spread_IT, spread_ES - Struct arrays of monthly 10Y spread metrics.
%
%   OUTPUTS:
%       FSI_euro             - Struct array for the composite Eurozone FSI.
%       FSI_italy            - Struct array for the Italian FSI.
%       FSI_spain            - Struct array for the Spanish FSI.
%
%       Each output struct array contains the following fields:
%           * month : The reference date (datenum).
%           * value : The numeric stress level (0 = Green, 1 = Yellow, 2 = Red).
%           * color : A string representing the stress state.

    % Compute country-level FSIs
    FSI_italy = computeFSI(months_IT, slope_IT, time_IT, spread_IT);
    FSI_spain = computeFSI(months_ES, slope_ES, time_ES, spread_ES);
    
    M        = length(months_IT);
    colorMap = {'Green', 'Yellow', 'Red'};
    
    % Initialize the Eurozone FSI struct array
    FSI_euro = struct('month', cell(M,1), 'value', cell(M,1), 'color', cell(M,1));
    
    % Vectorized extraction and element-wise maximum (Baviera-Lebovitz Eq. 1)
    val = max([FSI_italy.value]', [FSI_spain.value]');
    
    % Map the values back to the struct array and assign colors
    for m = 1:M
        FSI_euro(m).month = months_IT(m);
        FSI_euro(m).value = val(m);
        FSI_euro(m).color = colorMap{val(m) + 1}; % +1 because values are 0, 1, 2
    end
end
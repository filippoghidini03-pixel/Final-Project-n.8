function [FSI_euro, FSI_italy, FSI_spain] = computeEuroFSI( ...
    months_IT, slope_IT, time_IT, spread_IT, ...
    months_ES, slope_ES, time_ES, spread_ES)

%Compute country-level FSIs 
FSI_italy = computeFSI(months_IT, slope_IT, time_IT, spread_IT);
FSI_spain = computeFSI(months_ES, slope_ES, time_ES, spread_ES);

% Align on common months, use Italy months as reference (should be identical to Spain months)
M = length(months_IT);
FSI_euro = struct('month', cell(M,1), 'value', cell(M,1), 'color', cell(M,1));

colorMap = {'Green', 'Yellow', 'Red'};

for m = 1 : M
    % Find corresponding Spain month (match by date)
    [~, idx] = min(abs([FSI_spain.month] - months_IT(m)));

    val_IT = FSI_italy(m).value;
    val_ES = FSI_spain(idx).value;

    val_euro = max(val_IT, val_ES);   % Eq.(1) of [2]

    FSI_euro(m).month = months_IT(m);
    FSI_euro(m).value = val_euro;
    FSI_euro(m).color = colorMap{val_euro + 1};
end

end 
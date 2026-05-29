function [FSI_euro, FSI_italy, FSI_spain] = computeEuroFSI( ...
    months_IT, slope_IT, time_IT, spread_IT, ...
    months_ES, slope_ES, time_ES, spread_ES)

FSI_italy = computeFSI(months_IT, slope_IT, time_IT, spread_IT);
FSI_spain = computeFSI(months_ES, slope_ES, time_ES, spread_ES);

M        = length(months_IT);
colorMap = {'Green', 'Yellow', 'Red'};
FSI_euro = struct('month', cell(M,1), 'value', cell(M,1), 'color', cell(M,1));

val = max([FSI_italy.value]', [FSI_spain.value]');

for m = 1:M
    FSI_euro(m).month = months_IT(m);
    FSI_euro(m).value = val(m);
    FSI_euro(m).color = colorMap{val(m) + 1};
end

end
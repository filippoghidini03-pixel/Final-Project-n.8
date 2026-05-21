function EONIA = buildEONIAstruct(allDatesOut, PDout, ratesOut)
% BUILDEONIASTRUCT  Packages bootstrap results into the EONIA struct array.

nDates = length(allDatesOut);
EONIA  = struct('Dates',           cell(nDates, 1), ...
                'Rates',           cell(nDates, 1), ...
                'DiscountFactors', cell(nDates, 1));

for i = 1 : nDates
    EONIA(i).Dates           = allDatesOut{i};
    EONIA(i).Rates           = [NaN; ratesOut{i}];
    EONIA(i).DiscountFactors = PDout{i};
end

end
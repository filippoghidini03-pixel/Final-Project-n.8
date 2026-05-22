function EONIA = buildEONIAstruct(allDatesOut, PDout, ratesOut)
% BUILDEONIASTRUCT Packages the bootstrap results into an EONIA struct array.
%
% INPUTS:
%   allDatesOut - Cell array (nDates x 1) where each cell contains a vector 
%                 of dates for the bootstrapped curve.
%   PDout       - Cell array (nDates x 1) where each cell contains a vector 
%                 of Discount Factors.
%   ratesOut    - Cell array (nDates x 1) where each cell contains a vector 
%                 of calculated rates (e.g., zero rates).
%
% OUTPUT:
%   EONIA       - A struct array of length nDates containing the following fields:
%                 * Dates: Vector of node dates.
%                 * Rates: Vector of rates (with NaN at the first index).
%                 * DiscountFactors: Vector of discount factors.

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
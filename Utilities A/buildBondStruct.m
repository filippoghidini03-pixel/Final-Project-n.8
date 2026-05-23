function bond = buildBondStruct(filename, t1, tN)
% BUILDBONDSTRUCT Reads bond data from an Excel file and builds a structured array.
%
% INPUTS:
%   filename - String or char array specifying the name of the Excel file 
%              (e.g., 'INPUT_BON.xlsx').
%   t1       - Start date of the observation period (MATLAB datenum).
%   tN       - End date of the observation period (MATLAB datenum).
%
% OUTPUT:
%   bond     - A struct array containing the processed data for each valid bond.
%              Fields for each struct:
%              * BBGname: Bloomberg ticker of the bond.
%              * settleDate: Settlement date (datenum).
%              * expDate: Maturity/Expiration date (datenum).
%              * firstCouponDate: Date of the very first coupon (datenum).
%              * couponValue: Annual coupon rate (e.g., 4.5 for 4.5%).
%              * couponFrequency: Number of coupon payments per year.
%              * pricesDates: Vector of valid historical trade dates (datenum).
%              * pricesCleanValues: Vector of historical clean prices.
%              * pricesDirtyValues: Vector of computed dirty prices.

EXCEL_BASE = datenum('30/12/1899', 'dd/mm/yyyy');

info = readcell(filename, 'Sheet', 'Info');
data = readcell(filename, 'Sheet', 'Data');

% Normalize Data: datetime -> datenum, invalid/empty -> NaN 
isDT = cellfun(@isdatetime, data);
data(isDT) = cellfun(@(x) datenum(x), data(isDT), 'UniformOutput', false);
isInvalid  = cellfun(@(x) (~isnumeric(x) && ~ischar(x)) || (isnumeric(x) && isempty(x)), data);
data(isInvalid) = {NaN};

% Detect stride and build bond-column map based on 'PX_DIRTY_MID' presence
hasDirty = any(cellfun(@(x) ischar(x) && strcmpi(strtrim(x), 'PX_DIRTY_MID'), data(2,:)));
stride   = 3 + hasDirty;

dataMap = containers.Map();
for c = 1:stride:size(data, 2)
    name = data{1, c};
    if ~ischar(name) || isempty(name), break; end
    dataMap(strtrim(name)) = c;
end

bond      = struct('BBGname',{}, 'settleDate',{}, 'expDate',{}, ...
                   'firstCouponDate',{}, 'couponValue',{}, 'couponFrequency',{}, ...
                   'pricesDates',{}, 'pricesCleanValues',{}, 'pricesDirtyValues',{});
nKept     = 0;
priceRows = data(3:end, :);

% Clean remaining text cells (like '#N/A') by forcing them to NaN to prevent cell2mat crashes
isNonNumeric = ~cellfun(@isnumeric, priceRows);
priceRows(isNonNumeric) = {NaN};

for r = 3:size(info, 1)
    bbg = info{r, 1};
    if ~ischar(bbg) || isempty(bbg), continue; end
    bbg = strtrim(bbg);
    if ~isKey(dataMap, bbg), continue; end
    
    sc         = dataMap(bbg);
    settleDate = datenum(info{r, 2}, 'dd/mm/yyyy');
    expDate    = datenum(info{r, 3}, 'dd/mm/yyyy');
    firstCpn   = datenum(info{r, 4}, 'dd/mm/yyyy');
    cpnValue   = info{r, 6};
    cpnFreq    = info{r, 7};
    
    % Extract full columns as numeric arrays [vectorized]
    dArr  = cell2mat(priceRows(:, sc));
    clArr = cell2mat(priceRows(:, sc + 1));
    
    % Convert Excel serials to Matlab datenums [vectorized]
    mask = ~isnan(dArr) & dArr < 50000;
    dArr(mask) = dArr(mask) + EXCEL_BASE;
    
    % Keep only valid observations strictly within [t1, tN] [vectorized]
    valid = ~isnan(dArr) & ~isnan(clArr) & dArr >= t1 & dArr <= tN;
    
    dates       = dArr(valid);
    cleanPrices = clArr(valid);
    if isempty(dates), continue; end
    
    [dates, idx] = sort(dates);
    cleanPrices  = cleanPrices(idx);
    
    % Dirty = clean + accrued [vectorized inside] 
    % Passing firstCpn perfectly integrates with the math-based computeAccrual
    
    dirtyPrices = cleanPrices + computeAccrual(dates, firstCpn, cpnValue, cpnFreq);
    
    nKept = nKept + 1;
    bond(nKept).BBGname           = bbg;
    bond(nKept).settleDate        = settleDate;
    bond(nKept).expDate           = expDate;
    bond(nKept).firstCouponDate   = firstCpn;
    bond(nKept).couponValue       = cpnValue;
    bond(nKept).couponFrequency   = cpnFreq;
    bond(nKept).pricesDates       = dates;
    bond(nKept).pricesCleanValues = cleanPrices;
    bond(nKept).pricesDirtyValues = dirtyPrices;
end

fprintf('  Bonds kept: %d\n', nKept);
end
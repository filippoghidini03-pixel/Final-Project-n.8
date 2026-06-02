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

info = readcell(filename, 'Sheet', 'Info');
data = readcell(filename, 'Sheet', 'Data');

EXCEL_BASE = datenum('30/12/1899', 'dd/mm/yyyy');

% Check how dates are imported from Excel and replace any gaps 
% or invalid formats with NaNs
isDT = cellfun(@isdatetime, data);
data(isDT) = cellfun(@(x) datenum(x), data(isDT), 'UniformOutput', false);

isInvalid  = cellfun(@(x) (~isnumeric(x) && ~ischar(x)) || (isnumeric(x) && isempty(x)), data);
data(isInvalid) = {NaN};

% Determine the column stride (number of columns) between one bond and the next
hasDirty = any(cellfun(@(x) ischar(x) && strcmpi(strtrim(x), 'PX_DIRTY_MID'), data(2,:)));
stride   = 3 + hasDirty;

% Build a map of the bonds, very useful for quickly looking up bond column indices
dataMap = containers.Map();
for c = 1:stride:size(data, 2)
    name = data{1, c};
    if ~ischar(name) || isempty(name) 
        break; 
    end
    dataMap(strtrim(name)) = c;
end

% Initialize the output struct array
bond      = struct('BBGname',{}, 'settleDate',{}, 'expDate',{}, ...
                   'firstCouponDate',{}, 'couponValue',{}, 'couponFrequency',{}, ...
                   'pricesDates',{}, 'pricesCleanValues',{}, 'pricesDirtyValues',{});
nKept     = 0;

% We only want numerical data; skip the first two header rows
priceRows = data(3:end, :);

% Clean remaining text cells by forcing them to NaN to avoid crashes
isNonNumeric = ~cellfun(@isnumeric, priceRows);
priceRows(isNonNumeric) = {NaN};

% Start reading the info sheet from row 3 (skipping headers)
for r = 3:size(info, 1)
    
    % Get the bond ticker from the first column of the info sheet
    bbg = info{r, 1};
    
    % If the cell is empty or the ticker is not in the map, skip to the next
    if ~ischar(bbg) || isempty(bbg) 
        continue; 
    end
    bbg = strtrim(bbg);
    
    if ~isKey(dataMap, bbg)
        continue; 
    end
    
    sc         = dataMap(bbg);
    settleDate = datenum(info{r, 2}, 'dd/mm/yyyy');
    expDate    = datenum(info{r, 3}, 'dd/mm/yyyy');
    firstCpn   = datenum(info{r, 4}, 'dd/mm/yyyy');
    cpnValue   = info{r, 6};
    cpnFreq    = info{r, 7};
    
    % Extract full columns as numeric arrays 
    dArr  = cell2mat(priceRows(:, sc));
    clArr = cell2mat(priceRows(:, sc + 1));
    
    % Convert Excel serials to Matlab datenums 
    mask = ~isnan(dArr) & dArr < 50000;
    dArr(mask) = dArr(mask) + EXCEL_BASE;
    
    % Keep only valid observations strictly within [t1, tN] 
    valid = ~isnan(dArr) & ~isnan(clArr) & dArr >= t1 & dArr <= tN;
    
    dates       = dArr(valid);
    cleanPrices = clArr(valid);
    
    if isempty(dates) 
        continue; 
    end
    
    [dates, idx] = sort(dates);
    cleanPrices  = cleanPrices(idx);
    
    % Dirty = clean + accrued  
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
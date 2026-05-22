function bond = buildBondStruct(filename, t1, tN)
% BUILDBONDSTRUCT  Reads Info and Data sheets, builds bond struct.
%   Dirty price = clean price + accrued interest (30/360)

EXCEL_BASE = datenum('30/12/1899', 'dd/mm/yyyy');

info = readcell(filename, 'Sheet', 'Info');
data = readcell(filename, 'Sheet', 'Data');

% Normalize Data: datetime -> datenum, invalid/empty -> NaN [vectorized]
isDT = cellfun(@isdatetime, data);
data(isDT) = cellfun(@(x) datenum(x), data(isDT), 'UniformOutput', false);
isInvalid  = cellfun(@(x) (~isnumeric(x) && ~ischar(x)) || (isnumeric(x) && isempty(x)), data);
data(isInvalid) = {NaN};

% Detect stride and build bond-column map
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
    
    % Keep only valid observations in [t1, tN] [vectorized] - PULITO, NESSUN FILTRO STRANO
    valid = ~isnan(dArr) & ~isnan(clArr) & dArr >= t1 & dArr <= tN;
    
    dates       = dArr(valid);
    cleanPrices = clArr(valid);
    if isempty(dates), continue; end
    
    [dates, idx] = sort(dates);
    cleanPrices  = cleanPrices(idx);
    
    % Dirty = clean + accrued [vectorized inside] 
    % TORNATO A firstCpn: Niente più crash di MATLAB sulla scadenza!
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
function bond = buildBondStruct(filename, t1, tN)

% Read Excel sheets directly into cell arrays
info = readcell(filename, 'Sheet', 'Info');
data = readcell(filename, 'Sheet', 'Data');

% Create a simple lookup map: Bloomberg Name -> Row Index
infoMap = containers.Map();
for r = 3 : size(info, 1)
    name = info{r, 1};
    if ischar(name) && ~isempty(name)
        infoMap(strtrim(name)) = r;
    end
end

bond      = [];
nKept     = 0;
excelBase = datenum('30/12/1899', 'dd/mm/yyyy');

% Loop across every column in the Data sheet to find bond start positions
for c = 1 : size(data, 2)
    bbg = data{1, c};
    if ~ischar(bbg) || isempty(bbg), continue; end
    bbg = strtrim(bbg);
    
    % Filters F1 & F2: Verify the bond is present in Info and has FIXED coupons
    if ~isKey(infoMap, bbg), continue; end
    ir = infoMap(bbg);
    if ~strcmpi(strtrim(info{ir, 5}), 'FIXED'), continue; end
    
    % Verify if issue settlement date falls in the correct range
    settleDate = datenum(info{ir, 2}, 'dd/mm/yyyy');
    if settleDate < datenum('01/01/1999', 'dd/mm/yyyy') || settleDate > tN, continue; end
    
    % Read static bond metadata
    expDate  = datenum(info{ir, 3}, 'dd/mm/yyyy');
    firstCpn = datenum(info{ir, 4}, 'dd/mm/yyyy');
    cpnValue = info{ir, 6};
    cpnFreq  = info{ir, 7};
    
    % Identify if an optional dirty price column is provided for this bond
    hasDirty = (c+2 <= size(data, 2)) && ischar(data{2, c+2}) && strcmpi(strtrim(data{2, c+2}), 'PX_DIRTY_MID');
    
    % Slice time series data rows (from row 3 downward)
    rawDates = data(3:end, c);
    rawClean = data(3:end, c+1);
    rawDirty = data(3:end, min(c+2, size(data, 2)));
    
    % Extract and filter chronological pricing records
    dates = []; cleanPrices = []; dirtyPrices = [];
    for r = 1 : length(rawDates)
        d  = rawDates{r};
        cl = rawClean{r};
        
        if isempty(d) || (isnumeric(d) && isnan(d)), continue; end
        if isempty(cl) || (isnumeric(cl) && isnan(cl)), continue; end
        
        % Auto-detect date format: automatically add base offset if it is an Excel serial number
        if isnumeric(d)
            dn = d + (d < 50000) * excelBase;
        else
            continue;
        end
        
        % Retain observations within [t1, tN] window
        if dn < t1 || dn > tN, continue; end
        
        dates(end+1, 1)       = dn;
        cleanPrices(end+1, 1) = cl;
        
        if hasDirty && ~isempty(rawDirty{r}) && ~isnan(rawDirty{r})
            dirtyPrices(end+1, 1) = rawDirty{r};
        else
            dirtyPrices(end+1, 1) = NaN;
        end
    end
    
    if isempty(dates), continue; end
    
    % Sort rows by date ascending
    [dates, sortIdx] = sort(dates);
    cleanPrices      = cleanPrices(sortIdx);
    dirtyPrices      = dirtyPrices(sortIdx);
    
    % Filter price spikes using your custom filter_prices function
    cleanPrices = filter_prices(cleanPrices);
    if hasDirty
        dirtyPrices = filter_prices(dirtyPrices);
    end
    
    % Append into structured output array
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
end % <-- This was the missing end for the main column loop!

fprintf('  Bonds kept successfully: %d\n', nKept);

end
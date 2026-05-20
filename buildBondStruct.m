function bond = buildBondStruct(filename, t1, tN)
% BUILDBONDSTRUCT  Build the bond struct array as required by Part A.4.
%
%   bond = BUILDBONDSTRUCT(filename, t1, tN)
%
%   Constructs a struct array where each element corresponds to one bond
%   passing the filters of Part A.2-A.3. Fields per bond:
%     i)   BBGname           : Bloomberg ID (string)
%     ii)  settleDate        : issue settle date (Matlab datenum)
%     iii) expDate           : maturity date (Matlab datenum)
%     iv)  firstCouponDate   : first coupon date (Matlab datenum)
%     v)   couponValue       : coupon rate in % (e.g. 4.5)
%     vi)  couponFrequency   : coupons per year (1=annual, 2=semi-annual)
%     vii) pricesDates       : [M x 1] Matlab datenums of price observations
%     viii)pricesCleanValues : [M x 1] clean prices
%     ix)  pricesDirtyValues : [M x 1] dirty prices (NaN if unavailable)
%
%   Static info (fields i-vi) is read from the 'Info' sheet.
%   Price time series (fields vii-ix) is read from the 'Data' sheet,
%   matched by Bloomberg ID.
%
%   Filters applied:
%     F1. CPN_TYP = 'FIXED' only
%     F2. FIRST_SETTLE_DT in [01/01/1999, tN]
%     F3. Spike filter on prices: isolated jumps > 50bps replaced by
%         average of neighbours (see [2] Appendix)
%
%   Notes on Data sheet structure (detected automatically):
%     - BTP file: stride=4 cols per bond (Date, PX_LAST, PX_DIRTY_MID, empty)
%     - BON file: stride=3 cols per bond (Date, PX_LAST, empty)
%     - Date columns alternate between Matlab datetime objects (col 0 of
%       each bond) and Excel serial integers (col 4, 8, ...) in BTP file.
%       BON file uses Excel serials throughout.
%     - Bonds in Data sheet are matched to Info by Bloomberg ID (the order
%       differs between the two sheets).
%


EXCEL_BASE       = datenum('30/12/1899', 'dd/mm/yyyy');
DATE_1999        = datenum('01/01/1999', 'dd/mm/yyyy');
SPIKE_THRESHOLD  = 0.50;   % 50 bps

% =========================================================================
% 1. READ INFO SHEET
% =========================================================================
fprintf('  Reading Info sheet from %s...\n', filename);
[~, ~, rawInfo] = xlsread(filename, 'Info');
% Row 1: Bloomberg field names, Row 2: labels, Row 3+: data
infoData = rawInfo(3:end, :);
nInfo    = size(infoData, 1);

% Build lookup: BBGname -> row index in infoData
infoMap = containers.Map();
for r = 1 : nInfo
    name = infoData{r, 1};
    if ischar(name) && ~isempty(name)
        infoMap(strtrim(name)) = r;
    end
end
fprintf('  Info entries read: %d\n', nInfo);

% =========================================================================
% 2. READ DATA SHEET
% =========================================================================
fprintf('  Reading Data sheet from %s...\n', filename);
[~, ~, rawData] = xlsread(filename, 'Data');

% --- Detect stride from row 2 (column headers) --------------------------
headerRow = rawData(2, :);
hasDirty  = any(cellfun(@(x) ischar(x) && ...
                strcmpi(strtrim(x), 'PX_DIRTY_MID'), headerRow));
if hasDirty
    stride      = 4;
    offClean    = 1;   % offset from bond start col to clean price col
    offDirty    = 2;   % offset to dirty price col
else
    stride      = 3;
    offClean    = 1;
    offDirty    = NaN;
end

% --- Parse bond names and start columns from row 1 ----------------------
nameRow      = rawData(1, :);
bondNames    = {};
bondStartCol = [];
for c = 1 : stride : size(rawData, 2)
    name = nameRow{c};
    if ~ischar(name) || isempty(name), break; end
    bondNames{end+1}    = strtrim(name); %#ok<AGROW>
    bondStartCol(end+1) = c;             %#ok<AGROW>
end
nBondsData = length(bondNames);
fprintf('  Bonds found in Data sheet: %d\n', nBondsData);

% --- Data rows (from row 3) ---------------------------------------------
priceRows = rawData(3:end, :);
nRows     = size(priceRows, 1);

% =========================================================================
% 3. BUILD BOND STRUCT — loop over bonds in Data sheet
% =========================================================================
bond = struct('BBGname',           {}, ...
              'settleDate',         {}, ...
              'expDate',            {}, ...
              'firstCouponDate',    {}, ...
              'couponValue',        {}, ...
              'couponFrequency',    {}, ...
              'pricesDates',        {}, ...
              'pricesCleanValues',  {}, ...
              'pricesDirtyValues',  {});

nKept   = 0;
nNoInfo = 0;
nDropF1 = 0;
nDropF2 = 0;

for b = 1 : nBondsData
    bbg = bondNames{b};

    % --- Match to Info sheet by Bloomberg ID ----------------------------
    if ~isKey(infoMap, bbg)
        nNoInfo = nNoInfo + 1;
        continue;
    end
    ir = infoMap(bbg);

    % --- Filter F1: FIXED coupon only -----------------------------------
    cpnType = infoData{ir, 5};
    if ~ischar(cpnType) || ~strcmpi(strtrim(cpnType), 'FIXED')
        nDropF1 = nDropF1 + 1;
        continue;
    end

    % --- Parse static info (fields i-vi) --------------------------------
    settleDate = parseInfoDate(infoData{ir, 2}, EXCEL_BASE);
    expDate    = parseInfoDate(infoData{ir, 3}, EXCEL_BASE);
    firstCpnDt = parseInfoDate(infoData{ir, 4}, EXCEL_BASE);
    cpnValue   = infoData{ir, 6};   % in %
    cpnFreq    = infoData{ir, 7};   % coupons per year

    % --- Filter F2: settle date in [01/01/1999, tN] ---------------------
    if isnan(settleDate) || settleDate < DATE_1999 || settleDate > tN
        nDropF2 = nDropF2 + 1;
        continue;
    end

    % --- Read price time series (fields vii-ix) -------------------------
    sc = bondStartCol(b);
    dates       = nan(nRows, 1);
    cleanPrices = nan(nRows, 1);
    dirtyPrices = nan(nRows, 1);

    for r = 1 : nRows
        d = priceRows{r, sc};
        if isempty(d) || (isnumeric(d) && isnan(d)), continue; end

        dn = parseDataDate(d, EXCEL_BASE);
        if isnan(dn) || dn < t1 || dn > tN, continue; end

        cl = priceRows{r, sc + offClean};
        if isnumeric(cl) && ~isnan(cl)
            dates(r)       = dn;
            cleanPrices(r) = cl;
        end

        if ~isnan(offDirty)
            di = priceRows{r, sc + offDirty};
            if isnumeric(di) && ~isnan(di)
                dirtyPrices(r) = di;
            end
        end
    end

    % Remove empty rows and sort by date
    valid       = ~isnan(dates);
    dates       = dates(valid);
    cleanPrices = cleanPrices(valid);
    dirtyPrices = dirtyPrices(valid);
    if isempty(dates), continue; end

    [dates, idx] = sort(dates);
    cleanPrices  = cleanPrices(idx);
    dirtyPrices  = dirtyPrices(idx);

    % --- Filter F3: spike filter ----------------------------------------
    cleanPrices = spikeFilter(cleanPrices, SPIKE_THRESHOLD);
    if any(~isnan(dirtyPrices))
        dirtyPrices = spikeFilter(dirtyPrices, SPIKE_THRESHOLD);
    end

    % --- Store ----------------------------------------------------------
    nKept = nKept + 1;
    bond(nKept).BBGname           = bbg;
    bond(nKept).settleDate        = settleDate;
    bond(nKept).expDate           = expDate;
    bond(nKept).firstCouponDate   = firstCpnDt;
    bond(nKept).couponValue       = cpnValue;
    bond(nKept).couponFrequency   = cpnFreq;
    bond(nKept).pricesDates       = dates;
    bond(nKept).pricesCleanValues = cleanPrices;
    bond(nKept).pricesDirtyValues = dirtyPrices;

end % for each bond

fprintf('  No Info entry         : %d bonds skipped\n', nNoInfo);
fprintf('  F1 (non-FIXED)        : %d bonds dropped\n', nDropF1);
fprintf('  F2 (settle out range) : %d bonds dropped\n', nDropF2);
fprintf('  Bonds kept            : %d\n', nKept);

end % function buildBondStruct


%% =========================================================================
%  LOCAL HELPERS
%% =========================================================================

function prices = spikeFilter(prices, threshold)
% Replace isolated spikes > threshold with average of neighbours.
% Reference: [2] Appendix, "Filtering technique".
    for r = 2 : length(prices) - 1
        if isnan(prices(r-1)) || isnan(prices(r)) || isnan(prices(r+1))
            continue;
        end
        d1 = prices(r)   - prices(r-1);
        d2 = prices(r+1) - prices(r);
        if abs(d1) > threshold && abs(d2) > threshold && sign(d1) ~= sign(d2)
            prices(r) = (prices(r-1) + prices(r+1)) / 2;
        end
    end
end

function dn = parseInfoDate(d, EXCEL_BASE) %#ok<INUSD>
% Parse date from Info sheet: always a string 'dd/mm/yyyy'.
    if ischar(d)
        try
            dn = datenum(d, 'dd/mm/yyyy');
        catch
            dn = NaN;
        end
    else
        dn = NaN;
    end
end

function dn = parseDataDate(d, EXCEL_BASE)
% Parse date from Data sheet.
% BTP col 0: xlsread returns Matlab datenum (already converted from datetime).
% BTP cols 4,8,...: xlsread returns Excel serial integer.
% BON all date cols: xlsread returns Excel serial integer.
%
% Disambiguation: Excel serials 2007-2020 in [39083, 43831].
% Matlab datenums 2007-2020 in [733042, 737791]. No overlap.
    EXCEL_SERIAL_MAX = 50000;
    if isnumeric(d) && ~isnan(d)
        if d < EXCEL_SERIAL_MAX
            dn = d + EXCEL_BASE;        % Excel serial
        else
            dn = d;                     % already Matlab datenum
        end
    else
        dn = NaN;
    end
end
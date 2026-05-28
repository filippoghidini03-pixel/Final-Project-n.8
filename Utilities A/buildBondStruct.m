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

% Stiamo verificando come sono importate le date da excel, e voglia
% rimpiazzare i buchi o cose strane con i NaN, se presenti
isDT = cellfun(@isdatetime, data);
data(isDT) = cellfun(@(x) datenum(x), data(isDT), 'UniformOutput', false);
isInvalid  = cellfun(@(x) (~isnumeric(x) && ~ischar(x)) || (isnumeric(x) && isempty(x)), data);
data(isInvalid) = {NaN};

% Serve per vedere quante colonne vuote ci sono tra un bond e l'altro
hasDirty = any(cellfun(@(x) ischar(x) && strcmpi(strtrim(x), 'PX_DIRTY_MID'), data(2,:)));
stride   = 3 + hasDirty;

% Costruisce una mappa dei bond, molto utile per trovare rapidamente il bond
dataMap = containers.Map();
for c = 1:stride:size(data, 2)
    name = data{1, c};
    if ~ischar(name) || isempty(name) 
        break; 
    end
    dataMap(strtrim(name)) = c;
end

% Iniziamo a costruire la struct
bond      = struct('BBGname',{}, 'settleDate',{}, 'expDate',{}, ...
                   'firstCouponDate',{}, 'couponValue',{}, 'couponFrequency',{}, ...
                   'pricesDates',{}, 'pricesCleanValues',{}, 'pricesDirtyValues',{});
nKept     = 0;
% Vogliamo solo i numeri, le prime due righe non ci servono
priceRows = data(3:end, :);

% Clean remaining text cells by forcing them to NaN to avoid crash
isNonNumeric = ~cellfun(@isnumeric, priceRows);
priceRows(isNonNumeric) = {NaN};

% Iniziamo a leggere il foglio dalla riga 3
for r = 3:size(info, 1)
    % Prendiamo il nome del bond, usando la mappa creata prima, guarda la
    % prima colonna del foglio info
    bbg = info{r, 1};
    % Se la cella è vuota o non esiste il nome nella mappa saltiamo
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
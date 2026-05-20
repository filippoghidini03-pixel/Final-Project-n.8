function OIS_raw = readOISdata(filename, t1, tN, maxTenorYears)

fprintf('  Reading file: %s\n', filename);
raw = readcell(filename, 'Sheet', 'EONIA_BBG');
for ci = 1:numel(raw)
    v = raw{ci};
    if isdatetime(v)
        raw{ci} = datenum(v);          % converti a Matlab datenum
    elseif ~isnumeric(v) && ~ischar(v)
        raw{ci} = NaN;
    elseif isnumeric(v) && isempty(v)
        raw{ci} = NaN;
    end
end
ROW_TENORS = 5;
ROW_DATA   = 7;

% ---- Parse tenor labels from row 5 ------------------------------------
tenorRow   = raw(ROW_TENORS, :);
nCols      = size(raw, 2);
tenorYears = [];
colDate    = [];
colRate    = [];

c = 1;
while c <= nCols - 1
    num  = tenorRow{c};
    unit = tenorRow{c+1};
    if isempty(num) || (isnumeric(num) && isnan(num)), break; end
    if ~isnumeric(num) || ~ischar(unit), break; end

    if strcmpi(unit, 'm')
        tyr = num / 12;
    elseif strcmpi(unit, 'y')
        tyr = num;
    else
        c = c + 2; continue;
    end

    if tyr <= maxTenorYears + 0.01
        tenorYears(end+1) = tyr;   %#ok<AGROW>
        colDate(end+1)    = c;     %#ok<AGROW>
        colRate(end+1)    = c + 1; %#ok<AGROW>
    end
    c = c + 2;
end

nTenors = length(tenorYears);
fprintf('  Found %d tenors up to %g years.\n', nTenors, maxTenorYears);
if nTenors == 0
    error('readOISdata: no tenors found. Check file structure.');
end

% ---- Parse data rows ---------------------------------------------------
dataRaw = raw(ROW_DATA:end, :);
nRows   = size(dataRaw, 1);

% Collect dates from reference column (first tenor date col)
refCol   = colDate(1);
allDates = nan(nRows, 1);
for r = 1 : nRows
    d = dataRaw{r, refCol};
    if ischar(d) && ~isempty(d)
        allDates(r) = datenum(d, 'dd/mm/yyyy');
    elseif isnumeric(d) && ~isnan(d)
        allDates(r) = d;    % già datenum, passa direttamente
    end
end

valid    = ~isnan(allDates);
allDates = allDates(valid);
validIdx = find(valid);
nDates   = length(allDates);

% Collect rates for all tenors
rateMatrix = nan(nDates, nTenors);
for t = 1 : nTenors
    rc = colRate(t);
    for r = 1 : nDates
        v = dataRaw{validIdx(r), rc};
        if isnumeric(v) && ~isnan(v)
            rateMatrix(r, t) = v;
        end
    end
end

% ---- Filter to [t1, tN] and sort ascending ----------------------------
inRange    = (allDates >= t1) & (allDates <= tN);
allDates   = allDates(inRange);
rateMatrix = rateMatrix(inRange, :);
[allDates, sortIdx] = sort(allDates, 'ascend');
rateMatrix = rateMatrix(sortIdx, :);
nDates     = length(allDates);

% ---- Build output struct -----------------------------------------------
OIS_raw  = struct('valueDate',cell(nDates,1),'tenors',cell(nDates,1),'rates',cell(nDates,1));
nDropped = 0;
k        = 0;

for i = 1 : nDates
    rates = rateMatrix(i, :)';
    if any(isnan(rates))
        nDropped = nDropped + 1; continue;
    end
    k = k + 1;
    OIS_raw(k).valueDate = allDates(i);
    OIS_raw(k).tenors    = tenorYears(:);
    OIS_raw(k).rates     = rates;
end
OIS_raw = OIS_raw(1:k);

fprintf('  Dates in [t1,tN]  : %d\n', nDates);
if nDropped > 0
    fprintf('  Dropped (incomplete): %d days\n', nDropped);
end

end
function OIS_raw = readOISdata(filename, t1, tN, maxTenorYears)
% READOISDATA  Reads OIS curve data from Excel (EONIA_BBG sheet).
%   Missing rates are forward-filled within each row (prev tenor value).

raw = readcell(filename, 'Sheet', 'EONIA_BBG');

% Convert datetime objects to Matlab datenums
for ci = 1 : numel(raw)
    v = raw{ci};
    if isdatetime(v)
        raw{ci} = datenum(v);
    elseif ~isnumeric(v) && ~ischar(v)
        raw{ci} = NaN;
    elseif isnumeric(v) && isempty(v)
        raw{ci} = NaN;
    end
end

ROW_TENORS = 5;
ROW_DATA   = 7;

% =========================================================================
% 1. PARSE TENOR LABELS (row 5)
%    Structure: col c = tenor number, col c+1 = unit ('m' or 'y')
% =========================================================================
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
        c = c + 2;
        continue;
    end

    if tyr <= maxTenorYears + 0.01
        tenorYears(end+1) = tyr;
        colDate(end+1)    = c;
        colRate(end+1)    = c + 1;
    end
    c = c + 2;
end

nTenors = length(tenorYears);
fprintf('Found %d tenors up to %g years.\n', nTenors, maxTenorYears);
if nTenors == 0
    error('readOISdata: no tenors found. Check file structure.');
end

% =========================================================================
% 2. PARSE DATA ROWS (from row 7)
% =========================================================================
dataRaw = raw(ROW_DATA:end, :);
nRows   = size(dataRaw, 1);

% Collect dates from the first tenor date column
refCol   = colDate(1);
allDates = nan(nRows, 1);
for r = 1 : nRows
    d = dataRaw{r, refCol};
    if isnumeric(d) && ~isnan(d)
        allDates(r) = d;
    elseif ischar(d) && ~isempty(d)
        allDates(r) = datenum(d, 'dd/mm/yyyy');
    end
end

valid    = ~isnan(allDates);
allDates = allDates(valid);
validIdx = find(valid);
nDates   = length(allDates);

% Collect rates into a matrix [nDates x nTenors]
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

% =========================================================================
% 3. FORWARD-FILL MISSING RATES WITHIN EACH ROW
%    If a rate is missing, use the rate from the previous tenor.
%    If the first tenor is also missing, use the next available one.
% =========================================================================
for r = 1 : nDates
    % Forward fill: left to right
    for t = 2 : nTenors
        if isnan(rateMatrix(r, t)) && ~isnan(rateMatrix(r, t-1))
            rateMatrix(r, t) = rateMatrix(r, t-1);
        end
    end
    % Backward fill: right to left (handles missing values at the start)
    for t = nTenors-1 : -1 : 1
        if isnan(rateMatrix(r, t)) && ~isnan(rateMatrix(r, t+1))
            rateMatrix(r, t) = rateMatrix(r, t+1);
        end
    end
end

% =========================================================================
% 4. FILTER TO [t1, tN] AND SORT
% =========================================================================
inRange    = (allDates >= t1) & (allDates <= tN);
allDates   = allDates(inRange);
rateMatrix = rateMatrix(inRange, :);
[allDates, sortIdx] = sort(allDates, 'ascend');
rateMatrix          = rateMatrix(sortIdx, :);
nDates              = length(allDates);

% =========================================================================
% 5. BUILD OUTPUT STRUCT
% =========================================================================
OIS_raw = struct('valueDate', cell(nDates,1), 'tenors', cell(nDates,1), 'rates', cell(nDates,1));

for i = 1 : nDates
    OIS_raw(i).valueDate = allDates(i);
    OIS_raw(i).tenors    = tenorYears(:);
    OIS_raw(i).rates     = rateMatrix(i, :)';
end

fprintf('Dates in [t1, tN]: %d\n', nDates);

end
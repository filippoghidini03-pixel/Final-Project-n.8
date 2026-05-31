function [allDatesOut, PDout, ratesOut] = bootstrapEONIA(OIS_raw, settleLag)
% BOOTSTRAPEONIA Bootstraps the EONIA discount curve from Overnight Indexed Swap (OIS) quotes.
%
% INPUTS:
%   OIS_raw   - Struct array containing the daily market data. Expected fields:
%               * valueDate: The observation trade date (datenum).
%               * rates: Vector of OIS rates in percentage (e.g., 0.5 for 0.5%).
%               * tenors: Vector of corresponding tenors in years (e.g., 0.5, 1, 2).
%   settleLag - Integer representing the settlement lag in business days (e.g., 2).
%
% OUTPUTS:
%   allDatesOut - Cell array (nDates x 1), each cell contains the vector of 
%                 node dates starting from the settlement date (t0).
%   PDout       - Cell array (nDates x 1), each cell contains the vector of 
%                 bootstrapped Discount Factors corresponding to the node dates.
%   ratesOut    - Cell array (nDates x 1), each cell contains the original 
%                 OIS rates (in percentage) used for the curve.

nDates      = length(OIS_raw);
allDatesOut = cell(nDates, 1);
PDout       = cell(nDates, 1);
ratesOut    = cell(nDates, 1);

% Inizia ad analizzare dal giorno 1, estrae la data, i tassi e le scadenze
% in anni
for i = 1 : nDates
    vd       = OIS_raw(i).valueDate;
    rates    = OIS_raw(i).rates / 100;
    tenorsYr = OIS_raw(i).tenors;
    
    % Use the unified shiftDate function to calculate the settlement date (t0)
    %t0     = shiftDate(vd, settleLag, 'busdays');

    % Non va shiftato niente perché le date sono già settlement dates
    t0 = vd ;
    nKnots = length(tenorsYr);
    
    % Use the unified shiftDate function to calculate maturity dates (Modified Following)
    knotDates = shiftDate(t0, round(tenorsYr * 12), 'months');
    allDates  = [t0; knotDates];
    
    % Inizializzo un vettore di NaN e forzo il primo discount (cioè quello di t0) a 1
    PD    = nan(nKnots + 1, 1);
    PD(1) = 1.0; 
    
    % Trova gli indici di contartto a breve e lungo termine
    idxShort = find(tenorsYr < 0.999);
    idxLong  = find(tenorsYr >= 0.999);
    
    % Short tenors (OIS < 1y): Simple compounding formulation
    if ~isempty(idxShort)
        te    = knotDates(idxShort);
        % yearfrac parameter 2 applies the Actual/360 convention
        delta = yearfrac(t0, te, 2);
        PD(idxShort + 1) = 1 ./ (1 + delta .* rates(idxShort));
    end
    
    % Long tenors (OIS >= 1y): Annual compounding with zero-rate interpolation
    % Prende il nodo lungo, trova gli anni totali, la data finale e il tasso di questo swap.
    for ki = idxLong'
        nYears = round(tenorsYr(ki));
        t_i    = knotDates(ki);
        r_i    = rates(ki);
        
        % Costruisce il calendario dei flussi intermedi
        payDates      = shiftDate(t0, (1:nYears)' * 12, 'months');
        payDates(end) = t_i;
        allPayDates = [t0; payDates];
        deltas      = yearfrac(allPayDates(1:end-1), allPayDates(2:end), 2);
        
        % Interpolate the discount factors for intermediate payment dates
        pdVec       = interpolateDF(allDates, PD, payDates(1:end-1));
        
        % Bootstrapping formula for the final discount factor
        sumTerm    = sum(deltas(1:end-1) .* pdVec);
        PD(ki + 1) = (1 - r_i * sumTerm) / (1 + deltas(end) * r_i);
    end
    
    % Store the results in the pre-allocated cell arrays
    allDatesOut{i} = allDates;
    PDout{i}       = PD;
    ratesOut{i}    = rates * 100;
end
end


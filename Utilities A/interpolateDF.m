function df = interpolateDF(knownDates, knownPD, queryDates)
%
%   INPUTS:
%     knownDates  (Nx1 datenum) : dates for which DF is known; knownDates(1) = t0
%     knownPD     (Nx1 double)  : discount factors B(t0, knownDates)
%     queryDates  (Mx1 datenum) : dates at which to interpolate
%
%   OUTPUT:
%     df          (Mx1 double)  : interpolated discount factors

% Check for the days without bonds
if isempty(queryDates)
        df = [];
        return;
end

t0    = knownDates(1);
valid = ~isnan(knownPD) & ~isnan(knownDates);

tauVec  = max(yearfrac(t0, knownDates(valid), 3), 1e-6);   % Act/365
zVec    = -log(knownPD(valid)) ./ tauVec;
zVec(1) = zVec(2);   % stabilise anchor at t0 (avoid divide-by-zero artifacts)

queryDates = queryDates(:);
t0_vec_query = repmat(t0, length(queryDates), 1);
tauQ = yearfrac(t0_vec_query, queryDates, 3);% Act/365
%tauQ = (queryDates - t0) / 365;   % Act/365
zQ   = interp1(tauVec, zVec, tauQ, 'linear', 'extrap');
df   = exp(-zQ .* tauQ);
df(tauQ <= 0) = 1.0;   % B(t0, t0) = 1 by definition
end

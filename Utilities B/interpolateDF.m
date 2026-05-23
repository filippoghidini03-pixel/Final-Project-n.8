function df = interpolateDF(knownDates, knownPD, queryDates)
%INTERPOLATEDF  Log-linear interpolation (and extrapolation) of discount factors.
%
%   df = interpolateDF(knownDates, knownPD, queryDates)
%
%   Maps dates to instantaneous zero rates: z(t) = -log(DF(t)) / tau(t),
%   interpolates z linearly in time tau, then recovers DF = exp(-z * tau).
%   Extrapolation uses the last computed zero rate (flat extension).
%
%   INPUTS:
%     knownDates  (Nx1 datenum) : dates for which DF is known; knownDates(1) = t0
%     knownPD     (Nx1 double)  : discount factors B(t0, knownDates)
%     queryDates  (Mx1 datenum) : dates at which to interpolate
%
%   OUTPUT:
%     df          (Mx1 double)  : interpolated discount factors
%
%   Extracted from bootstrapEONIA.m for shared use across the project.
%   Identical logic; now callable as a standalone utility.

t0    = knownDates(1);
valid = ~isnan(knownPD) & ~isnan(knownDates);

tauVec  = max((knownDates(valid) - t0) / 365, 1e-6);
zVec    = -log(knownPD(valid)) ./ tauVec;
zVec(1) = zVec(2);   % stabilise anchor at t0 (avoid divide-by-zero artifacts)

queryDates = queryDates(:);
tauQ = (queryDates - t0) / 365;
zQ   = interp1(tauVec, zVec, tauQ, 'linear', 'extrap');
df   = exp(-zQ .* tauQ);
df(tauQ <= 0) = 1.0;   % B(t0, t0) = 1 by definition
end

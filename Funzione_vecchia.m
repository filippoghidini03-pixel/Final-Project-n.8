function [Spreads_BTP, Spreads_BON] = computeASWspreads(EONIA, bond_BTP, bond_BON)
%COMPUTEASWSPREADS  Compute ASW and Zeta spreads over EONIA for BTPs and BONOs.
%
%   [Spreads_BTP, Spreads_BON] = computeASWspreads(EONIA, bond_BTP, bond_BON)
%
%   For every business day t_i (settlement date t0 = EONIA(i).Dates(1)):
%     1. Selects bonds with expiry in the range (t0+2m, t0+10y].
%     2. For each selected bond computes the ASW spread over EONIA:
%
%            s_asw = [ B(t0,T) - P(0) + c * sum_n( delta_f(n) * B(t0,t_n) ) ]
%                    -------------------------------------------------------
%                              sum_k( delta_k * B(t0,t_k) )
%
%        where:
%          P(0)       : bond dirty price at settlement (fraction of par)
%          c          : annual coupon rate (fraction)
%          {t_n}      : bond coupon dates strictly after t0 up to T
%          delta_f(n) : yearfrac for coupon period (30/360 European, basis=6)
%                       consistent with computeAccrual.m used in Part A
%          {t_k}      : quarterly floating-leg dates, built BACKWARD from T
%                       with Modified Following -> short stub at the front
%          delta_k    : yearfrac for each float period (Act/360, basis=2)
%          B(t0,t)    : EONIA discount factor via interpolateDF.m
%
%     3. Computes the Z-spread: parallel shift z of the EONIA curve such that
%        the sum of discounted bond cash flows equals the dirty price.
%
%   DEPENDENCIES (all in Utilities A/):
%     shiftDate.m      - Modified Following month/busday shifts (from bootstrapEONIA)
%     interpolateDF.m  - log-linear DF interpolation          (from bootstrapEONIA)
%     computeAccrual.m - used in Part A for dirty prices (T+2 logic consistent here)
%
%   OUTPUT (struct arrays, one entry per EONIA date):
%     .ExpiryDates  (Mx1 datenum)  - bond expiry dates
%     .ASWSpreads   (Mx1 double)   - ASW spreads in basis points
%     .ZetaSpreads  (Mx1 double)   - Z-spreads  in basis points
%
%   References:
%     Baviera & Lebovitz (2015), Appendix "Asset Swap spread".


nDates = length(EONIA);
% Pre-allocate output struct arrays
empty = struct('ExpiryDates', [], 'ASWSpreads', [], 'ZetaSpreads', []);
Spreads_BTP(nDates, 1) = empty;
Spreads_BON(nDates, 1) = empty;
% Extract EONIA settlement dates (Dates(1) = t0 for each business day)
eon_t0 = arrayfun(@(x) x.Dates(1), EONIA);
% Pre-compute T+2 settlement dates for every bond price observation.
% Uses the SAME T+2 logic as computeAccrual.m (Part A), so matching is exact.
BTP_settle = precomputeSettleDates(bond_BTP);
BON_settle = precomputeSettleDates(bond_BON);
fprintf('Computing ASW and Z-spreads for %d dates...\n', nDates);
for i = 1:nDates
    if mod(i, 200) == 0 || i == nDates
        fprintf('  %d / %d\n', i, nDates);
    end
    t0       = eon_t0(i);
    eonDates = EONIA(i).Dates;
    eonDF    = EONIA(i).DiscountFactors;
    % Expiry filter: (t0 + 2 months,  t0 + 10 years]
    % Uses shiftDate.m (extracted from bootstrapEONIA.m) for Modified Following
    minExp = shiftDate(t0,   2, 'months');   % exclusive lower bound
    maxExp = shiftDate(t0, 120, 'months');   % inclusive upper bound (10y)
    % BTPs and BONOs share the SAME fixed-leg daycount: 30/360 European (basis=6)
    % This is consistent with computeAccrual.m which applies 30/360 to both.
    [ed, asw, zs] = computeSpreadsForBonds( ...
        bond_BTP, BTP_settle, t0, minExp, maxExp, eonDates, eonDF);
    Spreads_BTP(i).ExpiryDates = ed;
    Spreads_BTP(i).ASWSpreads  = asw;
    Spreads_BTP(i).ZetaSpreads = zs;
    [ed, asw, zs] = computeSpreadsForBonds( ...
        bond_BON, BON_settle, t0, minExp, maxExp, eonDates, eonDF);
    Spreads_BON(i).ExpiryDates = ed;
    Spreads_BON(i).ASWSpreads  = asw;
    Spreads_BON(i).ZetaSpreads = zs;
end
fprintf('ASW computation complete.\n');
end
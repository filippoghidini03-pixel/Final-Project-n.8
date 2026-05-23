function [expDates, aswVec, zetaVec] = computeSpreadsForBonds( ...
    bonds, settleDates, t0, minExp, maxExp, eonDates, eonDF)

%COMPUTESPRADSFOR BONDS  Compute ASW and Z-spread for all bonds at date t0.

expDates = zeros(0, 1);
aswVec   = zeros(0, 1);
zetaVec  = zeros(0, 1);

nBonds = length(bonds);
for j = 1:nBonds

    % ---- 1. Match bond price to this settlement date ----
    idx = find(settleDates{j} == t0, 1);
    if isempty(idx), continue; end

    % ---- 2. Expiry filter ----
    T = bonds(j).expDate;
    if T <= minExp || T > maxExp, continue; end

    % ---- 3. Dirty price as fraction of par ----
    dirtyP = bonds(j).pricesDirtyValues(idx) / 100;
    if isnan(dirtyP) || dirtyP <= 0, continue; end

    c        = bonds(j).couponValue / 100;   % annual coupon rate (fraction)
    freq     = bonds(j).couponFrequency;     % coupons per year
    firstCpn = bonds(j).firstCouponDate;

    % ---- 4. Fixed-leg coupon dates (strictly after t0, up to T) ----
    cpnDates = buildCouponDates(firstCpn, T, freq, t0);
    if isempty(cpnDates), continue; end

    % ---- 5. Floating-leg dates: quarterly, BACKWARD from T ----
    %   Produces [t0, d1, ..., d_{K-1}, T] where [t0, d1] is the short stub.
    %   Uses shiftDate.m (same as bootstrapEONIA) for Modified Following.
    floatDates = buildFloatDatesBackward(T, t0);
    if length(floatDates) < 2, continue; end

    % ---- 6. EONIA discount factors via interpolateDF.m ----
    %   interpolateDF.m is extracted from bootstrapEONIA's local helper:
    %   same log-linear zero-rate interpolation used throughout the project.
    DF_cpn   = interpolateDF(eonDates, eonDF, cpnDates);
    DF_float = interpolateDF(eonDates, eonDF, floatDates(2:end));
    DF_T     = interpolateDF(eonDates, eonDF, T);

    if any(isnan(DF_cpn)) || any(isnan(DF_float)) || isnan(DF_T)
        continue
    end

    % ---- 7. Yearfracs ----
    %
    %   Fixed leg: 30/360 European (basis=6).
    %   Consistent with computeAccrual.m (Part A) which uses the European
    %   30/360 convention for accrued interest on BOTH BTPs and BONOs.
    cpnPrev = [t0; cpnDates(1:end-1)];
    delta_f  = yearfrac(cpnPrev, cpnDates, 6);   % 30/360 European

    %   Floating leg: Act/360 (basis=2).
    %   Same basis used in bootstrapEONIA.m for OIS short-tenor deltas.
    delta_k  = yearfrac(floatDates(1:end-1), floatDates(2:end), 2);

    % ---- 8. ASW spread (Baviera-Lebovitz formula) ----
    %
    %   Numerator:   B(t0,T) - P(0) + c * sum_n[ delta_f(n) * B(t0,t_n) ]
    %   Denominator: sum_k[ delta_k * B(t0,t_k) ]
    %
    %   The denominator is built on the BACKWARD-constructed float dates:
    %   discount factors and yearfracs are taken for the same quarterly grid
    %   anchored at T (as prescribed by the paper).
    numerator   = DF_T - dirtyP + c * sum(delta_f .* DF_cpn);
    denominator = sum(delta_k .* DF_float);

    if denominator <= 1e-10 || isnan(denominator), continue; end

    asw = numerator / denominator;   % decimal (e.g. 0.01 = 100 bps)

    % ---- 9. Z-spread ----
    %   Find z such that:
    %     P(0) = c * sum_n[ delta_f(n) * B(t0,t_n) * exp(-z*tau_n) ]
    %           + B(t0,T) * exp(-z * tau_T)
    taus_cpn = (cpnDates - t0) / 365;
    tau_T    = (T        - t0) / 365;
    if tau_T <= 0, continue; end

    cf_cpn = c * delta_f;   % coupon cash flows as fraction of par

    objFun = @(z) sum(cf_cpn .* DF_cpn .* exp(-z .* taus_cpn)) ...
                + DF_T * exp(-z * tau_T) - dirtyP;
    try
        opts = optimset('Display', 'off', 'TolX', 1e-9);
        zeta = fzero(objFun, asw, opts);
    catch
        zeta = NaN;
    end

    expDates(end+1, 1) = T;
    aswVec  (end+1, 1) = asw  * 1e4;   % decimal -> bps
    zetaVec (end+1, 1) = zeta * 1e4;
end
end
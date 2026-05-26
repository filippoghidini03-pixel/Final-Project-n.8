function settleDates = precomputeSettleDates(bonds)
%PRECOMPUTESETTLEDATES  Convert bond price value dates to T+2 settlement dates.
%
%   Replicates the EXACT T+2 logic in computeAccrual.m so that settlement
%   dates match those used when building dirty prices in Part A.
%
%   MATLAB weekday codes: 1=Sun 2=Mon 3=Tue 4=Wed 5=Thu 6=Fri 7=Sat
%     Mon-Wed value date -> settle = vd + 2
%     Thu value date     -> settle = vd + 4  (Thu+2=Sat -> Mon)
%     Fri value date     -> settle = vd + 4  (Fri+2=Sun -> Tue)

nBonds = length(bonds);
settleDates = cell(nBonds, 1);
for j = 1:nBonds
    vd = bonds(j).pricesDates(:);
    s  = vd + 2;
    wd = weekday(vd);
    s(wd == 5) = s(wd == 5) + 2;   % Thu
    s(wd == 6) = s(wd == 6) + 2;   % Fri
    settleDates{j} = s;
end
end

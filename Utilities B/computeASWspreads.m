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
%   OUTPUT (struct arrays, one entry per EONIA date):
%     .ExpiryDates  (Mx1 datenum)  - bond expiry dates
%     .ASWSpreads   (Mx1 double)   - ASW spreads in basis points
%     .ZetaSpreads  (Mx1 double)   - Z-spreads  in basis points
%

nDates = length(EONIA);
    
    % --- 1. Preallocazione stretta (Obbligatoria per il parfor) ---
    % Quando si usa parfor, MATLAB deve sapere esattamente come "affettare" (slice)
    % la memoria in uscita. Preallocare l'intera struct è essenziale.
    Spreads_BTP = struct('ExpiryDates', cell(nDates,1), ...
                         'ASWSpreads',  cell(nDates,1), ...
                         'ZetaSpreads', cell(nDates,1));
                         
    Spreads_BON = struct('ExpiryDates', cell(nDates,1), ...
                         'ASWSpreads',  cell(nDates,1), ...
                         'ZetaSpreads', cell(nDates,1));

    % --- 2. Variabili in Broadcast ---
    % Estraiamo i t0 fuori dal loop per evitare overhead di accesso
    eon_t0 = arrayfun(@(x) x.Dates(1), EONIA);
    
    BTP_settle = precomputeSettleDates(bond_BTP);
    BON_settle = precomputeSettleDates(bond_BON);

    fprintf('Avvio calcolo parallelo (parfor) su %d giorni di mercato...\n', nDates);
    fprintf('(L''operazione potrebbe richiedere qualche minuto. Attendi...)\n');

    % --- 3. LOOP PARALLELO ---
    parfor i = 1:nDates
        t0       = eon_t0(i);
        eonDates = EONIA(i).Dates;
        eonDF    = EONIA(i).DiscountFactors;

        % Filtro per la scadenza: (t0 + 2 mesi,  t0 + 10 anni]
        minExp = shiftDate(t0,   2, 'months');   
        maxExp = shiftDate(t0, 120, 'months');   

        % Calcolo per i BTP
        [ed_BTP, asw_BTP, zs_BTP] = computeSpreadsForBonds( ...
            bond_BTP, BTP_settle, t0, minExp, maxExp, eonDates, eonDF);
            
        % Calcolo per i BONOS
        [ed_BON, asw_BON, zs_BON] = computeSpreadsForBonds( ...
            bond_BON, BON_settle, t0, minExp, maxExp, eonDates, eonDF);

        % --- Slicing per il salvataggio in output ---
        Spreads_BTP(i).ExpiryDates = ed_BTP;
        Spreads_BTP(i).ASWSpreads  = asw_BTP;
        Spreads_BTP(i).ZetaSpreads = zs_BTP;

        Spreads_BON(i).ExpiryDates = ed_BON;
        Spreads_BON(i).ASWSpreads  = asw_BON;
        Spreads_BON(i).ZetaSpreads = zs_BON;
    end
    
    fprintf('=== Calcolo ASW e Z-Spread Completato! ===\n');
end
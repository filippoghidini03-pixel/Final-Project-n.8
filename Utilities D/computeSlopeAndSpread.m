function [slopeSign, spread10y] = computeSlopeAndSpread(SpreadsFilt, datesFilt, tau_star, spreadField)
%
%   INPUTS:
%       SpreadsFilt - Filtered struct array containing bond data.
%                     Must contain 'ExpiryDates' and the field specified by spreadField.
%       datesFilt   - Vector (nDays x 1) of evaluation dates (datenums).
%       tau_star    - Vector (nDays x 1) of optimal breakpoints in years.
%       spreadField - (Optional) String specifying the spread field to use. 
%                     Default is 'ASWSpreads'.
%
%   OUTPUTS:
%       slopeSign   - Vector (nDays x 1) indicating the curve's slope direction:
%                     +1 for a normal/flat curve, -1 for an inverted curve.
%       spread10y   - Vector (nDays x 1) of the evaluated 10-year spreads.

    if nargin < 4, spreadField = 'ASWSpreads'; end
    
    nDays     = length(SpreadsFilt);
    slopeSign = ones(nDays, 1);
    spread10y = nan(nDays, 1);
    
    for i = 1:nDays
        % Skip days where the breakpoint could not be calculated
        if isnan(tau_star(i)) || isinf(tau_star(i)), continue; end
        
        T_dates = SpreadsFilt(i).ExpiryDates(:);
        s       = SpreadsFilt(i).(spreadField)(:);
        tau     = (T_dates - datesFilt(i)) / 365.25;
        
        % Sort maturities to ensure correct left/right splitting
        [tau, idx] = sort(tau);
        s  = s(idx);
        ts = tau_star(i);
        
        % Split the points into left and right segments based on tau*
        left  = tau <= ts;
        right = tau >  ts;
        
        % Perform linear regression on both segments if there are enough points.
        % Otherwise, fallback to a single linear fit for the whole curve.
        if sum(left) >= 2 && sum(right) >= 2
            pL = polyfit(tau(left),  s(left),  1);
            pR = polyfit(tau(right), s(right), 1);
        else
            pL = polyfit(tau, s, 1);
            pR = pL;
            ts = tau(end);
        end
        
        % --- 1. Evaluate the 10-Year Spread ---
        % Cap the evaluation point at the maximum available maturity
        eval_point = min(10, max(tau));
        
        if eval_point <= ts
            spread10y(i) = polyval(pL, eval_point);
        else
            spread10y(i) = polyval(pR, eval_point);
        end
        
        % --- 2. Evaluate the Short-Term Spread (0.5 Years) ---
        if 0.5 <= ts
            s_short = polyval(pL, 0.5);
        else
            s_short = polyval(pR, 0.5);
        end
        
        % --- 3. Determine Curve Inversion (Slope Sign) ---
        % If short-term spread is greater than long-term spread, curve is inverted
        if s_short > spread10y(i)
            slopeSign(i) = -1;
        end
    end
end
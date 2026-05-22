function ai = computeAccrual(dates, firstCpnDate, cpnValue, cpnFreq)
% COMPUTEACCRUAL 30/360 accrued interest calculation with yearfrac.

% Usiamo la regola dei due giorni in più, traslando in questo modo alcune
% date potrebbero finire nel weekend, nel caso le sistemiamo aggiungendo
% altri due giorni
settle = dates + 2; 
wd = weekday(settle); 
settle(wd == 1 | wd == 7) = settle(wd == 1 | wd == 7) + 2;

% Ci calcoliamo quanto tempo è passato dalla prima cedola e quanto dura in
% anni; coì possiamo calcolarci la frazione di anno passta dall'ultima
% cedola
totalYears = yearfrac(firstCpnDate, settle, 6);
periodYears = 1 / cpnFreq;
fracPassed = mod(totalYears, periodYears);

% Calcolo effettivo del rateo
ai = cpnValue .* fracPassed;

end
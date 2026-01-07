clear; clc;

C = config();
el1 = aem_to_electrode(C.AEM1);
savePrefix = sprintf('AEM%d_el%d', C.AEM1, el1);

pilotFile = fullfile(C.outDir, sprintf('Pilot6_%s.mat', savePrefix));
assert(isfile(pilotFile), 'Missing pilot file: %s', pilotFile);

S = load(pilotFile, 'pilot');
pilot = S.pilot;

seriesList = {
    pilot.P120.pre,  'P120_pre'
    pilot.P120.post, 'P120_post'
    pilot.P180.pre,  'P180_pre'
    pilot.P180.post, 'P180_post'
    pilot.P240.pre,  'P240_pre'
    pilot.P240.post, 'P240_post'
};

nTrain = 600;
nTest  = 300;
H      = 10;

Pmax   = 20;

results = struct();

bic_saved = NaN(6, 1);
for sIdx = 1:size(seriesList,1)
    x = seriesList{sIdx,1};
    name = seriesList{sIdx,2};

    % Κεντράρισμα της πλήρους σειράς που μπαίνει στο "fit":
    % xfit(t) = x(t) - mean(x), ώστε το AR να δουλέψει με Constant=0
    xfit = x - mean(x);

    bicVals = NaN(1,Pmax);
    models  = cell(1,Pmax);

    % Επιλογή τάξης AR με BIC πάνω στη σειρά που χρησιμοποιείται για fit
    % BIC(p) = n*log(σ̂_p^2) + p*log(n)
    for p = 1:Pmax
        m = fit_ar_yw(xfit, p);
        models{p} = m;

        sigma2 = max(m.sigma2, eps);
        bicVals(p) = length(x)*log(sigma2) + p*log(length(x));
    end

    [bic_saved(sIdx), pBest] = min(bicVals);
    mBest = models{pBest};

    % Υπόλοιπα πάνω στην ίδια κεντραρισμένη σειρά xfit:
    % e(t) = xfit(t) - sum_{k=1..p} a_k xfit(t-k)
    eTrain = ar_residuals(xfit, mBest);
    eTrain = eTrain(~isnan(eTrain));

    [hLBQ, pLBQ] = lbqtest(eTrain, 'Lags', 20);

    fprintf('%s | AR(%d): Ljung-Box p=%.3e\n', name, pBest, pLBQ);

    figure;
    autocorr(eTrain, 'NumLags', 20);
    title(['Residual ACF - ' name]);

    % Πρόβλεψη/NRMSE πάνω στην original σειρά x (η κεντράρισή της γίνεται εσωτερικά στο ar_forecast_nrmse)
    out = ar_forecast_nrmse(x, pBest, nTrain, nTest, H);

    results(sIdx).name   = name;
    results(sIdx).pBest  = pBest;
    results(sIdx).bic    = bicVals;
    results(sIdx).nrmse  = out.nrmse;

end

figure('Name','NRMSE (AR) - Pilot 6');
horizons = 1:H;
for sIdx = 1:numel(results)
    plot(horizons, results(sIdx).nrmse, '-o'); hold on;
end
grid on;
xlabel('Horizon (steps ahead)');
ylabel('NRMSE');
title(sprintf('Pilot 6 - AR models (electrode %d)', el1));
legend({results.name}, 'Location', 'best');

outFile = fullfile(C.outDir, sprintf('LinearResults_AR_Pilot6_%s.mat', savePrefix));
save(outFile, 'results', 'nTrain', 'nTest', 'H', 'Pmax');
fprintf('Saved linear results: %s\n', outFile);

for s = 1:numel(results)
    fprintf('%s: pBest=%d\n', results(s).name, results(s).pBest);
end

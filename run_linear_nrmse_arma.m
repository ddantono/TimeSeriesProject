clear; clc;

C = config();
el1 = aem_to_electrode(C.AEM1);
savePrefix = sprintf('AEM%d_el%d', C.AEM1, el1);

pilotFile = fullfile(C.outDir, sprintf('Pilot6_%s.mat', savePrefix));
assert(isfile(pilotFile), helpMissing(pilotFile));

S = load(pilotFile, 'pilot');
pilot = S.pilot;

% Συγκεντρώνουμε τις 6 χρονοσειρές της πιλοτικής μελέτης (pre/post για 3 εντάσεις)
seriesList = {
    pilot.P120.pre,  'P120_pre'
    pilot.P120.post, 'P120_post'
    pilot.P180.pre,  'P180_pre'
    pilot.P180.post, 'P180_post'
    pilot.P240.pre,  'P240_pre'
    pilot.P240.post, 'P240_post'
};

% Ορισμός training/test και ορίζοντα πρόβλεψης ώστε να είναι συγκρίσιμο με την ανάλυση AR
nTrain = 600;
nTest  = 300;
H      = 10;

% Πλέγμα υποψήφιων τάξεων ARMA(p,q)
pRange = 0:6;
qRange = 0:6;

results = struct([]);
bic_saved = NaN(1, 6);
for s = 1:size(seriesList,1)
    x = seriesList{s,1}(:);
    name = seriesList{s,2};

    % Κεντράρισμα της σειράς που μπαίνει στο fit/residual diagnostics:
    % xfit(t) = x(t) - mean(x)
    % (εδώ χρησιμοποιείται global mean για τη συγκεκριμένη πιλοτική σειρά)
    xfit = x - mean(x);

    % Επιλογή μοντέλου ARMA(p,q) με BIC σε πλέγμα τάξεων
    % BIC(p,q) = -2*logL + k*log(n), k = p + q + 1
    fitOut = fit_arma_bic(xfit, pRange, qRange);
    pBest = fitOut.pBest;
    qBest = fitOut.qBest;
    bic_saved(s) = fitOut.bestBIC;
    EstMdl = fitOut.EstMdlBest;

    assert(~isempty(EstMdl), 'ARMA estimation failed for %s on the grid.', name);

    % Υπόλοιπα (innovations) στο ίδιο σήμα xfit:
    % e(t) = xfit(t) - \hat{xfit}(t|t-1)
    eFit = infer(EstMdl, xfit);
    eFit = eFit(~isnan(eFit));

    % Ljung–Box: έλεγχος αν τα υπόλοιπα είναι ασυσχέτιστα έως 20 υστερήσεις
    [~, pLBQ] = lbqtest(eFit, 'Lags', 20);
    fprintf('%s | ARMA(%d,%d): Ljung-Box p=%.3e\n', name, pBest, qBest, pLBQ);

    % Οπτικός έλεγχος: ACF των υπολοίπων (θέλουμε να μην ξεχωρίζουν υστερήσεις)
    figure;
    autocorr(eFit, 'NumLags', 20);
    title(sprintf('Residual ACF - %s (ARMA(%d,%d))', name, pBest, qBest));

    % Rolling (expanding-origin) πολυβηματική πρόβλεψη και NRMSE στο test set
    % (η arma_forecast_nrmse κάνει το δικό της κεντράρισμα εσωτερικά)
    outF = arma_forecast_nrmse(x, EstMdl, nTrain, nTest, H);

    results(s).name = name;
    results(s).pBest = pBest;
    results(s).qBest = qBest;
    results(s).pLBQ = pLBQ;
    results(s).nrmse = outF.nrmse;
    results(s).bicMat = fitOut.bic;
end

% Συγκεντρωτικό plot NRMSE για όλες τις 6 χρονοσειρές
figure; hold on;
for s = 1:numel(results)
    plot(1:H, results(s).nrmse, '-o', 'DisplayName', results(s).name);
end
grid on;
xlabel('Horizon (steps ahead)');
ylabel('NRMSE');
title(sprintf('Pilot 6 - ARMA models (electrode %d)', el1));
legend('Location', 'best');

% Αποθήκευση των αποτελεσμάτων ώστε να χρησιμοποιηθούν στην αναφορά/σύγκριση
outFile = fullfile(C.outDir, sprintf('LinearResults_ARMA_Pilot6_%s.mat', savePrefix));
save(outFile, 'results', 'nTrain', 'nTest', 'H', 'pRange', 'qRange');
fprintf('Saved ARMA results: %s\n', outFile);

function msg = helpMissing(f)
% Variables:
% -f: path του αρχείου που λείπει
% -msg: μήνυμα σφάλματος που εξηγεί τι λείπει και ποιο βήμα πρέπει να τρέξει πρώτα

% Μικρό helper ώστε το assert να δίνει πιο "καθαρό" μήνυμα για το missing pilot file
msg = sprintf('Missing pilot file: %s\nRun the pilot builder that creates Pilot6_*.mat first.', f);
end

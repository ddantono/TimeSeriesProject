function T = process_segments_matrix(X, intensity, cond, pUse, nTrain, nTest, H, tauMI, nBins)
% Variables:
% -X: πίνακας δεδομένων (samples x N), κάθε στήλη ένα ανεξάρτητο epoch
% -intensity: επίπεδο έντασης TMS (π.χ. 120, 180, 240)
% -cond: συνθήκη χρονικού τμήματος ("pre" ή "post")
% -pUse: τάξη AR(p) που έχει επιλεγεί από την πιλοτική μελέτη
% -nTrain: πλήθος δειγμάτων training set για το γραμμικό μοντέλο
% -nTest: πλήθος δειγμάτων test set για την πρόβλεψη
% -H: ορίζοντας πρόβλεψης (εδώ H=1 → NRMSE(1))
% -tauMI: χρονική υστέρηση τ για τον υπολογισμό της αμοιβαίας πληροφορίας
% -nBins: αριθμός bins για την histogram-based εκτίμηση πιθανοτήτων
% -nS: πλήθος δειγμάτων ανά epoch
% -N: πλήθος epochs
% -NRMSE1: διάνυσμα NRMSE(1), ένα scalar γραμμικό μέτρο ανά epoch
% -MI1: διάνυσμα MI(1), ένα scalar μη-γραμμικό μέτρο ανά epoch
% -ep: δείκτης επεισοδίου
% -x: χρονοσειρά ενός μεμονωμένου epoch
% -T: πίνακας αποτελεσμάτων (table) με μία γραμμή ανά epoch

X = double(X);
[~, N] = size(X);

NRMSE1 = NaN(N,1);
MI1    = NaN(N,1);

for ep = 1:N
    x = X(:,ep);

    % Γραμμικό μέτρο:
    % Εκτίμηση AR(p) στο training set και υπολογισμός NRMSE για ορίζοντα 1
    % Το NRMSE(1) μετρά την άμεση προβλεπτική ικανότητα του μοντέλου
    out = ar_forecast_nrmse(x, pUse, nTrain, nTest, H);
    NRMSE1(ep) = out.nrmse(1);

    % Μη-γραμμικό μέτρο:
    % Αμοιβαία πληροφορία μεταξύ x(t) και x(t+τ),
    % MI(1) = I(x(t); x(t+1)) για τ = tauMI
    MI = mi_delay_hist(x, tauMI, nBins);
    MI1(ep) = MI(1);
end

% Μεταδεδομένα για κάθε γραμμή (ένα epoch = ένα στατιστικό δείγμα)
episode = (1:N).';
intensityCol = repmat(intensity, N, 1);
condCol = repmat(string(cond), N, 1);

% Συγκέντρωση όλων των πληροφοριών σε πίνακα:
% κάθε γραμμή αντιστοιχεί σε ένα epoch και περιέχει
% (ένταση, pre/post, δείκτη επεισοδίου, γραμμικό και μη-γραμμικό μέτρο)
T = table(intensityCol, condCol, episode, NRMSE1, MI1, ...
    'VariableNames', {'intensity','cond','episode','NRMSE1','MI1'});
end

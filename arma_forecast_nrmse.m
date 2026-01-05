function out = arma_forecast_nrmse(x, EstMdl, nTrain, nTest, H)
% Variables:
% -x: πλήρης χρονοσειρά εισόδου (σε original κλίμακα)
% -EstMdl: εκτιμημένο ARMA μοντέλο σε μορφή arima(p,0,q) με Constant=0
% -nTrain: πλήθος δειγμάτων εκμάθησης
% -nTest: πλήθος δειγμάτων αξιολόγησης
% -H: μέγιστος ορίζοντας πρόβλεψης (1..H)
% -xTrain: training set (πρώτα nTrain δείγματα), κεντραρισμένο
% -xTest: test set (τελευταία nTest δείγματα), κεντραρισμένο με τον ίδιο μέσο
% -mu: μέσος του training set, μ_train = mean(xTrain_original)
% -yhat: πίνακας προβλέψεων (nTest x H) στο κεντραρισμένο πεδίο
% -i: δείκτης origin μέσα στο test set (expanding-origin rolling)
% -y0: διαθέσιμη ιστορία για forecast στο origin i (train + test μέχρι i-1)
% -h: ορίζοντας πρόβλεψης
% -f: forecast διάνυσμα μήκους h (1-step έως h-step από το origin)
% -nrmse: διάνυσμα NRMSE (1 x H) ανά ορίζοντα
% -T: πλήθος έγκυρων συγκρίσεων για τον ορίζοντα h
% -pred_h: προβλέψεις για τον ορίζοντα h
% -actual: πραγματικές τιμές test που αντιστοιχούν στις προβλέψεις (στο κεντραρισμένο πεδίο)
% -rmse: Root Mean Square Error για τον ορίζοντα h
% -out: struct εξόδου με yhat (σε original κλίμακα), nrmse, EstMdl

x = x(:);

% Ορισμός train/test και κεντράρισμα με βάση ΜΟΝΟ το training:
% μ_train = mean(x_train), ώστε το Constant=0 στο ARMA να είναι συνεπές
xTrain = x(1:nTrain);
xTest  = x(end-nTest+1:end);

mu = mean(xTrain);
xTrain = xTrain - mu;
xTest  = xTest - mu;

yhat = nan(nTest, H);

% Rolling (expanding-origin) πολυβηματικές προβλέψεις:
% στο origin i χρησιμοποιούμε ιστορικό y0 = [train + test(1:i-1)]
for i = 1:nTest
    y0 = [xTrain; xTest(1:i-1)];
    for h = 1:H
        % Η forecast επιστρέφει τις προβλέψεις 1..h βημάτων μπροστά,
        % και κρατάμε την τελευταία ως h-step ahead πρόβλεψη
        f = forecast(EstMdl, h, 'Y0', y0);
        yhat(i, h) = f(end);
    end
end

% NRMSE ανά ορίζοντα:
% RMSE(h)  = sqrt( (1/T) * Σ (actual - pred)^2 )
% NRMSE(h) = RMSE(h) / std(actual)
nrmse = nan(1, H);
for h = 1:H
    T = nTest - (h-1);
    pred_h = yhat(1:T, h);
    actual = xTest(1+(h-1):1+(h-1)+T-1);

    rmse = sqrt(mean((actual - pred_h).^2));
    nrmse(h) = rmse / std(actual);
end

out = struct();

% Επιστρέφουμε προβλέψεις στην original κλίμακα:
% \hat{x}_orig = \hat{x}_centered + μ_train
out.yhat = yhat + mu;

out.nrmse = nrmse;
out.EstMdl = EstMdl;
end

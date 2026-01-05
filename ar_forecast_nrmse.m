function out = ar_forecast_nrmse(x, p, nTrain, nTest, H)
% Variables:
% -x: πλήρης χρονοσειρά εισόδου (σε original κλίμακα)
% -p: τάξη του AR(p) μοντέλου
% -nTrain: πλήθος δειγμάτων εκμάθησης
% -nTest: πλήθος δειγμάτων αξιολόγησης
% -H: μέγιστος ορίζοντας πρόβλεψης (1..H)
% -xTrain: training set (πρώτα nTrain δείγματα), κεντραρισμένο
% -xTest: test set (τελευταία nTest δείγματα), κεντραρισμένο με τον ίδιο μέσο
% -mu: μέσος του training set, μ_train = mean(xTrain_original)
% -model: εκτιμημένο AR(p) με Yule–Walker πάνω στο κεντραρισμένο training
% -a: συντελεστές AR (p x 1)
% -yhat: προβλέψεις στο κεντραρισμένο πεδίο (nTest x H)
% -history: διαθέσιμο ιστορικό στο κεντραρισμένο πεδίο (train + όσα test έχουν εισαχθεί)
% -t: δείκτης χρονικής στιγμής μέσα στο test set
% -buf: τα τελευταία p δείγματα του history (state του AR)
% -preds: προβλέψεις 1..H βημάτων μπροστά στη χρονική στιγμή t
% -workBuf: buffer που ενημερώνεται με προβλεπόμενες τιμές (recursive forecasting)
% -h: ορίζοντας πρόβλεψης
% -nrmse: NRMSE ανά ορίζοντα (1 x H)
% -T: πλήθος έγκυρων συγκρίσεων για τον ορίζοντα h
% -pred_h: προβλέψεις h βημάτων μπροστά (στο κεντραρισμένο πεδίο)
% -actual: πραγματικές τιμές test για τον ορίζοντα h (κεντραρισμένες)
% -rmse: Root Mean Square Error για τον ορίζοντα h
% -out: struct εξόδου με model, yhat (σε original κλίμακα), nrmse

x = x(:);

% Ορίζουμε train/test και κεντράρουμε με βάση ΜΟΝΟ το training:
% μ_train = mean(x_train), ώστε να μην "διαρρέει" πληροφορία από το test set
xTrain = x(1:nTrain);
mu = mean(xTrain);
xTrain = xTrain - mu;

xTest  = x(end-nTest+1:end);
xTest = xTest - mu;

% Εκτίμηση AR(p) στο κεντραρισμένο training με Yule–Walker
model = fit_ar_yw(xTrain, p);
a = model.a(:);

yhat = NaN(nTest, H);

% Rolling (expanding-origin): σε κάθε t, το history περιέχει train + τα test δείγματα μέχρι t-1
history = xTrain;

for t = 1:nTest
    % Το AR(p) μοντέλο χρειάζεται τις p πιο πρόσφατες τιμές ως state
    buf = history(end-p+1:end);

    preds = zeros(H,1);
    workBuf = buf(:);

    % Recursive multi-step forecasting:
    % \hat{x}(t+1) = Σ_{k=1..p} a_k x(t+1-k)
    % Για ορίζοντες >1, οι προηγούμενες προβλέψεις μπαίνουν πίσω στο workBuf
    for h = 1:H
        xnext = flipud(workBuf)' * a;
        preds(h) = xnext;
        workBuf = [workBuf(2:end); xnext];
    end

    yhat(t,:) = preds';

    % Ενημέρωση ιστορικού με την πραγματική παρατήρηση του test (στο κεντραρισμένο πεδίο)
    history = [history; xTest(t)];
end

% NRMSE ανά ορίζοντα:
% RMSE(h)  = sqrt( (1/T) * Σ_{t=1..T} (actual(t) - pred(t))^2 )
% NRMSE(h) = RMSE(h) / std(actual)
nrmse = NaN(1,H);

for h = 1:H
    T = nTest - (h-1);
    pred_h = yhat(1:T, h);
    actual = xTest(1+(h-1):1+(h-1)+T-1);

    rmse = sqrt(mean((actual - pred_h).^2));
    nrmse(h) = rmse / std(actual);
end

out = struct();
out.model = model;

% Επιστροφή προβλέψεων στην original κλίμακα:
% \hat{x}_orig = \hat{x}_centered + μ_train
out.yhat = yhat + mu;

out.nrmse = nrmse;
end

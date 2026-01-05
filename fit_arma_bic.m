function out = fit_arma_bic(xFit, pRange, qRange)
% Variables:
% -xFit: χρονοσειρά που χρησιμοποιείται για fit/selection (στην πράξη: x - mean(x) από τον runner)
% -pRange: υποψήφιες τάξεις AR (p) που θα σαρωθούν
% -qRange: υποψήφιες τάξεις MA (q) που θα σαρωθούν
% -n: πλήθος παρατηρήσεων της xFit (εδώ όλη η διαθέσιμη σειρά που δόθηκε)
% -bicMat: πίνακας BIC με διαστάσεις length(pRange) x length(qRange)
% -estModels: cell array με τα εκτιμημένα μοντέλα για κάθε (p,q)
% -bestBIC: η μικρότερη τιμή BIC που έχει βρεθεί μέχρι στιγμής
% -best: struct που κρατά το καλύτερο (p,q) και το αντίστοιχο εκτιμημένο μοντέλο
% -ip,iq: δείκτες loop πάνω στα pRange/qRange
% -p,q: τρέχουσες τάξεις AR/MA
% -Mdl: "σκελετός" ARMA(p,q) ως arima(p,0,q) πριν την εκτίμηση
% -opts: επιλογές optimizer για estimate (σιωπηλή εκτέλεση)
% -EstMdl: τελικό εκτιμημένο μοντέλο με μέγιστη πιθανοφάνεια
% -logL: λογαριθμική πιθανοφάνεια στο optimum (Gaussian likelihood)
% -e: innovations από infer (χρησιμοποιούνται αλλού για diagnostics, εδώ δεν μπαίνουν στο BIC)
% -k: πλήθος παραμέτρων του μοντέλου (p + q + 1 για τη διασπορά)
% -bic: τιμή BIC για το ζεύγος (p,q)
% -out: struct εξόδου με pBest, qBest, EstMdlBest, bic, estModels, κλπ.

xFit = xFit(:);
n = numel(xFit);

bicMat = nan(numel(pRange), numel(qRange));
estModels = cell(numel(pRange), numel(qRange));

bestBIC = inf;
best = struct('p', NaN, 'q', NaN, 'mdl', []);

for ip = 1:numel(pRange)
    p = pRange(ip);
    for iq = 1:numel(qRange)
        q = qRange(iq);

        % Παραλείπουμε το (0,0) γιατί δεν ορίζει ουσιαστικό δυναμικό μοντέλο
        if p==0 && q==0
            continue;
        end

        try
            % ARMA(p,q) υλοποιείται ως ARIMA(p,0,q).
            % Θέλουμε Constant=0, επειδή η σειρά που δίνεται εδώ είναι ήδη κεντραρισμένη.
            Mdl = arima(p, 0, q);
            Mdl.Constant = 0;

            % Εκτίμηση παραμέτρων με μέγιστη πιθανοφάνεια (Gaussian innovations)
            opts = optimoptions('fmincon','Display','off');
            [EstMdl, ~, logL] = estimate(Mdl, xFit, 'Display','off', 'Options', opts);

            % Innovations (one-step-ahead errors). Τα κρατάμε σαν "παράπλευρη" πληροφορία,
            % αλλά το BIC εδώ βασίζεται απευθείας στο logL.
            e = infer(EstMdl, xFit);

            % BIC από log-likelihood:
            % BIC(p,q) = -2*logL + k*log(n)
            % με k = p + q + 1 (οι όροι AR/MA + 1 για τη διασπορά σ^2)
            k = p + q + 1;
            bic = -2*logL + k*log(n);

            bicMat(ip, iq) = bic;
            estModels{ip, iq} = EstMdl;

            % Κρατάμε το μοντέλο που ελαχιστοποιεί το BIC
            if bic < bestBIC
                bestBIC = bic;
                best.p = p; best.q = q; best.mdl = EstMdl;
            end

        catch
            % Αν η εκτίμηση αποτύχει (π.χ. μη-σταθερότητα/μη-αναγνωρισιμότητα), συνεχίζουμε
            bicMat(ip, iq) = NaN;
            estModels{ip, iq} = [];
        end
    end
end

out = struct();
out.pBest = best.p;
out.qBest = best.q;
out.EstMdlBest = best.mdl;
out.bic = bicMat;
out.estModels = estModels;
out.pRange = pRange;
out.qRange = qRange;
out.bestBIC = bestBIC;
end

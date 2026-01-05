function MI = mi_delay_hist(x, taus, nBins)
% Variables:
% -x: χρονοσειρά εισόδου (διάνυσμα παρατηρήσεων x(t))
% -taus: διάνυσμα θετικών ακεραίων υστερήσεων τ
% -nBins: αριθμός bins για την εκτίμηση πιθανοτήτων με ιστογράμματα
% -N: μήκος της χρονοσειράς
% -MI: διάνυσμα αμοιβαίας πληροφορίας, MI(i) = I(x(t); x(t+taus(i)))
% -lo, hi: κατώτερο και ανώτερο όριο αποκοπής (percentiles) για robustness
% -xClip: clipped εκδοχή της χρονοσειράς για μείωση επίδρασης ακραίων τιμών
% -edges: κοινά όρια bins για όλα τα τ (σταθερή διακριτοποίηση)
% -x1, x2: ζεύγη παρατηρήσεων (x(t), x(t+τ))
% -jointCounts: κοινό ιστόγραμμα (counts) των (x1,x2)
% -Pxy: κοινή κατανομή πιθανότητας p(x,y)
% -Px, Py: οριακές κατανομές p(x), p(y)
% -mask: λογικός πίνακας για p(x,y)>0 (αποφυγή log(0))
% -miSum: άθροισμα όρων της αμοιβαίας πληροφορίας για δεδομένο τ

x = x(:);

% Αφαίρεση μέσου όρου ώστε η MI να μετρά καθαρά χρονική εξάρτηση
% και όχι στατική μετατόπιση του σήματος
x = x - mean(x);

N = length(x);

% Αν δεν δοθεί αριθμός bins, επιλέγεται ασφαλής default τιμή
if nargin < 3 || isempty(nBins)
    nBins = 16;
end

taus = taus(:);
MI = NaN(size(taus));

% Robust clipping για περιορισμό επίδρασης ακραίων τιμών (outliers),
% κάτι που είναι σημαντικό για EEG χρονοσειρές
lo = prctile(x, 1);
hi = prctile(x, 99);
xClip = min(max(x, lo), hi);

% Σταθερά όρια bins για όλα τα τ,
% ώστε οι εκτιμήσεις MI(τ) να είναι συγκρίσιμες μεταξύ τους
edges = linspace(lo, hi, nBins+1);

for i = 1:numel(taus)
    tau = taus(i);

    % Μη έγκυρες υστερήσεις απορρίπτονται
    if tau <= 0 || tau >= N
        MI(i) = NaN;
        continue;
    end

    % Ορισμός των τυχαίων μεταβλητών:
    % X = x(t), Y = x(t+τ)
    x1 = xClip(1:N-tau);
    x2 = xClip(1+tau:N);

    % Εκτίμηση της κοινής κατανομής p(x,y) μέσω 2D ιστογράμματος
    jointCounts = histcounts2(x1, x2, edges, edges);
    Pxy = jointCounts / sum(jointCounts(:));

    % Οριακές κατανομές p(x) και p(y)
    Px = sum(Pxy, 2);
    Py = sum(Pxy, 1);

    % Υπολογισμός αμοιβαίας πληροφορίας:
    % I(X;Y) = Σ_{x,y} p(x,y) log( p(x,y) / (p(x)p(y)) )
    % Οι όροι με p(x,y)=0 αγνοούνται για αποφυγή log(0)
    mask = Pxy > 0;
    [ix, iy] = find(mask);

    miSum = 0;
    for k = 1:numel(ix)
        px = Px(ix(k));
        py = Py(iy(k));
        pxy = Pxy(ix(k), iy(k));

        % Θεωρητικά px,py>0 όταν pxy>0, αλλά κρατάμε έλεγχο ασφάλειας
        if px > 0 && py > 0
            miSum = miSum + pxy * log(pxy / (px * py));
        end
    end

    % Η MI επιστρέφεται σε nats (λογάριθμος βάσης e)
    % Για bits: MI_bits = MI / log(2)
    MI(i) = miSum;
end
end

function model = fit_ar_yw(x, p)
% Variables:
% -x: χρονοσειρά εισόδου που χρησιμοποιείται για προσαρμογή του AR (πρέπει να είναι ήδη κεντραρισμένη)
% -p: τάξη του AR(p)
% -N: πλήθος δειγμάτων της χρονοσειράς
% -r: εκτίμηση αυτοσυσχέτισης για υστερήσεις 0..p
% -R: Toeplitz πίνακας (p x p) αυτοσυσχετίσεων στις εξισώσεις Yule–Walker
% -rhs: διάνυσμα (p x 1) με r(1)..r(p)
% -a: συντελεστές AR (p x 1)
% -sigma2: εκτίμηση διασποράς καινοτομίας (innovation variance)
% -model: struct εξόδου με πεδία a, sigma2, p

x = x(:);
N = length(x);

% Εμπειρική αυτοσυσχέτιση (biased) μέχρι υστέρηση p:
% r(k) = (1/N) * Σ_{t=k+1..N} x(t) x(t-k), k=0..p
% Η συνάρτηση xcorr επιστρέφει συμμετρικά lags [-p..p], κρατάμε το κομμάτι 0..p
r = xcorr(x, p, 'biased');
r = r(p+1:end);

% Εξισώσεις Yule–Walker για AR(p):
% R a = rhs, όπου
% R = toeplitz([r(0) r(1) ... r(p-1)]), rhs = [r(1) ... r(p)]^T
R = toeplitz(r(1:p));
rhs = r(2:p+1);

% Λύση για τους συντελεστές του AR:
% x(t) = Σ_{k=1..p} a_k x(t-k) + e(t)
a = R \ rhs;

% Διασπορά καινοτομίας:
% σ_e^2 = r(0) - rhs^T a
sigma2 = r(1) - rhs' * a;

model = struct('a', a, 'sigma2', sigma2, 'p', p);
end

clear; clc;

% Φόρτωση παραμέτρων ανάλυσης (paths, fs, διαστάσεις επεισοδίων, κλπ.)
C = config();

% Δημιουργία φακέλου εξόδου ώστε να αποθηκεύονται αποτελέσματα/γραφήματα
if ~exist(C.outDir, 'dir'); mkdir(C.outDir); end

% Αντιστοίχιση του ΑΕΜ σε δείκτη καναλιού EEG με βάση τον κανόνα:
% el = mod(mod(AEM,100),60) + 1
el1 = aem_to_electrode(C.AEM1);
fprintf('AEM1=%d -> electrode=%d\n', C.AEM1, el1);

% Φόρτωση των τριών datasets (120%, 180%, 240%) και ανάκτηση του πίνακα cMF
D120 = load_tmseeg_mat(C.files.mat120, C);
D180 = load_tmseeg_mat(C.files.mat180, C);
D240 = load_tmseeg_mat(C.files.mat240, C);

% Έλεγχος ότι οι διαστάσεις που φορτώθηκαν είναι λογικές (n, K, M)
fprintf('Loaded 120: n=%d K=%d M=%d\n', D120.n, D120.K, D120.M);
fprintf('Loaded 180: n=%d K=%d M=%d\n', D180.n, D180.K, D180.M);
fprintf('Loaded 240: n=%d K=%d M=%d\n', D240.n, D240.K, D240.M);

% Εξαγωγή χρονοσειρών για το επιλεγμένο κανάλι:
% από cMF(n x K x M) -> X(n x M), όπου κάθε στήλη είναι ένα epoch
X120 = squeeze(D120.cMF(:, el1, :));
X180 = squeeze(D180.cMF(:, el1, :));
X240 = squeeze(D240.cMF(:, el1, :));

% Γρήγορος έλεγχος συνέπειας: η πρώτη διάσταση πρέπει να ισούται με n
assert(size(X120,1) == D120.n);
assert(size(X180,1) == D180.n);
assert(size(X240,1) == D240.n);

% Ορισμός άξονα χρόνου σε δευτερόλεπτα:
% t[i] = i / fs, i = 0,...,n-1
t = (0:(C.n-1)) / C.fs;

% Γρήγορο plot ενός epoch για να φανεί ότι το σήμα "μοιάζει" σωστό
% και ότι το TMS πέφτει στη θέση tmsSample
figure('Name','Quick check - 120%');
plot(t, X120(:,1)); hold on;
xline((C.tmsSample-1)/C.fs);
title(sprintf('120%% - electrode %d - epoch 1', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

% Προαιρετικά plot και δεύτερου epoch για οπτικό sanity check
if size(X120,2) >= 2
    figure('Name','Quick check - 120% epoch2');
    plot(t, X120(:,2)); hold on;
    xline((C.tmsSample-1)/C.fs);
    title(sprintf('120%% - electrode %d - epoch 2', el1));
    xlabel('Time (s)'); ylabel('EEG (a.u.)');
end
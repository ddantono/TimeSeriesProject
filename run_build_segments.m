clear; clc;

% Ορισμός παραμέτρων/paths και επιλογή καναλιού από το ΑΕΜ
C = config();
el1 = aem_to_electrode(C.AEM1);
savePrefix = sprintf('AEM%d_el%d', C.AEM1, el1);

% Φόρτωση των τριών datasets (120%, 180%, 240%) και απομόνωση του καναλιού el1
D120 = load_tmseeg_mat(C.files.mat120, C);
D180 = load_tmseeg_mat(C.files.mat180, C);
D240 = load_tmseeg_mat(C.files.mat240, C);

% Από cMF(n x K x M) κρατάμε μόνο το κανάλι el1 -> X(n x M)
X120 = squeeze(D120.cMF(:, el1, :));
X180 = squeeze(D180.cMF(:, el1, :));
X240 = squeeze(D240.cMF(:, el1, :));

% Φόρτωση των δεικτών ποιοτικού ελέγχου (QC) που καθορίζουν ποια epochs κρατάμε
qc120file = fullfile(C.outDir, sprintf('QC_%s_%s.mat', 'P120', savePrefix));
qc180file = fullfile(C.outDir, sprintf('QC_%s_%s.mat', 'P180', savePrefix));
qc240file = fullfile(C.outDir, sprintf('QC_%s_%s.mat', 'P240', savePrefix));

assert(isfile(qc120file), 'Missing QC file: %s', qc120file);
assert(isfile(qc180file), 'Missing QC file: %s', qc180file);
assert(isfile(qc240file), 'Missing QC file: %s', qc240file);

S120 = load(qc120file, 'selectedIdx');
S180 = load(qc180file, 'selectedIdx');
S240 = load(qc240file, 'selectedIdx');

% Οι δείκτες epochs μπαίνουν σε μορφή row-vector για ευκολία σε loops/printing
idx120 = S120.selectedIdx(:)';
idx180 = S180.selectedIdx(:)';
idx240 = S240.selectedIdx(:)';

fprintf('Selected N (P120/P180/P240) = %d / %d / %d\n', numel(idx120), numel(idx180), numel(idx240));

% Για κάθε ένταση, παίρνουμε τα επιλεγμένα epochs και τα κόβουμε σε:
% preTMS:  πρώτα 0.9 s  -> pre_n δείγματα
% postTMS: τελευταία 0.9 s -> post_n δείγματα
% με pre_n = round(0.9*fs), post_n = round(0.9*fs)
[pre120, post120] = build_segments_from_indices(X120, idx120, C);
[pre180, post180] = build_segments_from_indices(X180, idx180, C);
[pre240, post240] = build_segments_from_indices(X240, idx240, C);

% Αποθήκευση των segments και ενός meta struct για traceability (ΑΕΜ, κανάλι, fs, indices)
out120 = fullfile(C.outDir, sprintf('Segments_P120_%s.mat', savePrefix));
out180 = fullfile(C.outDir, sprintf('Segments_P180_%s.mat', savePrefix));
out240 = fullfile(C.outDir, sprintf('Segments_P240_%s.mat', savePrefix));

meta = struct();
meta.AEM = C.AEM1;
meta.electrode = el1;
meta.fs = C.fs;
meta.n = C.n;
meta.pre_n = C.pre_n;
meta.post_n = C.post_n;
meta.idx120 = idx120;
meta.idx180 = idx180;
meta.idx240 = idx240;

save(out120, 'pre120', 'post120', 'meta');
save(out180, 'pre180', 'post180', 'meta');
save(out240, 'pre240', 'post240', 'meta');

fprintf('Saved:\n  %s\n  %s\n  %s\n', out120, out180, out240);

% Δημιουργία άξονα χρόνου για pre και post τμήματα:
% t[i] = i/fs, i = 0,...,L-1
tpre  = (0:(C.pre_n-1))/C.fs;
tpost = (0:(C.post_n-1))/C.fs;

blue   = [0 0.4470 0.7410];
orange = [0.8500 0.3250 0.0980];

% Οπτικός έλεγχος στο 1ο segment κάθε περίπτωσης, για να επιβεβαιωθεί ότι ο τεμαχισμός "βγάζει νόημα"
figure('Name','P120 pre');
plot(tpre, pre120(:,1), 'Color', blue, 'LineWidth', 1.2);
title(sprintf('P120 pre | el %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

figure('Name','P120 post');
plot(tpost, post120(:,1), 'Color', orange, 'LineWidth', 1.2);
title(sprintf('P120 post | el %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

figure('Name','P180 pre');
plot(tpre, pre180(:,1), 'Color', blue, 'LineWidth', 1.2);
title(sprintf('P180 pre | el %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

figure('Name','P180 post');
plot(tpost, post180(:,1), 'Color', orange, 'LineWidth', 1.2);
title(sprintf('P180 post | el %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

figure('Name','P240 pre');
plot(tpre, pre240(:,1), 'Color', blue, 'LineWidth', 1.2);
title(sprintf('P240 pre | el %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

figure('Name','P240 post');
plot(tpost, post240(:,1), 'Color', orange, 'LineWidth', 1.2);
title(sprintf('P240 post | el %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');


function [PRE, POST] = build_segments_from_indices(X, idx, C)
    % Variables:
    % -X: πίνακας σήματος για ένα κανάλι, διαστάσεων n x M (M epochs)
    % -idx: δείκτες των επιλεγμένων epochs που θα χρησιμοποιηθούν (1 x N)
    % -C: struct παραμέτρων (pre_n, post_n, idx_pre, idx_post, n)
    % -N: πλήθος επιλεγμένων epochs
    % -PRE: πίνακας preTMS segments, διαστάσεων pre_n x N
    % -POST: πίνακας postTMS segments, διαστάσεων post_n x N
    % -ii: μετρητής loop πάνω στα επιλεγμένα epochs
    % -e: ένα πλήρες epoch (n x 1)
    % -p: preTMS τμήμα (pre_n x 1)
    % -q: postTMS τμήμα (post_n x 1)
    
    % Προδέσμευση μνήμης για τα segments ώστε το loop να είναι γρήγορο και καθαρό
    N = numel(idx);
    PRE  = zeros(C.pre_n,  N);
    POST = zeros(C.post_n, N);
    
    % Για κάθε επιλεγμένο epoch: κόβουμε pre/post και τα αποθηκεύουμε σε στήλες
    for ii = 1:N
        e = X(:, idx(ii));
        [p, q] = split_pre_post(e, C);
        PRE(:, ii)  = p;
        POST(:, ii) = q;
    end

end

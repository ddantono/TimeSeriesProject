clear; clc;

% Φόρτωση παραμέτρων (paths, fs, διαστάσεις) και υπολογισμός καναλιού από το ΑΕΜ
C = config();
el1 = aem_to_electrode(C.AEM1);
savePrefix = sprintf('AEM%d_el%d', C.AEM1, el1);

% Φόρτωση των τριών καταγραφών (120%, 180%, 240%) από τα αντίστοιχα .mat
D120 = load_tmseeg_mat(C.files.mat120, C);
D180 = load_tmseeg_mat(C.files.mat180, C);
D240 = load_tmseeg_mat(C.files.mat240, C);

% Απομόνωση του καναλιού el1:
% από cMF(n x K x M) -> X(n x M), όπου κάθε στήλη είναι ένα epoch
X120 = squeeze(D120.cMF(:, el1, :));
X180 = squeeze(D180.cMF(:, el1, :));
X240 = squeeze(D240.cMF(:, el1, :));

% Διαδραστικός ποιοτικός έλεγχος (keep/reject) για κάθε ένταση
% και τυχαία επιλογή έως N "καθαρών" epochs με σταθερό seed (αναπαραγωγιμότητα)
[keep120, sel120] = qc_review_epochs(X120, C, 'P120', el1, savePrefix);
[keep180, sel180] = qc_review_epochs(X180, C, 'P180', el1, savePrefix);
[keep240, sel240] = qc_review_epochs(X240, C, 'P240', el1, savePrefix);

% Εκτύπωση των τελικών δεικτών epochs που θα περάσουν στην ανάλυση
disp('Selected epoch indices:');
fprintf('P120: %s\n', mat2str(sel120));
fprintf('P180: %s\n', mat2str(sel180));
fprintf('P240: %s\n', mat2str(sel240));

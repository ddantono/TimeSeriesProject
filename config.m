function C = config()
% Variables:
% -C: struct που συγκεντρώνει όλες τις παραμέτρους και ρυθμίσεις της ανάλυσης

C.AEM1 = 10620;

% Ορίζεται ο βασικός φάκελος εργασίας και ο φάκελος εξόδου για αποτελέσματα
C.baseDir = 'C:\Users\DIMITRIS\OneDrive\ΗΜΜΥ\9ο εξάμηνο\Χρονοσειρές\Υπολογιστική';
C.outDir  = fullfile(C.baseDir, 'out');

% Πλήρη paths προς τα αρχεία .mat για τα τρία επίπεδα έντασης TMS
C.files.mat120 = fullfile(C.baseDir, 'P_HF_I036_P120_v3_V2022CL.mat');
C.files.mat180 = fullfile(C.baseDir, 'P_HF_I054_P180_v3_V2022CL.mat');
C.files.mat240 = fullfile(C.baseDir, 'P_HF_I072_P240_v3_V2022CL.mat');
C.files.channelsTxt = fullfile(C.baseDir, 'Channels.txt');

% Βασικές παράμετροι καταγραφής EEG
C.fs = 1450;          % συχνότητα δειγματοληψίας (Hz)
C.n  = 2901;          % συνολικός αριθμός δειγμάτων ανά επεισόδιο
C.k  = 60;            % αριθμός καναλιών EEG
C.tmsSample = 1451;   % χρονικό δείγμα στο οποίο εφαρμόζεται το TMS

% Διάρκειες preTMS και postTMS σε milliseconds
C.pre_ms  = 900;
C.post_ms = 900;

% Μετατροπή διάρκειας από ms σε αριθμό δειγμάτων:
% n_samples = (duration_ms / 1000) * fs
C.pre_n  = round(C.pre_ms/1000 * C.fs);
C.post_n = round(C.post_ms/1000 * C.fs);

% Δείκτες για την εξαγωγή των preTMS και postTMS τμημάτων
C.idx_pre  = 1:C.pre_n;
C.idx_post = (C.n - C.post_n + 1):C.n;

% Αριθμός επεισοδίων που θα χρησιμοποιηθούν στην ανάλυση
C.N = 20;

% Seed για τον γεννήτορα τυχαίων αριθμών, ώστε η επιλογή επεισοδίων
% να είναι αναπαραγώγιμη
C.rngSeed = 42;

end

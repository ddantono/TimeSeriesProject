clear; clc;

C = config();
el1 = aem_to_electrode(C.AEM1);
savePrefix = sprintf('AEM%d_el%d', C.AEM1, el1);

nTrain = 600;
nTest  = 300;
H      = 1;
tauMI  = 1;
nBins  = 16;

linFile = fullfile(C.outDir, sprintf('LinearResults_AR_Pilot6_%s.mat', savePrefix));
assert(isfile(linFile), 'Missing: %s', linFile);
Slin = load(linFile, 'results');
Rlin = Slin.results;

% Φτιάχνουμε αντιστοίχιση: όνομα χρονοσειράς -> βέλτιστη τάξη AR από την πιλοτική μελέτη
% Η λογική είναι να "κλειδώσουμε" τις τάξεις AR και να τις εφαρμόσουμε μαζικά στα N epochs
pMap = containers.Map();
for i = 1:numel(Rlin)
    pMap(Rlin(i).name) = Rlin(i).pBest;
end

p120pre  = pMap('P120_pre');
p120post = pMap('P120_post');
p180pre  = pMap('P180_pre');
p180post = pMap('P180_post');
p240pre  = pMap('P240_pre');
p240post = pMap('P240_post');

fprintf('Using fixed pilot AR orders:\n');
fprintf(' P120 pre/post : %d / %d\n', p120pre, p120post);
fprintf(' P180 pre/post : %d / %d\n', p180pre, p180post);
fprintf(' P240 pre/post : %d / %d\n', p240pre, p240post);

% Βοηθητικό wrapper που εφαρμόζει τα "κλειδωμένα" measures σε έναν πίνακα segments:
% X: (samples x N), όπου κάθε στήλη είναι ένα epoch
% Επιστρέφει πίνακα/πίνακα-δομή με 1 γραμμικό και 1 μη-γραμμικό μέτρο ανά epoch
processMat = @(X, intensity, cond, pUse) process_segments_matrix(X, intensity, cond, pUse, nTrain, nTest, H, tauMI, nBins);

f120 = fullfile(C.outDir, sprintf('Segments_P120_%s.mat', savePrefix));
f180 = fullfile(C.outDir, sprintf('Segments_P180_%s.mat', savePrefix));
f240 = fullfile(C.outDir, sprintf('Segments_P240_%s.mat', savePrefix));
assert(isfile(f120) && isfile(f180) && isfile(f240), 'Missing one or more Segments files.');

S120 = load(f120);
S180 = load(f180);
S240 = load(f240);

% Για κάθε ένταση, επεξεργαζόμαστε χωριστά preTMS και postTMS:
% προκύπτουν 6 "μπλοκ" γραμμών (ένα ανά κατηγορία: intensity × condition)
T120pre  = processMat(S120.pre120,  120, "pre",  p120pre);
T120post = processMat(S120.post120, 120, "post", p120post);

T180pre  = processMat(S180.pre180,  180, "pre",  p180pre);
T180post = processMat(S180.post180, 180, "post", p180post);

T240pre  = processMat(S240.pre240,  240, "pre",  p240pre);
T240post = processMat(S240.post240, 240, "post", p240post);

% Συνένωση όλων των αποτελεσμάτων ώστε να έχουμε ένα ενιαίο dataset 6×N γραμμών
T = [T120pre; T120post; T180pre; T180post; T240pre; T240post];

outFile = fullfile(C.outDir, sprintf('Measures_%s.mat', savePrefix));
save(outFile, 'T', 'nTrain','nTest','H','tauMI','nBins', ...
    'p120pre','p120post','p180pre','p180post','p240pre','p240post');
fprintf('Saved Step 7 measures: %s\n', outFile);

% Παραγωγή των συγκριτικών γραφημάτων (pre vs post, intensity comparisons, baseline correction)
make_plots(T, C, savePrefix);

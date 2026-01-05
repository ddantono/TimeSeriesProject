function [keepIdx, selectedIdx] = qc_review_epochs(X, C, tag, el, savePrefix)
% Variables:
% -X: πίνακας epochs ενός καναλιού (n x M), κάθε στήλη ένα επεισόδιο EEG
% -C: struct ρυθμίσεων (fs, n, pre_n, post_n, tmsSample, N, rngSeed, outDir)
% -tag: label dataset (π.χ. 'P120', 'P180', 'P240')
% -el: δείκτης ηλεκτροδίου (1..60)
% -savePrefix: label για naming των αρχείων εξόδου (π.χ. 'AEM10621_el22')
% -M: πλήθος epochs (στήλες του X)
% -keepIdx: λογικό διάνυσμα 1 x M (true = κρατάμε το epoch)
% -decided: λογικό διάνυσμα 1 x M (true = έχει παρθεί απόφαση για το epoch)
% -t: χρονικός άξονας του epoch σε δευτερόλεπτα
% -pre_t_end: χρονική στιγμή που τελειώνει το pre τμήμα (οπτικός οδηγός)
% -post_t_start: χρονική στιγμή που ξεκινά το post τμήμα (οπτικός οδηγός)
% -hFig: handle του παραθύρου QC
% -S: state struct αποθηκευμένο στο figure μέσω guidata (κρατά το τελευταίο command)
% -i: δείκτης τρέχοντος epoch προς αξιολόγηση
% -y: σήμα του τρέχοντος epoch (n x 1)
% -gotDecision: flag που δείχνει αν δόθηκε έγκυρη απόφαση (k/r/q)
% -cmd: το πλήκτρο που πατήθηκε (σε lower-case)
% -cleanIdx: indices όλων των epochs που επιλέχθηκαν ως "keep"
% -perm: τυχαία επιλογή C.N δεικτών (αναπαράξιμη μέσω rngSeed)
% -selectedIdx: τελικοί δείκτες των epochs που θα χρησιμοποιηθούν στην ανάλυση (<= C.N)
% -saveFile: αρχείο .mat όπου αποθηκεύεται το αποτέλεσμα QC
%
% Controls (στο ενεργό παράθυρο figure):
% -k: KEEP
% -r: REJECT
% -q: QUIT (τερματισμός νωρίς)

assert(size(X,1) == C.n, 'X must be n x M with n=C.n');

M = size(X,2);
keepIdx = false(1, M);
decided = false(1, M);

t = (0:(C.n-1)) / C.fs;
pre_t_end    = (C.pre_n-1) / C.fs;
post_t_start = (C.n - C.post_n) / C.fs;

% Δημιουργούμε figure με callbacks:
% -KeyPressFcn: καταγράφει το πλήκτρο και κάνει uiresume για να συνεχίσει ο βρόχος
% -CloseRequestFcn: "καθαρή" έξοδος ακόμα κι αν είμαστε σε uiwait
hFig = figure('Name', sprintf('QC %s | electrode %d | %s', tag, el, savePrefix), ...
              'NumberTitle', 'off', ...
              'KeyPressFcn', @onKey, ...
              'CloseRequestFcn', @onClose);

% State του figure: κρατάμε την τελευταία εντολή (cmd) που πατήθηκε
S.cmd = '';
guidata(hFig, S);

i = 1;
while i <= M && isvalid(hFig)

    % Καθαρίζουμε ρητά το συγκεκριμένο figure (ώστε να μην "καθαρίσει" λάθος παράθυρο)
    clf(hFig);
    y = X(:, i);

    plot(t, y); hold on;
    xline((C.tmsSample-1)/C.fs, '--', 'TMS');
    xline(pre_t_end, ':');
    xline(post_t_start, ':');

    title(sprintf('%s | electrode %d | epoch %d/%d', tag, el, i, M));
    xlabel('Time (s)'); ylabel('EEG (a.u.)');

    txt = {'k = KEEP', 'r = REJECT', 'q = QUIT'};
    annotation(hFig, 'textbox', [0.78 0.80 0.18 0.14], ...
               'String', txt, 'FitBoxToText', 'on');

    drawnow;

    % Περιμένουμε μέχρι να δοθεί έγκυρη εντολή:
    % uiwait "παγώνει" την εκτέλεση μέχρι να καλεστεί uiresume από το onKey/onClose
    gotDecision = false;
    while ~gotDecision && isvalid(hFig)
        uiwait(hFig);

        if ~isvalid(hFig), break; end

        S = guidata(hFig);
        cmd = lower(S.cmd);
        S.cmd = '';
        guidata(hFig, S);

        switch cmd
            case 'k'
                keepIdx(i) = true;
                decided(i) = true;
                gotDecision = true;

            case 'r'
                keepIdx(i) = false;
                decided(i) = true;
                gotDecision = true;

            case 'q'
                % Τερματισμός νωρίς: αφήνουμε τα υπόλοιπα ως undecided -> reject στο τέλος
                i = M + 1;
                gotDecision = true;

            otherwise
                % Αγνοούμε οποιοδήποτε άλλο πλήκτρο
        end
    end

    i = i + 1;
end

% Ό,τι δεν αποφασίστηκε ρητά θεωρείται reject (συντηρητική επιλογή)
keepIdx(~decided) = false;

% Επιλογή έως C.N "καθαρών" epochs με αναπαράξιμο τρόπο (rngSeed)
cleanIdx = find(keepIdx);
rng(C.rngSeed);

if numel(cleanIdx) > C.N
    perm = randperm(numel(cleanIdx), C.N);
    selectedIdx = sort(cleanIdx(perm));
else
    selectedIdx = cleanIdx;
end

% Αποθήκευση αποτελεσμάτων QC για να χρησιμοποιηθούν στα επόμενα στάδια (segments/massive)
if ~exist(C.outDir, 'dir'); mkdir(C.outDir); end
saveFile = fullfile(C.outDir, sprintf('QC_%s_%s.mat', tag, savePrefix));
save(saveFile, 'keepIdx', 'selectedIdx', 'tag', 'el', 'M');

fprintf('[QC] %s: kept %d/%d epochs, selected %d for analysis. Saved: %s\n', ...
        tag, numel(cleanIdx), M, numel(selectedIdx), saveFile);

function onKey(src, evt)
% Variables:
% -src: handle του figure που δέχεται το keypress
% -evt: struct event με πεδίο Key (π.χ. 'k','r','q')
% -S: state που αποθηκεύεται στο figure μέσω guidata
%
% Καταγράφουμε το πλήκτρο στο S.cmd και κάνουμε uiresume για να συνεχίσει ο βρόχος QC

    S = guidata(src);
    S.cmd = evt.Key;
    guidata(src, S);
    uiresume(src);
end

function onClose(src, ~)
% Variables:
% -src: handle του figure που κλείνει
%
% Αν είμαστε σε uiwait, κάνουμε πρώτα uiresume ώστε να μην "κολλήσει" ο βρόχος,
% και μετά διαγράφουμε το παράθυρο

    if strcmp(get(src,'WaitStatus'),'waiting')
        uiresume(src);
    end
    delete(src);
end

end

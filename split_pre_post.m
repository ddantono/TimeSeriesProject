function [preSeg, postSeg] = split_pre_post(epoch, C)
% Variables:
% -epoch: μονοδιάστατη χρονοσειρά EEG ενός επεισοδίου (μήκους n δειγμάτων)
% -C: struct παραμέτρων που περιέχει n, δείκτες pre/post και ρυθμίσεις χρόνου
% -preSeg: τμήμα preTMS (900 ms πριν το TMS, σε δείγματα)
% -postSeg: τμήμα postTMS (900 ms μετά το TMS, σε δείγματα)

% Έλεγχος ότι το epoch είναι διάνυσμα
assert(isvector(epoch), 'epoch must be a vector');

% Εξασφάλιση μορφής στήλης για συνέπεια
epoch = epoch(:);

% Έλεγχος ότι το μήκος του επεισοδίου συμφωνεί με το αναμενόμενο n
if length(epoch) ~= C.n
    error('Expected epoch length %d, got %d', C.n, length(epoch));
end

% Εξαγωγή preTMS τμήματος:
% τα πρώτα pre_n δείγματα, που αντιστοιχούν σε 0.9 s πριν το TMS
preSeg = epoch(C.idx_pre);

% Εξαγωγή postTMS τμήματος:
% τα τελευταία post_n δείγματα, που αντιστοιχούν σε 0.9 s μετά το TMS,
% αποκλείοντας το παράθυρο άμεσης απόκρισης στο TMS
postSeg = epoch(C.idx_post);

end

function D = load_tmseeg_mat(matFile, C)
% Variables:
% -matFile: πλήρες path προς το αρχείο .mat που περιέχει τα δεδομένα EEG
% -C: struct παραμέτρων (π.χ. αναμενόμενες διαστάσεις n και K)
% -S: struct που προκύπτει από τη φόρτωση του αρχείου .mat
% -cMF: τρισδιάστατος πίνακας EEG δεδομένων (χρόνος x κανάλια x επεισόδια)
% -n: αριθμός χρονικών δειγμάτων ανά επεισόδιο
% -K: αριθμός καναλιών EEG
% -M: αριθμός επεισοδίων TMS
% -D: struct εξόδου που συγκεντρώνει δεδομένα και βασικά μεταδεδομένα

if ~isfile(matFile)
    error('File not found: %s', matFile);
end

% Φόρτωση του αρχείου .mat στη μνήμη
S = load(matFile);

% Έλεγχος ότι υπάρχει ο πίνακας cMF, ο οποίος χρησιμοποιείται στην ανάλυση
if ~isfield(S, 'cMF')
    error('The file %s does not contain variable "cMF".', matFile);
end

cMF = S.cMF;

% Έλεγχος ότι τα δεδομένα έχουν τη σωστή τρισδιάστατη μορφή
% (χρόνος x κανάλια x επεισόδια)
if ndims(cMF) ~= 3
    error('cMF must be a 3D array (n x K x M).');
end

% Ανάκτηση διαστάσεων του πίνακα δεδομένων
[n, K, M] = size(cMF);

% Έλεγχος συμβατότητας με τις αναμενόμενες διαστάσεις από το config
if n ~= C.n
    warning('Expected n=%d but got n=%d in %s.', C.n, n, matFile);
end
if K ~= C.k
    warning('Expected K=%d but got K=%d in %s.', C.k, K, matFile);
end

% Οργάνωση των δεδομένων και των μεταδεδομένων σε struct εξόδου
D = struct();
D.file = matFile;
D.cMF  = cMF;
D.n = n;
D.K = K;
D.M = M;

end

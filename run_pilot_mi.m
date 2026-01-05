clear; clc;

C = config();
el1 = aem_to_electrode(C.AEM1);
savePrefix = sprintf('AEM%d_el%d', C.AEM1, el1);

pilotFile = fullfile(C.outDir, sprintf('Pilot6_%s.mat', savePrefix));
assert(isfile(pilotFile), 'Missing pilot file: %s', pilotFile);

S = load(pilotFile, 'pilot');
pilot = S.pilot;

% Οι 6 πιλοτικές χρονοσειρές που θα συγκρίνουμε (pre/post για 3 εντάσεις)
seriesList = {
    pilot.P120.pre,  'P120_pre'
    pilot.P120.post, 'P120_post'
    pilot.P180.pre,  'P180_pre'
    pilot.P180.post, 'P180_post'
    pilot.P240.pre,  'P240_pre'
    pilot.P240.post, 'P240_post'
};

% Υστερήσεις τ που θα σαρώσουμε για MI(τ) και αριθμός bins για histogram-based εκτίμηση πιθανοτήτων
taus = 1:100;
nBins = 16;

MI_curves = struct();
MI_saved = NaN(100, 6);

% Στόχος εδώ είναι να δούμε τις καμπύλες MI(τ) και να πάρουμε ένα scalar μέτρο για σύγκριση
figure('Name','Pilot MI(tau) curves');
hold on; grid on;
xlabel('\tau (lag)'); ylabel('MI(\tau) (nats)');
title(sprintf('Pilot 6 Mutual Information curves | %s', savePrefix));

for sIdx = 1:size(seriesList,1)
    x = seriesList{sIdx,1};
    name = seriesList{sIdx,2};

    % Αμοιβαία πληροφορία μεταξύ X=x(t) και Y=x(t+τ):
    % I(X;Y) = Σ_{x,y} p(x,y) log( p(x,y) / (p(x)p(y)) )
    % Εδώ οι p(.) εκτιμώνται με ιστογράμματα (nBins bins)
    MI = mi_delay_hist(x, taus, nBins);
    MI_saved(:,sIdx) = MI;

    % Εντοπισμός πρώτου τοπικού ελαχίστου της MI(τ):
    % τ* τέτοιο ώστε MI(τ*) < MI(τ*-1) και MI(τ*) < MI(τ*+1)
    % Χρησιμοποιείται συχνά ως επιλογή delay στην εμβύθιση (Takens)
    tauStar = NaN;
    for k = 2:(numel(MI)-1)
        if MI(k) < MI(k-1) && MI(k) < MI(k+1)
            tauStar = taus(k);
            break;
        end
    end
    MI_curves(sIdx).tauStar = tauStar;

    % Αποθήκευση καμπύλης MI(τ) και ενός "ασφαλούς" scalar μέτρου MI(1) για σύγκριση
    MI_curves(sIdx).name = name;
    MI_curves(sIdx).taus = taus;
    MI_curves(sIdx).MI = MI;
    MI_curves(sIdx).MI1 = MI(1);

    % Plot καμπύλης MI(τ) για την τρέχουσα χρονοσειρά
    plot(taus, MI, '-o', 'DisplayName', sprintf('%s (MI1=%.3g)', name, MI(1)));
end

legend('Location','best');

% Αποθήκευση σχήματος και αποτελεσμάτων για την αναφορά
figPath = fullfile(C.outDir, sprintf('Pilot6_MI_curves_%s.png', savePrefix));
saveas(gcf, figPath);

outFile = fullfile(C.outDir, sprintf('Nonlinear_MI_Pilot6_%s.mat', savePrefix));
save(outFile, 'MI_curves', 'taus', 'nBins');

fprintf('Saved MI pilot results: %s\n', outFile);
fprintf('Saved MI figure: %s\n', figPath);

% Εκτύπωση των MI(1) για συνοπτική σύγκριση μεταξύ των 6 περιπτώσεων
fprintf('\nMI(1) values (nonlinear measure) for pilot 6:\n');
for sIdx = 1:numel(MI_curves)
    fprintf('  %-9s : MI(1)=%.6g\n', MI_curves(sIdx).name, MI_curves(sIdx).MI1);
end

% Εκτύπωση του τ* (πρώτο τοπικό ελάχιστο) όπου υπάρχει, σαν κριτήριο επιλογής delay
fprintf('\nFirst local minimum lag tau* from MI(tau):\n');
for sIdx = 1:numel(MI_curves)
    ts = MI_curves(sIdx).tauStar;
    if isnan(ts)
        fprintf('  %-9s : tau* = (no clear local minimum in tau=1..%d)\n', ...
            MI_curves(sIdx).name, max(taus));
    else
        fprintf('  %-9s : tau* = %d\n', MI_curves(sIdx).name, ts);
    end
end

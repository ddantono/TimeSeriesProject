clear; clc;

% Φόρτωση ρυθμίσεων και επιλογή καναλιού από το ΑΕΜ
C = config();
el1 = aem_to_electrode(C.AEM1);
savePrefix = sprintf('AEM%d_el%d', C.AEM1, el1);

% Φόρτωση των ήδη αποθηκευμένων segments (pre/post) για κάθε ένταση
f120 = fullfile(C.outDir, sprintf('Segments_P120_%s.mat', savePrefix));
f180 = fullfile(C.outDir, sprintf('Segments_P180_%s.mat', savePrefix));
f240 = fullfile(C.outDir, sprintf('Segments_P240_%s.mat', savePrefix));

assert(isfile(f120), 'Missing: %s', f120);
assert(isfile(f180), 'Missing: %s', f180);
assert(isfile(f240), 'Missing: %s', f240);

S120 = load(f120, 'pre120', 'post120', 'meta');
S180 = load(f180, 'pre180', 'post180', 'meta');
S240 = load(f240, 'pre240', 'post240', 'meta');

% Επιλογή ενός τυχαίου index epoch ανά ένταση, με σταθερό seed για αναπαραγωγιμότητα
rng(C.rngSeed);
i120 = randi(size(S120.pre120, 2));
i180 = randi(size(S180.pre180, 2));
i240 = randi(size(S240.pre240, 2));

pilot = struct();
pilot.indices.P120 = i120;
pilot.indices.P180 = i180;
pilot.indices.P240 = i240;

% Εξαγωγή των 6 πιλοτικών χρονοσειρών (pre/post για κάθε ένταση), ως στήλες
pilot.P120.pre  = S120.pre120(:, i120);
pilot.P120.post = S120.post120(:, i120);

pilot.P180.pre  = S180.pre180(:, i180);
pilot.P180.post = S180.post180(:, i180);

pilot.P240.pre  = S240.pre240(:, i240);
pilot.P240.post = S240.post240(:, i240);

% Αποθήκευση της πιλοτικής επιλογής ώστε να μπορεί να αναπαραχθεί ακριβώς
pilotFile = fullfile(C.outDir, sprintf('Pilot6_%s.mat', savePrefix));
save(pilotFile, 'pilot', 'savePrefix');
fprintf('Saved pilot selection: %s\n', pilotFile);

% Άξονας χρόνου για τα segments:
% t[i] = i/fs, i = 0,...,L-1 (εδώ L = pre_n = post_n)
t = (0:(C.pre_n-1))/C.fs;

% Γρήγορα plots των 6 χρονοσειρών για να δούμε μορφολογία/κλίμακα
figure('Name','Pilot P120 pre');
plot(t, pilot.P120.pre, 'LineWidth', 1.2);
title(sprintf('Pilot P120 pre | electrode %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

figure('Name','Pilot P120 post');
plot(t, pilot.P120.post, 'LineWidth', 1.2);
title(sprintf('Pilot P120 post | electrode %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

figure('Name','Pilot P180 pre');
plot(t, pilot.P180.pre, 'LineWidth', 1.2);
title(sprintf('Pilot P180 pre | electrode %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

figure('Name','Pilot P180 post');
plot(t, pilot.P180.post, 'LineWidth', 1.2);
title(sprintf('Pilot P180 post | electrode %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

figure('Name','Pilot P240 pre');
plot(t, pilot.P240.pre, 'LineWidth', 1.2);
title(sprintf('Pilot P240 pre | electrode %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

figure('Name','Pilot P240 post');
plot(t, pilot.P240.post, 'LineWidth', 1.2);
title(sprintf('Pilot P240 post | electrode %d', el1));
xlabel('Time (s)'); ylabel('EEG (a.u.)');

% Ορισμός μέγιστης υστέρησης για ACF/PACF
maxLag = 200;

% Υπολογισμός/απεικόνιση ACF και PACF για κάθε μία από τις 6 πιλοτικές χρονοσειρές
plot_acf_pacf(pilot.P120.pre,  C, maxLag, 'P120 pre');
plot_acf_pacf(pilot.P120.post, C, maxLag, 'P120 post');
plot_acf_pacf(pilot.P180.pre,  C, maxLag, 'P180 pre');
plot_acf_pacf(pilot.P180.post, C, maxLag, 'P180 post');
plot_acf_pacf(pilot.P240.pre,  C, maxLag, 'P240 pre');
plot_acf_pacf(pilot.P240.post, C, maxLag, 'P240 post');

function plot_acf_pacf(x, C, maxLag, titleTag)
% Variables:
% -x: χρονοσειρά προς ανάλυση (segment pre ή post)
% -C: struct παραμέτρων (δεν χρησιμοποιείται άμεσα εδώ, αλλά κρατιέται για ομοιομορφία)
% -maxLag: μέγιστη υστέρηση (k) για την οποία υπολογίζεται ACF/PACF
% -titleTag: κείμενο για τίτλους/ονόματα figure
%
% -ACF:  ρ(k) = γ(k) / γ(0), όπου γ(k)=E[(x_t-μ)(x_{t-k}-μ)]
% -PACF: φ_kk, ο μερικός συντελεστής συσχέτισης στη υστέρηση k (με "αφαίρεση" των ενδιάμεσων υστερήσεων)

% Αφαίρεση μέσου ώστε η εμπειρική αυτοσυσχέτιση να βασίζεται σε μηδενικό μέσο
x = x(:) - mean(x(:));

% ACF: δείχνει γραμμικές εξαρτήσεις σε διαφορετικές υστερήσεις
figure('Name', ['ACF ' titleTag]);
autocorr(x, 'NumLags', maxLag);
title(['ACF - ' titleTag]);

% PACF: χρήσιμη για προτάσεις τάξης AR(p) (κόβεται περίπου μετά το p)
figure('Name', ['PACF ' titleTag]);
parcorr(x, 'NumLags', maxLag);
title(['PACF - ' titleTag]);

end

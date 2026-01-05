function make_plots(T, C, savePrefix)
% Variables:
% -T: table με τα μαζικά αποτελέσματα (μία γραμμή ανά epoch και συνθήκη)
%     columns: intensity, cond ("pre"/"post"), episode, NRMSE1, MI1
% -C: struct ρυθμίσεων (δεν χρησιμοποιείται άμεσα εδώ, αλλά κρατιέται για ομοιομορφία pipeline)
% -savePrefix: label για naming/αναφορά (δεν χρησιμοποιείται άμεσα εδώ)
% -measures: λίστα από τα δύο scalar μέτρα που θα απεικονίσουμε
% -intensities: τα επίπεδα έντασης που συγκρίνουμε
% -m: δείκτης μέτρου (NRMSE1 ή MI1)
% -i: δείκτης έντασης (120/180/240)
% -idx: λογική μάσκα επιλογής γραμμών στον πίνακα T
% -deltas: διάνυσμα διαφορών (post-pre) ανά epoch για ένα μέτρο
% -deltaInt: αντίστοιχο διάνυσμα έντασης για κάθε delta, ώστε να γίνει ομαδοποίηση στο boxplot
% -I: τρέχουσα ένταση μέσα στο loop
% -epsHere: διαθέσιμοι δείκτες επεισοδίων (epoch ids) για τη συγκεκριμένη ένταση
% -ep: τρέχον episode id
% -idxPre/idxPost: μάσκες που βρίσκουν τη γραμμή pre και τη γραμμή post του ίδιου episode
% -d: delta τιμή μέτρου = (post) - (pre)

measures = {'NRMSE1','MI1'};
intensities = [120 180 240];

% (1) Σύγκριση pre vs post, ξεχωριστά για κάθε ένταση
% Εδώ απαντάμε στο ερώτημα: "αλλάζει το μέτρο μετά το TMS για σταθερή ένταση;"
for m = 1:numel(measures)
    figure('Name', ['pre vs post | ' measures{m}]);
    tiledlayout(1,3);

    for i = 1:3
        nexttile;

        % Κρατάμε μόνο τις γραμμές της συγκεκριμένης έντασης και κάνουμε ομαδοποίηση κατά cond
        idx = T.intensity == intensities(i);
        boxplot(T{idx, measures{m}}, T.cond(idx));

        title(sprintf('%s | %d', measures{m}, intensities(i)));
        grid on;
    end
end

% (2) Σύγκριση μεταξύ εντάσεων στο post
% Ερώτημα: "μετά το TMS, διαφέρει το μέτρο ανάλογα με την ένταση;"
for m = 1:numel(measures)
    figure('Name', ['post intensities | ' measures{m}]);

    idx = T.cond == "post";
    boxplot(T{idx, measures{m}}, T.intensity(idx));

    title(['POST | ' measures{m}]);
    xlabel('Intensity');
    grid on;
end

% (3) Σύγκριση μεταξύ εντάσεων στο pre
% Ερώτημα: "πριν το TMS, υπάρχουν διαφορές ανά ένταση (baseline differences);"
for m = 1:numel(measures)
    figure('Name', ['pre intensities | ' measures{m}]);

    idx = T.cond == "pre";
    boxplot(T{idx, measures{m}}, T.intensity(idx));

    title(['PRE | ' measures{m}]);
    xlabel('Intensity');
    grid on;
end

% (4) Baseline correction: Δ = post - pre για το ίδιο episode, και σύγκριση μεταξύ εντάσεων
% Ερώτημα: "η μεταβολή λόγω TMS (εντός-επεισοδίου) διαφέρει ανά ένταση;"
for m = 1:numel(measures)
    deltas = [];
    deltaInt = [];

    for I = intensities
        % Παίρνουμε τα episode IDs που υπάρχουν για αυτή την ένταση
        epsHere = unique(T.episode(T.intensity==I));

        for ep = epsHere.'
            % Εντοπίζουμε το ζεύγος (pre, post) του ίδιου episode
            idxPre  = (T.intensity==I) & (T.cond=="pre")  & (T.episode==ep);
            idxPost = (T.intensity==I) & (T.cond=="post") & (T.episode==ep);

            % Υπολογισμός Δ = post - pre, μόνο αν υπάρχουν και τα δύο
            if any(idxPre) && any(idxPost)
                d = T{idxPost, measures{m}} - T{idxPre, measures{m}};

                % Κρατάμε τη delta τιμή μαζί με την ένταση της για ομαδοποίηση στο plot
                deltas = [deltas; d]; %#ok<AGROW>
                deltaInt = [deltaInt; I]; %#ok<AGROW>
            end
        end
    end

    figure('Name', ['Delta post-pre | ' measures{m}]);
    boxplot(deltas, deltaInt);

    title(['Delta (post-pre) | ' measures{m}]);
    xlabel('Intensity');
    grid on;
end

end

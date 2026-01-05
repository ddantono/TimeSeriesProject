function el = aem_to_electrode(aem)
% Variables:
% -aem: αριθμός μητρώου φοιτητή (ΑΕΜ)
% -x: τα δύο τελευταία ψηφία του ΑΕΜ
% -el: δείκτης καναλιού EEG στο διάστημα [1, 60]

validateattributes(aem, {'numeric'}, {'scalar','integer','positive'});

% Εξαγωγή των δύο τελευταίων ψηφίων του ΑΕΜ
x = mod(aem, 100);

% Αντιστοίχιση ΑΕΜ σε κανάλι EEG με βάση τον κανόνα:
% el = mod(x, 60) + 1
% Η πράξη mod εξασφαλίζει σωστή αντιστοίχιση στα 60 κανάλια
el = mod(x, 60) + 1;

end

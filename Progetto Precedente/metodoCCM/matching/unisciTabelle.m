tabella1 = load('tabelle/tabellaSupportoUnita.mat').TUF;
tabella2 = load('tabelle/tab_listaTemplateFinale.mat').T;
tabella3 = load("H:\Drive condivisi\Progetto SRD\metodoCCM\LABORATORIO\matching\tabelle\tab_listaTemplateFinaleLABORATORIO_9.mat").T;

%Concatenazione
TU = [tabella1;tabella2;tabella3];

%Verifica righe duplicate
[TUF, ia, ic] = unique(TU, 'rows', 'stable');
duplicateCount = height(TU) - numel(ia); 
disp(['Numero di righe duplicate: ', num2str(duplicateCount)]);

%Verifica score NaN
hasNaN_Score = find(isnan(TUF.Score));
nanCount = sum(isnan(TUF.Score)); 
TUF(hasNaN_Score, :) = [];
disp(['Numero di righe con Score NaN: ', num2str(nanCount)]);

%Salvataggio tabella finale di supporto
save('tabelle/tabellaSupportoUnita.mat', 'TUF');



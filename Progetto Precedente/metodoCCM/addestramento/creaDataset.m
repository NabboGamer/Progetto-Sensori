%% MANUELE CAPECE - CHIARA CAPORALE - GIANFRANCO MANFREDA
%==========================================================================
% SCRIPT UNIONE DATASET (CSV) - CREAZIONE DATASET CONCATENATO
%
% Questo script recupera tutti i dataset (file .csv) presenti nella cartella
% ./dataset/ e li concatena verticalmente in un unico file:
%   ./dataset/datasetUnito.csv
%
% Scopo:
%   - Ottenere un dataset globale (multi-utente / multi-acquisizione) da usare
%     per addestrare il classificatore (es. Random Forest / Bagging).
%
% Pipeline:
%   1) Verifica esistenza cartella dataset
%   2) Elenca tutti i CSV presenti
%   3) Legge ogni CSV come tabella e lo concatena a combinedData
%   4) (Opzionale) Rimuove colonne non utili al modello (commentato)
%   5) Salva il dataset unito in datasetUnito.csv
%
% NOTE:
%   - I CSV devono avere intestazioni compatibili tra loro (stesse colonne e tipi),
%     altrimenti la concatenazione potrebbe fallire o produrre colonne mancanti.
%   - Gli errori di lettura di singoli file non interrompono lo script: viene
%     emesso un warning e si prosegue.
%==========================================================================


%% --- 1) Definizione percorsi ---
% Cartella contenente tutti i CSV per acquisizione
pathListaDataset = [cd,'/dataset/'];

% File di output (dataset concatenato)
pathDatasetUnito = [cd,'/datasetUnito.csv'];

%% --- 2) Controllo esistenza cartella ---
if ~isfolder(pathListaDataset)
    error('Il percorso specificato non esiste: %s', pathListaDataset);
end

%% --- 3) Ricerca dei file CSV ---
% Elenca tutti i file .csv nella cartella dataset
csvFiles = dir(fullfile(pathListaDataset, '*.csv'));

% Tabella accumulatore (inizialmente vuota)
combinedData = table();

%% --- 4) Lettura e concatenazione dei CSV ---
n = length(csvFiles);
for i = 1:n
    % Percorso completo del file corrente
    filePath = fullfile(pathListaDataset, csvFiles(i).name);

    % Lettura robusta: se un file è corrotto/incompatibile, lo salto con warning
    try
        data = readtable(filePath);

        % Concatenazione verticale: aggiunge le righe del file corrente
        combinedData = [combinedData; data];
    catch ME
        warning('Non è stato possibile leggere il file %s: %s', filePath, ME.message);
    end

    % Stampa avanzamento
    fprintf('Completamento : %.2f%%\n',((i/n)*100));
end

%% --- 5) Salvataggio del dataset unito ---
writetable(combinedData, pathDatasetUnito);
fprintf('Tutti i file CSV sono stati uniti in: %s\n', pathDatasetUnito);

%% --- 6) (Opzionale) Rimozione colonne non utili al modello ---
% Se si vuole addestrare un modello con un subset di feature, si possono eliminare colonne qui.
% NOTA: i nomi delle colonne dipendono da come regionprops3 esporta i campi nel CSV.
%
% combinedData.Volume = [];
% combinedData.EquivDiameter = [];
% combinedData.SurfaceArea = [];
% combinedData.PrincipalAxisLength_1 = [];
% combinedData.PrincipalAxisLength_2 = [];
% combinedData.PrincipalAxisLength_3 = [];
% combinedData.Centroid_1 = [];
% combinedData.Centroid_2 = [];
% combinedData.Centroid_3 = [];
% combinedData.distCentroidPelle = [];
% 
% pathDatasetUnitoColonneFiltrate = [cd,'/datasetUnitoColonneFilt.csv'];
% writetable(combinedData, pathDatasetUnitoColonneFiltrate);
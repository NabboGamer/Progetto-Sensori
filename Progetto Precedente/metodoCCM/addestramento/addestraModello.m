%% MANUELE CAPECE - CHIARA CAPORALE - GIANFRANCO MANFREDA
%==========================================================================
% SCRIPT ADDESTRAMENTO MODELLO RANDOM FOREST (BAGGING)
%
% Questo script addestra un classificatore binario basato su un ensemble di
% alberi decisionali con tecnica di bagging.
%
% Pipeline:
%   1) Carica il dataset (CSV) contenente feature + label finale (ultima colonna)
%   2) Mescola le righe (shuffle)
%   3) Suddivide in train/test (80% / 20%)
%   4) Addestra un modello fitcensemble con tuning automatico degli iperparametri
%   5) Valuta il modello sul test set (matrice di confusione + accuratezza)
%   6) Salva il modello in "modelloRF.mat" nella cartella corrente
%
% OUTPUT:
%   - modelloRF.mat (variabile salvata: "model")
%
% NOTE:
%   - Si assume che l'ultima colonna del CSV sia la label (0/1 o classi equivalenti).
%   - Tutte le colonne precedenti sono usate come feature numeriche.
%==========================================================================

% clear all;

%% --- 1) Caricamento del dataset ---
% Percorso del dataset unito e già filtrato per colonne utili
pathDatasetUnito = [cd,'/datasetUnitoColonneFilt.csv'];

% Lettura tabella: righe = campioni, colonne = feature + label finale
data = readtable(pathDatasetUnito);

%% --- 2) Shuffle delle righe ---
% Mescola l'ordine dei campioni per evitare bias dovuti a ordinamenti nel file
rowOrder = randperm(height(data));
data_shuffled = data(rowOrder, :);

%% --- 3) Split train/test (80/20) ---
dimRighe = size(data_shuffled,1);
dimRigheTest  = round(dimRighe*20/100);   % ~20% per test
dimRigheTrain = dimRighe - dimRigheTest; % restante per train

% Estrazione di feature (tutte le colonne tranne l'ultima) e label (ultima colonna)
% Train set
X_train = data_shuffled{1:dimRigheTrain, 1:end-1};
y_train = data_shuffled{1:dimRigheTrain, end};

% Test set
X_test  = data_shuffled{dimRigheTrain+1:end, 1:end-1};
y_test  = data_shuffled{dimRigheTrain+1:end, end};

%% --- 4) Addestramento modello (Ensemble Bagging) ---
% fitcensemble con Method='Bag' costruisce un ensemble di alberi su bootstrap
% delle righe del training set.
% OptimizeHyperparameters='auto' avvia un tuning automatico degli iperparametri
% con funzione di acquisizione "expected-improvement-plus".
model = fitcensemble(X_train, y_train, ...
                     'Method', 'Bag', ...
                     'OptimizeHyperparameters', 'auto', ...
                     'HyperparameterOptimizationOptions', struct( ...
                         'AcquisitionFunctionName', 'expected-improvement-plus'));

%% --- 5) Valutazione del modello sul test set ---
% Predizione delle etichette sul set di test
y_pred = predict(model, X_test);

% Matrice di confusione: righe = classe reale, colonne = classe predetta
confMat = confusionmat(y_test, y_pred);
disp('Matrice di Confusione:');
disp(confMat);

% Accuratezza complessiva
accuracy = sum(y_pred == y_test) / length(y_test);
fprintf('Accuratezza: %.2f%%\n', accuracy * 100);

%% --- 6) Salvataggio del modello ---
% Salva il modello addestrato per riutilizzo nelle fasi di filtraggio/classificazione
save('modelloRF.mat', 'model');

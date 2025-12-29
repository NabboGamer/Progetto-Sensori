%% MANUELE CAPECE - CHIARA CAPORALE - GIANFRANCO MANFREDA
%==========================================================================
% SCRIPT CREAZIONE DATASET (UTENTE) - ETICHETTATURA MULTI-ACQUISIZIONE
%
% Questo script automatizza la creazione del dataset per un singolo utente,
% iterando su tutti i file presenti nella cartella delle acquisizioni e
% lanciando la procedura di etichettatura delle componenti connesse solo per
% le acquisizioni selezionate in listaAcquisizioni.
%
% Flusso principale:
%   1) Imposta path alle utility necessarie e pulisce l'ambiente
%   2) Seleziona utente, tipo di acquisizione e la lista delle acquisizioni da etichettare
%   3) Scansiona la cartella dei .mat dell'utente
%   4) Per ogni file, estrae (utente, acquisizione) dal nome
%   5) Se l'acquisizione è nella lista, esegue lo script/func "etichettaCC"
%
% OUTPUT:
%   - Aggiornamento/creazione dei file CSV di dataset per ciascuna acquisizione
%     (dipende da etichettaCC e dalla pipeline associata).
%
% NOTE:
%   - Si assume un naming dei file del tipo: "<utente>_0<acquisizione>.mat" (o simile),
%     dove l'acquisizione viene estratta prendendo il testo dopo "_0" e prima di ".mat".
%   - La variabile "classificazioneTotale" viene impostata a 1 per indicare che lo script
%     è eseguito in modalità batch (usata internamente da etichettaCC per non reinizializzare).
%==========================================================================


%% --- Setup ambiente ---
% Aggiungo al path le utility dell'estrazione template (usate dalla pipeline)
addpath([cd,'/../estrazioneTemplate/utility']);

% Pulizia figure e workspace
close all;
close(findall(0, 'Type', 'figure', 'Name', '3D Volume Viewer'));
clear all;
clc;

%% --- Parametri utente / acquisizioni da processare ---
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
utente = 'Molinaro';                    % Utente di interesse
listaAcquisizioni = {'01','09','14'};   % Acquisizioni da etichettare (whitelist)
pathMatfiles = [cd,'/..','/Matfiles/']; % Base path dei .mat
tipo = 's';                             % Tipo acquisizione
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Cartella che contiene i file .mat dell'utente
pathCartella = [pathMatfiles,utente,'-',tipo,'/'];

% Flag/modalità batch: segnala a etichettaCC che si sta facendo un ciclo completo
classificazioneTotale = 1;

%% --- Scansione file della cartella utente ---
files = dir(pathCartella);

% Tengo solo i file (escludo le directory) e ne ricavo i nomi
fileNames = {files(~[files.isdir]).name};

disp('Etichettatura completa utente iniziata');

%% --- Loop sulle acquisizioni ---
for i = 1:length(fileNames)
    currentFileName = fileNames{i};

    % Individuo la posizione dell'underscore nel nome file per estrarre utente/acquisizione
    underscorePos = strfind(currentFileName, '_');

    % Estrazione utente: tutto ciò che precede il primo underscore
    utente = currentFileName(1:underscorePos(1)-1);

    % Estrazione acquisizione:
    % - assume formato "_0XX.mat" e quindi prende da underscore+2 fino a prima di ".mat"
    acquisizione = currentFileName(underscorePos(1)+2:end-4);

    % Esegue l'etichettatura solo per le acquisizioni in lista (whitelist)
    if ismember(acquisizione, listaAcquisizioni)
        etichettaCC; % Script/funzione che avvia la pipeline di etichettatura CC
    end
end

%% MANUELE CAPECE - CHIARA CAPORALE - GIANFRANCO MANFREDA
%==========================================================================
% SCRIPT ETICHETTATURA ACQUISIZIONE
%
% Questo script esegue l'intera pipeline per:
%   1) caricare una specifica acquisizione (.mat),
%   2) estrarre e preprocessare il volume del palmo (segmentazione vene),
%   3) ottenere un volume "pulito" su cui fare la classificazione,
%   4) iterare sulle componenti connesse per etichettarle e salvare i risultati
%      su una tabella CSV del dataset.
%
% OUTPUT PRINCIPALE:
%   - <utente>_0<acquisizione>.csv in ./dataset/
%     (tabella di etichette/attributi delle CC, aggiornata da iteraCC)
%
% NOTE:
%   - Se la variabile "classificazioneTotale" non esiste nel workspace,
%     lo script si autoinizializza con valori di default.
%==========================================================================


%% 1) Lettura del file .mat e setting dei path
% Se non sto riprendendo una sessione già avviata (classificazioneTotale assente),
% preparo l'ambiente: path utility, chiusura figure, reset workspace e parametri base.
if ~exist('classificazioneTotale', 'var')
    addpath([cd,'/utility']);

    % Pulizia ambiente grafico e workspace
    close all;
    clear all;
    close(findall(0, 'Type', 'figure', 'Name', '3D Volume Viewer'));
    close(findall(0, 'Type', 'figure', 'Name', 'Volume originale'));
    close(findall(0, 'Type', 'figure', 'Name', 'Volume da classificare'));
    clc;

    % Parametri di default (utente/acquisizione/tipo)
    utente = 'Brienza';
    acquisizione = '00';
    pathMatfiles = [cd,'/..','/Matfiles/'];
    tipo = 's';
end

% Path di output della tabella CSV associata a questa acquisizione
pathTabella = [cd,'/dataset/',utente,'_0',acquisizione,'.csv'];

% Path utili per cambio directory e ritorno
pathScriptEstrazione = [cd,'/..','/estrazioneTemplate'];
pathBase = cd;

% Definizione dei path specifici per caricare l'acquisizione e salvare immagini 3D
[pathMatrice,pathSaveImg3D] = definisciPath(pathMatfiles,utente,tipo,acquisizione);

% Carica i dati dell'acquisizione (attesi in variabili tipo M, X, Y, Z, ecc.)
caricaAcquisizione;

% Messaggio a video per identificare la sessione
printTestoCornice(strcat("Etichettatura acquisizione ",utente,acquisizione),'+');


%% 2) Estrapolazione del volume da classificare
% Esegue la pipeline di estrazione/segmentazione e pre-processing del volume venoso.
cd(pathScriptEstrazione);

% Avvia il pool parallelo se necessario
avviaPoolParallelo;

% Cropping della matrice di acquisizione e dei relativi assi (riduce ROI / area utile)
[Mc,Xc,Yc,Yi] = cropMatrice(M,X,Y);

% Estrazione del palmo e delle maschere di supporto:
% - volumePalmo: volume del palmo
% - Mnp: matrice "normalizzata/preparata" su cui lavorare
% - maschere: acqua/nero ecc. per rimuovere artefatti
% - indiciPalmoNoPelle: ROI del palmo senza la regione di pelle
[volumePalmo,Mnp,mascheraAcqua,mascheraNeroPalmo,mascheraNeroTotale,indiciPalmoNoPelle] = ...
    estrapolaVolumeVene(Mc,Z,utente,acquisizione,200,0);

% Binarizzazione per estrarre strutture venose e calcolo del vettore feature "vecFine"
[volumeBin,vecFine] = effettuaBinarizzazione(Mnp,volumePalmo, mascheraAcqua, mascheraNeroTotale, ...
    indiciPalmoNoPelle, utente, acquisizione, size(Yc,1),0);

% Isolamento del pattern venoso (rimozione di strutture non coerenti con le vene)
[volIsolato] = isolaPatternVenoso(volumeBin,utente,acquisizione,0);

% Inspessimento/morfologia per rendere le strutture più robuste e connesse
% (sogliaGauss è un parametro/risultato utile per tracciare la binarizzazione)
[volSpesso,sogliaGauss] = inspessimento(volIsolato,utente,acquisizione,-1,0);

% Ritorno alla directory di base
cd(pathBase);


%% 3) Classificazione componenti connesse
% Pre-filtraggio: rimuove CC troppo piccole (rumore) prima dell'etichettatura manuale/assistita.
% NOTA: qui filtraCC viene usata in forma "semplice" per non considerare CC < 5000 voxel.
[volumeFiltrato] = filtraCC(volSpesso,5000); % Non etichetto le CC con volume < 5000

% Visualizzazione del volume originale e del volume filtrato pronto per la classificazione
graficoVolshow(Mnp,'Volume originale',utente,acquisizione,1);
graficoVolshow(volumeFiltrato,'Volume da classificare',utente,acquisizione,1);

% Iterazione sulle CC del volume filtrato:
% - usa contesto (indiciPalmoNoPelle) e feature (vecFine)
% - aggiorna/crea la tabella CSV in pathTabella
tabellaCC = iteraCC(volumeFiltrato,indiciPalmoNoPelle,vecFine,pathTabella);

% Chiusura delle finestre di visualizzazione usate nella fase di classificazione
close(findall(0, 'Type', 'figure', 'Name', 'Volume da classificare'));
close(findall(0, 'Type', 'figure', 'Name', 'Volume originale'));

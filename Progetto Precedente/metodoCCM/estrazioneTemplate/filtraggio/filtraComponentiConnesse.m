function [volFilt] = filtraComponentiConnesse(volume,minSize,indiciPalmoNoPelle,vecFine,utente,acquisizione,show)
%FILTRACOMPONENTICONNESSE Filtra e ricostruisce le componenti connesse (CC) del volume venoso.
%
%   Questa funzione esegue un filtraggio a più stadi delle componenti connesse
%   presenti in un volume binario/segmentato (vene + rumore). L'obiettivo è:
%     1) separare CC grandi e piccole,
%     2) classificare (vene vs rumore) tramite un modello Random Forest,
%     3) connettere porzioni venose interrotte,
%     4) rifinire eliminando rumore residuo e mantenendo strutture coerenti.
%   Se un risultato già calcolato è disponibile su disco, viene caricato e
%   restituito senza ricalcolo.
%
%   INPUT
%     volume             Volume (tipicamente binario o maschera) contenente le strutture estratte.
%     minSize            Soglia (in voxel) per separare CC piccole e CC grandi nel primo split.
%     indiciPalmoNoPelle Indici/maschera dei voxel appartenenti al palmo (escludendo la pelle),
%                        usati come informazione contestuale nel filtraggio/classificazione.
%     vecFine            Vettore/feature (tipicamente derivato da profilo o statistiche),
%                        usato dal classificatore per distinguere vene da rumore.
%     utente             Identificativo utente (string/char) per gestione cartelle e naming.
%     acquisizione       Identificativo acquisizione (string/char) per gestione cartelle e naming.
%     show               Flag di visualizzazione (0 = no plot, 1 = mostra volumi intermedi).
%
%   OUTPUT
%     volFilt            Volume finale filtrato (uint8), con vene a 255 e sfondo a 0.
%
%   NOTE OPERATIVE
%   - I risultati intermedi/finali vengono salvati in:
%       ./stepIntermedi/<utente>/<acquisizione>/volFilt.mat
%   - Il modello di classificazione viene caricato da "modelloRF.mat" e si
%     assume contenga la variabile "model".
%   - Le CC "minuscole" (palline) vengono preservate e riunite al volume finale.

    %% --- Intestazione e caching su disco ---
    printTestoCornice("Filtraggio delle componenti connesse",'*');

    folderPath = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione);
    filename   = strcat(folderPath,'/volFilt','.mat');

    % Se il volume filtrato esiste già, lo carico e termino
    if exist(filename, 'file') == 2
        disp('Volume filtrato presente nella cartella, caricamento...');
        load(filename,'volFilt');
        graficoVolshow(volFilt,'Volume filtrato finale',utente,acquisizione,show);
        return;
    end

    %% --- Caricamento modello di classificazione ---
    % Carica il modello Random Forest (atteso come variabile "model")
    load("modelloRF.mat");

    %% --- 1) Separazione iniziale CC piccole vs CC grandi ---
    % Divido le componenti connesse del volume in base a minSize
    [volumeCCPiccole,volumeCCGrandi] = dividiCCvolume(volume,minSize);

    %% --- 2) Filtraggio delle CC grandi tramite classificatore ---
    % Classifico le CC grandi (vene vs rumore) usando feature/contesto
    [volumeFCCR,~] = filtraCC(volumeCCGrandi,indiciPalmoNoPelle,vecFine,model,3);

    % Riaggiungo le CC piccole (per non perdere eventuali dettagli utili)
    volumeFCCR = volumeFCCR | volumeCCPiccole;

    graficoVolshow(volumeFCCR,'Volume post filtraggio cc GRANDI',utente,acquisizione,show);

    %% --- 3) Connessione delle vene (ricostruzione continuità) ---
    % Unisce tratti venosi interrotti usando informazioni geometriche/euristiche
    volumeConnesso = connettiVene(volumeFCCR,utente,acquisizione,show);

    %% --- 4) Isolamento CC "minuscole" (palline) e stima soglia adattiva ---
    % Estrae CC molto piccole (<=1000) separandole dal resto del volume connesso
    [volumeCCPalline,volumeCCGrandi] = dividiCCvolume(volumeConnesso,1000);

    % Calcolo statistiche volumetriche delle CC rimanenti per stimare una soglia
    t = getTabellaCCVolume(volumeCCGrandi);

    % Soglia adattiva basata su media e deviazione standard dei volumi CC
    soglia = round(std(t.Volume) - mean(t.Volume));
    if soglia <= 0
        soglia = round(std(t.Volume));
    end
    fprintf('Soglia cc piccole calcolata: %d\n',soglia);

    % Nuova divisione: CC piccole (rumore/dettagli) vs CC grandi (strutture più coerenti)
    [volumeCCPiccole,volumeCCGrandi] = dividiCCvolume(volumeCCGrandi,soglia);

    %% --- 5) Filtraggio delle CC piccole (post-connessione) ---
    % Classifico le CC piccole con parametri diversi (ultimo argomento = 0)
    [volumeFCCPiccole,~] = filtraCC(volumeCCPiccole,indiciPalmoNoPelle,vecFine,model,0);

    % Ricompongo volume: CC grandi preservate + CC piccole "buone"
    volumeFCCFinal = volumeFCCPiccole | volumeCCGrandi;

    graficoVolshow(volumeFCCFinal,'Volume post filtraggio cc PICCOLE',utente,acquisizione,0);

    %% --- 6) Pulizia finale: rimozione CC sotto soglia fissa e conversione ---
    % Mantengo solo le componenti sopra 5000 voxel (filtraggio finale di coerenza)
    [~,volFilt] = dividiCCvolume(volumeFCCFinal,5000);

    % Converto a uint8 e imposto i voxel attivi a 255 per visualizzazione/salvataggio
    volFilt = uint8(volFilt);
    volFilt(volFilt == 1) = 255;

    %% --- 7) Riunione delle CC "palline" al volume finale ---
    % Preserva anche le componenti minuscole isolate in precedenza
    volFilt = volFilt | volumeCCPalline;

    graficoVolshow(volFilt,'volFilt - Volume dopo filtraggio finale',"","",show);

    %% --- 8) Salvataggio su disco (solo se non vuoto) ---
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end

    if nnz(volFilt) > 0
        save(filename,'volFilt');
        disp('Volume filtrato salvato con successo');
    else
        disp('Volume filtrato vuoto NON salvato');
    end
end

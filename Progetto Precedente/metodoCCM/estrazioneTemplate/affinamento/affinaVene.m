function [volumeFilled] = affinaVene(volume,indiciPalmoNoPelle,vecFine,utente,acquisizione,show)
%AFFINAVENE Affina il volume venoso: rimozione disturbi residui, recupero pezzi e filling delle vene.
%
%   Questa funzione applica una serie di operazioni "avanzate" per:
%     - separare ulteriormente rumore residuo dalle vene,
%     - migliorare la continuità/resa grafica del template,
%     - recuperare porzioni eliminate durante i filtraggi,
%     - effettuare un "filling" selettivo delle regioni sottili lungo lo skeleton.
%
%   Il risultato viene cachato su disco per evitare ricalcoli:
%     ./stepIntermedi/<utente>/<acquisizione>/volAff.mat
%
%   INPUT
%     volume             Volume binario/segmentato di partenza (vene + rumore).
%     indiciPalmoNoPelle Matrice 2D (Y,X) con quota del palmo senza pelle (feature contestuale).
%     vecFine            Vettore su Y utilizzato come feature (coerente con il modello RF).
%     utente             Identificativo utente (per path e titoli).
%     acquisizione       Identificativo acquisizione (per path e titoli).
%     show               Flag di visualizzazione (0/1).
%
%   OUTPUT
%     volumeFilled       Volume finale affinato (logico) contenente vene "ripulite" e riempite.
%
%   PIPELINE (alto livello)
%     0) Caching e caricamento modello
%     1) Split CC piccole/grandi (soglia 1000)
%     2) Per ciascuna CC grande:
%          - affinaDisturbi: separa rumore/pallini dalla CC
%          - split ulteriormente in "pezzi" e "vene" (soglia 5000)
%          - filtraCC (modello) sulle vene e liscia con filtro gaussiano
%          - accumula: vene buone + pezzi/eliminate (da recuperare dopo)
%     3) eliminaRumore sul volume aggregato
%     4) recuperaPezzi: tenta di reinserire porzioni coerenti
%     5) smoothing/closing + eliminaCCcorte + filtraCC finale
%     6) Filling vene: per ogni CC
%          - calcola spessore locale (calcolaFeaturesFilling)
%          - skeletonize (bwskel) e dilata selettivamente le porzioni sottili
%     7) Salvataggio su disco se non vuoto
%
%   NOTE
%   - Nel codice sono presenti commenti "POSSIBILE PERDITA": indicano punti in cui
%     soglie/filtri potrebbero eliminare vene reali se i parametri non sono robusti.


    % Ulteriore operazione per separare il rumore rimasto dalle vene.
    % Migliora la resa grafica del template.
    printTestoCornice("Affinamento delle componenti connesse",'*');

    %% --- 0) Caching (caricamento se già calcolato) ---
    folderPath = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione);
    filename = strcat(folderPath,'/volAff','.mat');

    if exist(filename, 'file') == 2
        disp('Volume affinato presente nella cartella, caricamento...');
        load(filename,'volumeFilled');
        graficoVolshow(volumeFilled,'Volume affinato finale',utente,acquisizione,show);
        return;
    end

    %% --- 0b) Caricamento modello di classificazione ---
    load("modelloRF.mat");

    %% --- 1) Split iniziale: CC piccole vs grandi ---
    % Le CC piccole vengono mantenute a parte e reinserite più avanti.
    [volumeCCPiccole,volumeCCGrandi] = dividiCCvolume(volume,1000);

    % Analizzo solo le CC grandi in questa fase
    CC = bwconncomp(volumeCCGrandi);
    volumeAffinato = false(size(volumeCCGrandi)); % accumula vene "affinate"
    volumePezzi    = false(size(volumeCCGrandi)); % accumula pezzi/rumore/punti da recuperare

    disp(newline);
    disp('***Affinamento disturbi iniziato***');

    pixelIdxList  = CC.PixelIdxList;
    numComponents = CC.NumObjects;

    %% --- 2) Loop sulle componenti grandi: rimozione disturbi e filtraggio ---
    for i = 1:numComponents

        % Ricostruisce la i-esima CC come volume logico
        componente = false(size(volumeAffinato));
        componente(pixelIdxList{i}) = true;

        % Separazione disturbi: ritorna volume affinato e "pallini" separati
        [volAffinato,volPallini] = affinaDisturbi(componente);

        % Divide ulteriormente: volPezzi = parti sotto soglia; volVene = parti sopra soglia
        [volPezzi,volVene] = dividiCCvolume(volAffinato,5000);

        %% --- 2a) FILTRO basato sul modello (RF) ---
        % Classifica le CC di volVene: mantiene solo quelle predette come vene
        [volVeneFilt,~] = filtraCC(volVene,indiciPalmoNoPelle,vecFine,model,0); % POSSIBILE PERDITA

        % Smoothing/riconnessione (custom) per migliorare continuità
        [volAffinatoint] = filtGaussVol(volVeneFilt,1,100);

        % Vene finali per questa componente
        volAffinatoFinal = volAffinatoint;

        % Porzioni eliminate dal modello (candidate al recupero)
        volVeneEliminate = volVene & ~volVeneFilt;

        % Accumulo "pezzi" da gestire dopo (pezzi piccoli + eliminati)
        volumePezzi = volumePezzi | volPezzi | volVeneEliminate;

        %% --- 2b) (Alternativa commentata) FILTRO basato sulla dimensione ---
        % Qui era prevista una logica alternativa con soglia su volumi (commentata nel codice originale)

        % I pallini estratti da affinaDisturbi vengono reinseriti tra le CC piccole
        volumeCCPiccole = volumeCCPiccole | volPallini;

        % Chiusura morfologica per colmare piccoli buchi e aumentare continuità
        volAffinatoFinal = imclose(volAffinatoFinal,strel('sphere',5));

        % Accumulo nel volume globale delle vene affinate
        volumeAffinato = volumeAffinato | volAffinatoFinal;
    end

    %% --- 3) Eliminazione rumore residuo sul volume aggregato ---
    disp(newline);
    disp('***Elimina rumore iniziato***');

    [volumeFilt] = eliminaRumore(volumeAffinato,indiciPalmoNoPelle,5000,utente,acquisizione,show); % POSSIBILE PERDITA

    %% --- 4) Recupero pezzi eliminati (per evitare perdita di vene) ---
    disp('***Recupera pezzi iniziato***');

    % Split dei "pezzi" in piccole/grandi per gestire separatamente
    [volumeCCPiccole,volumePezzi] = dividiCCvolume(volumePezzi,1000);

    % Recupero guidato: prova a reinserire porzioni coerenti con le vene
    [volumeRecuperato] = recuperaPezzi(volumeFilt, volumePezzi, volumeCCPiccole, ...
        indiciPalmoNoPelle, vecFine, model, utente, acquisizione, show); % POSSIBILE PERDITA

    % Ricompongo: vene filtrate + CC piccole + recupero
    volumeAffinato = volumeFilt | volumeCCPiccole | volumeRecuperato;

    graficoVolshow(volumeAffinato,'volumeAffinato - Volume affinato dai disturbi',"","",show);

    %% --- 5) Post-processing globale (smoothing + closing + rimozione CC "corte") ---
    volumeAffinato = filtGaussVol(volumeAffinato,1,30);
    volumeAffinato = imclose(volumeAffinato, strel('sphere', 5));

    % Rimozione di CC troppo corte (euristica) - POSSIBILE PERDITA
    [volumeAffinato] = eliminaCCcorte(volumeAffinato);

    % Filtraggio finale con modello (ulteriore pulizia) - POSSIBILE PERDITA
    [volumeAffFilt,~] = filtraCC(volumeAffinato,indiciPalmoNoPelle,vecFine,model,0);
    graficoVolshow(volumeAffFilt,'volumeAffFilt - Volume affinato filtrato',"","",show);

    %% --- 6) Filling vene: riempimento selettivo delle porzioni sottili ---
    disp('***Filling vene iniziato***');

    CC = bwconncomp(volumeAffFilt);
    volumeFilled = false(size(volumeAffFilt));

    pixelIdxList  = CC.PixelIdxList;
    numComponents = CC.NumObjects;

    % Parallelizzo perché il filling è indipendente per ciascuna componente
    parfor i = 1:numComponents
        % Ricostruisce la componente
        componente = false(size(volumeAffFilt));
        componente(pixelIdxList{i}) = true;

        % Affinamento finale della singola componente
        [volAffinato,~] = affinaDisturbi(componente);

        % Mantiene solo CC sopra soglia (pulizia ulteriore)
        [~,volAffinatoCleaned] = dividiCCvolume(volAffinato,5000);
        componente = volAffinatoCleaned;

        % Calcolo "spessori" locali (custom) usati per identificare tratti sottili
        [vecDiam] = calcolaFeaturesFilling(componente);

        % Soglia di spessore: media tra mediana e minimo (euristica)
        sogliaSpessore = mean([median(vecDiam), min(vecDiam)]);

        % Elemento strutturante: raggio ~ metà dello spessore medio
        se = strel('sphere', round(mean(vecDiam)/2));

        % Skeleton: ottengo l'asse centrale della vena
        skeleton = filtGaussVol(componente,10,1);
        skeleton = bwskel(skeleton,'MinBranchLength',30);

        % Distance transform: distanza interna dal bordo (spessore locale)
        distanceMap = bwdist(~componente);

        % Porzioni sottili: punti dello skeleton dove lo spessore è sotto soglia
        porzioniSottili = skeleton & (distanceMap <= sogliaSpessore);

        % Dilata selettivamente le porzioni sottili per "riempire" tratti troppo fini
        dilatedThinParts = imdilate(porzioniSottili, se);

        % Accumula nel volume finale
        volumeFilled = volumeFilled | componente | dilatedThinParts;
    end

    disp('***Filling vene terminato***');
    graficoVolshow(volumeFilled,'volumeFilled - Volume affinato finale',"","",show);

    %% --- 7) Salvataggio su disco (solo se non vuoto) ---
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end

    if nnz(volumeFilled) > 0
        save(filename,'volumeFilled');
        disp('Volume affinato salvato con successo');
    else
        disp('Volume affinato vuoto NON salvato');
    end
end

function [volumeSpesso,soglia] = inspessimentoRecuperoAdatt(volume,show)
%INSPESSIMENTORECUPEROADATT Inspessisce/riconnette strutture nel volume per facilitare il "recupero" delle vene.
%
%   Questa funzione è una variante "adattiva" pensata per la fase di recupero
%   (es. dentro recuperaVena). L'obiettivo è rendere una componente più separabile
%   e riclassificabile, combinando:
%     1) erosione leggera (per separare ulteriormente strutture adese),
%     2) filtraggio gaussiano 3D (per ammorbidire/riconnettere porzioni vicine),
%     3) scelta automatica di una soglia di binarizzazione in base all'andamento
%        del numero di CC "significative" (Volume >= 1000) al variare della soglia,
%     4) binarizzazione finale alla soglia stimata.
%
%   INPUT
%     volume  Volume binario/logico da inspessire/riconnettere (voxel != 0 = oggetto).
%     show    Flag di visualizzazione:
%              - 0: nessuna figura
%              - 1: mostra il volume binarizzato finale (graficoVolshow)
%
%   OUTPUT
%     volumeSpesso Volume binario risultante dopo filtro gaussiano + binarizzazione.
%     soglia       Soglia scelta automaticamente (in intensità 0..255 circa, coerente col volume uint8).
%
%   METODO (stima soglia)
%     - Si esplorano soglie in [start, stop] con passo step.
%     - Per ogni soglia:
%         a) binarizza(volumeGauss) alla soglia corrente
%         b) conta quante CC hanno Volume >= 1000
%     - Si calcola la derivata discreta dy = diff(vecNumCC).
%     - Si cercano picchi (findpeaks) su dy:
%         * se esistono almeno 2 picchi, si usa il secondo (heuristic: cambio di regime più robusto)
%         * altrimenti, se siamo all'ultima iterazione e c'è almeno 1 picco, si usa il primo

    %% --- 1) Erosione leggera per separare strutture adese ---
    % Riduce leggermente gli oggetti e può separare ponti sottili/artefatti
    erodedVolume = imerode(volume, strel('sphere', 1));
    % graficoVolshow(erodedVolume,'Volume eroso',utente,acquisizione,show);

    %% --- 2) Preparazione a filtro gaussiano: conversione in uint8 (0/255) ---
    erodedVolumeint = uint8(erodedVolume);
    erodedVolumeint(erodedVolumeint == 1) = 255;

    % Filtro gaussiano 3D (sigma=1) per ammorbidire e favorire riconnessioni
    volumeGauss = imgaussfilt3(erodedVolumeint,1);

    %% --- 3) Scansione soglie per binarizzazione adattiva ---
    start = 1;
    stop  = 150;
    step  = 3;

    vecSoglie = start:step:stop;
    numIteration = numel(vecSoglie);

    % Numero di CC "grandi" per ogni soglia
    vecNumCC = nan(1,numIteration);

    % Soglia finale (da stimare)
    soglia = NaN;

    for i = 1:numIteration
        % Binarizzazione alla soglia corrente
        volBin = binarizza(volumeGauss,'manuale',vecSoglie(i));

        % Conteggio CC significative (Volume >= 1000)
        CC = bwconncomp(volBin);
        tabCC = regionprops3(CC, 'Volume');
        numCCval = find([tabCC.Volume] >= 1000);
        vecNumCC(i) = numel(numCCval);

        % Derivata discreta del numero di CC (trend rispetto alla soglia)
        dy = diff(vecNumCC);

        % Cerco massimi locali (picchi) nella derivata
        [~,maxLocalIdx] = findpeaks(dy);

        % Se ho almeno due picchi, uso il secondo (heuristic più stabile)
        if ~isempty(maxLocalIdx) && size(maxLocalIdx,2) > 1
            secondMax = maxLocalIdx(2);
            soglia = (round(secondMax) * step);
            break;
        end

        % Se arrivo alla fine e non ho scelto soglia ma ho almeno un picco, uso il primo
        if i == numIteration && isnan(soglia) && ~isempty(maxLocalIdx)
            firstMax = maxLocalIdx(1);
            soglia = (round(firstMax) * step);
        end
    end

    %% --- 4) Binarizzazione finale e output ---
    fprintf('Soglia calcolata: %d\n',soglia);

    volumeGaussBin = binarizza(volumeGauss,'manuale',soglia);

    % Visualizzazione diagnostica (se richiesta)
    graficoVolshow(volumeGaussBin,'Volume binarizzato RECUPERO','','',show);

    % Output finale: volume "inspessito/riconnnesso" per fase di recupero
    volumeSpesso = volumeGaussBin;
end

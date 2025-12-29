function [closedvolumeGaussBin] = connettiVene(volume,utente,acquisizione,show)
%CONNETTIVENE Connette segmenti venosi discontinui tramite smoothing gaussiano e chiusura morfologica.
%
%   La funzione ha lo scopo di aumentare la continuità delle strutture venose
%   (spesso frammentate dalla binarizzazione) eseguendo:
%     1) conversione del volume binario in uint8 (0/255),
%     2) filtraggio gaussiano 3D (imgaussfilt3) per "espandere" e raccordare
%        strutture vicine,
%     3) ricerca automatica di una soglia di binarizzazione sul volume filtrato,
%        basata sul numero di componenti connesse "significative" (Volume >= 1000)
%        al variare della soglia,
%     4) binarizzazione finale con la soglia stimata,
%     5) chiusura morfologica 3D (imclose con sfera) per colmare piccoli gap e
%        connettere ulteriormente i tratti venosi.
%
%   INPUT
%     volume        Volume binario/logico (vene segmentate) da "connettere".
%     utente        Identificativo utente (per eventuali plot/label).
%     acquisizione  Identificativo acquisizione (per eventuali plot/label).
%     show          Flag di visualizzazione:
%                    - 0: nessun grafico
%                    - 1: mostra grafici di fitting della soglia + volshow finale
%
%   OUTPUT
%     closedvolumeGaussBin Volume binario finale "connesso" dopo smoothing + closing.
%
%   METODO (scelta soglia)
%     - Si esplorano soglie da startSoglia a stopSoglia con passo stepSoglia.
%     - Per ogni soglia si binarizza il volume filtrato e si conta quante CC hanno
%       Volume >= 1000.
%     - Il vettore del numero di CC viene smussato (LOESS).
%     - Si calcola la derivata discreta (diff) del vettore smussato.
%     - La soglia scelta è la prima soglia corrispondente a un minimo locale della derivata
%       (interpretabile come punto di "stabilizzazione"/cambio di regime del numero di CC).
%     - Se non ci sono minimi locali, si usa una soglia di fallback (50).

    %% --- 1) Preparazione volume e smoothing gaussiano ---
    % Converto in uint8 e porto i voxel attivi a 255 (standard per filtri su immagini)
    volume = uint8(volume);
    volume(volume == 1) = 255;

    % Filtro gaussiano 3D (sigma=1) per favorire connessioni tra strutture vicine
    volumeGauss = imgaussfilt3(volume,1);

    %% --- 2) Setup scansione soglie ---
    startSoglia = 1;
    stopSoglia  = 150;
    stepSoglia  = 2;

    vecSoglie = startSoglia:stepSoglia:stopSoglia;
    numIteration = numel(vecSoglie);

    % Vettore che conterrà, per ogni soglia, il numero di CC "grandi" (>=1000 voxel)
    vecNumCC = nan(1,numIteration);

    %% --- 3) Scansione soglie (parallela) e conteggio CC significative ---
    parfor i = 1:numIteration
        % NOTA: qui la soglia è costruita come i*stepSoglia (coerente con vecSoglie quasi sempre),
        % mantenendo l'impostazione originale del codice.
        soglia = i*stepSoglia;

        % Binarizzazione del volume gaussiano alla soglia corrente
        volBin = binarizza(volumeGauss,'manuale',soglia);

        % Calcolo componenti connesse e relativi volumi
        CC = bwconncomp(volBin);
        tabCC = regionprops3(CC, 'Volume');

        % Seleziono le CC con Volume >= 1000 e ne conto il numero
        numCCval = find([tabCC.Volume] >= 1000);
        vecNumCC(i) = numel(numCCval);
    end

    %% --- 4) Smussamento e scelta automatica della soglia ---
    % Smusso il vettore numero CC per ridurre rumore e oscillazioni
    vec_loess = smooth(vecNumCC, 30, 'loess');

    % Derivata discreta: evidenzia variazioni tra soglie successive
    dy = diff(vec_loess);

    % Identifico minimi locali della derivata (punti di "calo" dopo un aumento, o stabilizzazione)
    minLocalIdx = islocalmin(dy);

    if ~isempty(minLocalIdx)
        % Prendo il primo minimo locale (prima soglia "buona")
        firstMin = find(minLocalIdx, 1);

        % Ricostruisco la soglia corrispondente all'indice individuato
        soglia = (stepSoglia*firstMin) + 1;
    else
        % Fallback se non trovo un minimo locale
        soglia = 50;
    end

    fprintf('Soglia binarizzazione gauss connetti vene calcolata: %d\n',soglia);

    %% --- 5) (Opzionale) Plot diagnostici per show==1 ---
    if show == 1
        figure;

        % Numero CC originale vs smussato
        subplot(2,1,1);
        plot(vecSoglie, vecNumCC, 'b');
        hold on;
        plot(vecSoglie, vec_loess, 'b', 'LineWidth', 2);
        xlabel('Soglia');
        ylabel('Numero CC');
        title('Confronto vettore numero cc originale e smussato');
        legend('originale','loess');
        hold off;

        % Derivata del vettore smussato
        subplot(2,1,2);
        plot(vecSoglie(2:end), dy, 'b');
        xlabel('Soglia');
        ylabel('Derivata vettore CC');
        title('Derivata numero cc vettore smussato');

        sgtitle('Grafici fitting parametro soglia binarizzazione gauss');
    end

    %% --- 6) Binarizzazione finale e closing morfologico ---
    % Binarizzo il volume filtrato alla soglia stimata
    volumeGaussBin = binarizza(volumeGauss,'manuale',soglia);

    % Chiusura morfologica 3D con elemento sferico per colmare piccoli gap
    closedvolumeGaussBin = imclose(volumeGaussBin, strel('sphere', 3));

    % Visualizzazione finale (se show==1)
    graficoVolshow(closedvolumeGaussBin,'Volume connesso.',utente,acquisizione,show);
end

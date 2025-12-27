function [soglia] = calcolaSogliaIniziale(Mnp, mascheraNeroTotale, indiciPalmoNoPelle, vecDistProcessed, show)
%CALCOLASOGLIAINIZIALE Stima automaticamente la soglia iniziale di binarizzazione.
%
% Strategia:
% - Provo una serie di soglie decrescenti (da startSoglia a stopSoglia).
% - Per ciascuna soglia binarizzo il volume (binIncrementale) usando come profondità "fine"
%   un valore fissato (qui: fine = min(vecDistProcessed)).
% - Conteggio quante componenti connesse "grandi" (Volume >= 2000 voxel) risultano dalla binarizzazione.
% - Ottengo quindi un vettore vecNumCC(soglia) = #CC_valide al variare della soglia.
% - Smusso vecNumCC, calcolo la derivata discreta, e scelgo la soglia in un punto "di transizione"
%   vicino al massimo globale del numero di CC, cercando un minimo locale della derivata.
%
% Input:
%   Mnp                : volume pre-processato (0..255) su cui fare la binarizzazione
%   mascheraNeroTotale : maschera delle regioni da escludere
%   indiciPalmoNoPelle : mappa (y,x) della superficie del palmo (senza pelle)
%   vecDistProcessed   : vettore distanze (processato/smussato); qui usato per fissare fine
%   show               : 1 per mostrare i grafici di fitting, 0 altrimenti
%
% Output:
%   soglia             : valore di soglia iniziale stimato (intero)

    disp(newline)
    disp('***Inizio calcolo soglia iniziale***');

    % Range di soglie provate (decrescente): più alta = più selettiva, più bassa = più permissiva
    startSoglia = 250;
    stopSoglia  = 210;
    stepSoglia  = -1;

    % Numero di iterazioni = numero di soglie testate
    numIteration = numel(startSoglia:stepSoglia:stopSoglia);

    % Vettore che conterrà, per ogni soglia, quante CC "valide" vengono trovate
    vecNumCC = nan(1, numIteration);

    % Profondità massima considerata per la binarizzazione (scelta conservativa)
    % Qui si usa la minima distanza disponibile tra vene e palmo.
    fine = min(vecDistProcessed);

    %%------------------ Setup progresso (parfor) ------------------%%
    % (qui è definito ma l'invio send(...) è commentato, quindi non stampa progresso)
    D = parallel.pool.DataQueue;
    afterEach(D, @nUpdateProgress);
    numCompleted = 0;
    function nUpdateProgress(~)
        numCompleted = numCompleted + 1;
        percentComplete = (numCompleted / numIteration) * 100;
        fprintf('Progresso: %.2f%% completato\n', percentComplete);
    end
    %%--------------------------------------------------------------%%

    % 1) Sweep delle soglie: per ogni soglia binarizzo il volume e conto quante CC grandi ottengo
    parfor i = 1:numIteration

        % Con stepSoglia=-1 questa formula produce: 250,249,...,210
        soglia = (startSoglia + 1) + (stepSoglia * i);

        % Binarizzazione incrementale del volume:
        % - soglia corrente come soglia iniziale
        % - 255 come soglia finale (massima)
        [volBin] = binIncrementale(Mnp, mascheraNeroTotale, indiciPalmoNoPelle, fine, soglia, 255);

        % Calcolo CC 3D sul volume binario risultante
        CC = bwconncomp(volBin);

        % Ottengo il volume (numero voxel) di ciascuna componente
        tabCC = regionprops3(CC, 'Volume');

        % Tengo solo le CC "significative" (>=2000 voxel) e conto quante sono
        numCCval = find([tabCC.Volume] >= 2000);
        vecNumCC(i) = numel(numCCval);

        % Aggiornamento progresso (disabilitato)
        % send(D, i);
    end

    % 2) Smussamento del vettore #CC(soglia) per ridurre rumore da discretizzazione
    smoothing = 10;
    vecProcessed = smooth(vecNumCC, smoothing, 'loess');

    % Derivata discreta del vettore smussato: evidenzia le zone dove #CC cambia rapidamente
    dy = diff(vecProcessed);

    % 3) Trovo il massimo globale del vettore originale (non smussato)
    [maxVec, idMaxVec] = max(vecNumCC);

    % Trovo i massimi locali della derivata (punti di salita rapida)
    [~, maxLocalIdx] = findpeaks(dy);

    % Trovo i minimi locali della derivata (punti di discesa / cambio regime)
    minLocalIdx = find(islocalmin(dy) == 1);

    % 4) Selezione della soglia tramite "punto di transizione" vicino al massimo globale:
    % - scelgo il massimo locale della derivata più vicino a idMaxVec
    [~, idMinDistMax] = min(abs(maxLocalIdx - idMaxVec));
    idDerMaxNear = maxLocalIdx(idMinDistMax);

    % - scelgo il minimo locale della derivata più vicino a quel massimo locale
    [~, idMinDistMin] = min(abs(minLocalIdx - idDerMaxNear));
    idDerMinNear = minLocalIdx(idMinDistMin);

    % Converto l'indice (posizione nel vettore) in valore di soglia reale.
    % stepSoglia è negativo: aumentando l'indice diminuisce la soglia.
    soglia = startSoglia + (idDerMinNear * stepSoglia);

    fprintf('Soglia iniziale bin. calcolata: %d\n', soglia);

    % 5) Grafici di debug/interpretazione (opzionali)
    if show == 1
        % Asse delle soglie provate (stesso ordine del ciclo: 250 -> 210)
        vecIdSoglia = startSoglia:stepSoglia:stopSoglia;

        % Valori della derivata nei punti selezionati
        valDerMaxNear = dy(idDerMaxNear);
        valDerMinNear = dy(idDerMinNear);

        % Soglia associata al massimo locale della derivata vicino
        sogliaDerMaxNear = startSoglia + (idDerMaxNear * stepSoglia);

        figure;

        % (1) #CC vs soglia: originale e smussato + marker sul massimo globale originale
        subplot(2,1,1);
        plot(vecIdSoglia, vecNumCC, 'b');
        hold on;
        plot(vecIdSoglia, vecProcessed, 'b', 'LineWidth', 2);
        plot(vecIdSoglia(idMaxVec), maxVec, 'diamond', ...
             'MarkerSize', 10, 'MarkerEdgeColor', 'm', 'MarkerFaceColor', 'm', 'LineWidth', 2);

        % Inverte X per mostrare soglia decrescente da sinistra a destra (più intuitivo qui)
        set(gca, 'XDir', 'reverse');
        xlabel('Soglia');
        ylabel('Numero CC');
        title('Confronto vettore numero cc originale e smussato');
        legend('originale', 'loess', 'max originale', 'Location', 'southeast');
        xLimits = xlim;
        axis padded;
        xlim(xLimits);
        hold off;

        % (2) Derivata del vettore smussato: evidenzia massimo e minimo locali selezionati
        subplot(2,1,2);
        hold on;
        plot(vecIdSoglia(2:end), dy, 'b', 'LineWidth', 2);
        plot(sogliaDerMaxNear, valDerMaxNear, 'diamond', ...
             'MarkerSize', 10, 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'LineWidth', 2);
        plot(soglia, valDerMinNear, 'diamond', ...
             'MarkerSize', 10, 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'LineWidth', 2);

        set(gca, 'XDir', 'reverse');
        xlabel('Soglia');
        ylabel('Derivata vettore CC');
        title('Derivata numero cc vettore smussato');
        hold off;
        legend('der(loess)', 'nearest max', 'nearest min', 'Location', 'southeast');

        sgtitle('Grafici fitting parametro soglia binarizzazione iniziale');
    end

end

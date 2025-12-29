function [volumeFinale] = eliminaRumore(volume,indiciPalmoNoPelle,minSize,utente,acquisizione,show)
%ELIMINARUMORE Filtra componenti connesse rumorose usando metriche 3D+2D lungo Y e distanza dal palmo.
%
%   Questa funzione rimuove ulteriormente rumore residuo dal volume venoso, applicando:
%     1) un filtro dimensionale iniziale sulle componenti connesse (Volume >= minSize),
%     2) un'analisi slice-by-slice (piani XZ lungo Y) per ogni componente mantenuta,
%     3) la costruzione di feature "geometriche" e "di posizione":
%          - distanza media vena-palmo (lungo Z) calcolata sui piani XZ,
%          - pendenza media della distanza (variazione lungo Y),
%          - numero di piani XZ in cui la componente è presente,
%          - numero di piani in cui la componente tocca il bordo del piano (colonna 1 o end),
%     4) regole euristiche (soglie) per decidere se eliminare la componente.
%
%   INPUT
%     volume             Volume binario/logico (vene + rumore) da filtrare.
%     indiciPalmoNoPelle Matrice 2D (Y,X) che contiene la quota del palmo (senza pelle) per ogni (Y,X).
%                        Usata per calcolare la distanza palmo - vena sui piani XZ.
%     minSize            Soglia minima in voxel: CC sotto questa dimensione vengono scartate a priori.
%     utente             Identificativo utente (per plot/label).
%     acquisizione       Identificativo acquisizione (per plot/label).
%     show               Flag di visualizzazione:
%                        - 0: nessun grafico diagnostico
%                        - 1: mostra volumi e grafici delle feature/soglie
%
%   OUTPUT
%     volumeFinale       Volume binario finale con il rumore filtrato secondo le euristiche.
%
%   METODO (dettaglio)
%   - Per ogni CC grande:
%       * Per y = 1:stepY:yDim:
%           - estrai piano XZ della componente
%           - se presente, trova il centroide della CC "più in basso" (max Z) nel piano
%           - calcola distanza distVeinPalm = Zpalmo(y,xCentroid) - zCentroid
%           - incrementa contatore nPiani se la CC tocca il bordo sinistro o destro del piano
%       * Dalla sequenza di distanze (una per vari y):
%           - calcola statistiche (mean, median, std, min, max, range, var, percentili)
%           - calcola una "pendenza media" dalla derivata del segnale smussato (LOESS)
%           - calcola nPianiXZ (lunghezza del segnale * stepY)
%   - Soglie euristiche:
%       * sogliaDist = mean(distMean) + std(distMean)  (solo sulle componenti con distMean != 0)
%       * sogliaPend = 5
%       * sogliaPiani = 30
%       * sogliaPianiBordo(i) = 20% di mat(i,11)  (qui c'è un dettaglio: nel codice usa mat(:,11))
%   - Regole di eliminazione:
%       * se nPianiXZ < sogliaPiani  -> elimina
%       * se nPianiBordo > sogliaPianiBordo -> elimina (componente troppo "attaccata" ai bordi)
%       * se distMean > sogliaDist E pendMean < sogliaPend -> elimina (lontana dal palmo e poco variabile)
%
%   NOTE IMPORTANTI (coerenza e possibili edge-case)
%   - Nel codice originale la variabile "minSize" viene riusata dentro il calcolo
%     delle statistiche come "min(component)" (sovrascrivendo il parametro). Qui
%     NON si modifica la logica, ma è un punto da evitare in refactoring.
%   - Nel parfor interno: y viene calcolato come y = j*stepY, mentre vecY è
%     startY:stepY:stopY. Con startY=1, stepY=2, j=1 -> y=2 (si salta y=1).
%     È coerente col codice originale ma da tenere a mente.
%   - La tabella T viene creata ma non usata oltre ai grafici (utile per debug).

    %% --- 1) Filtro dimensionale iniziale: tengo solo CC >= minSize ---
    [~,volFilt] = dividiCCvolume(volume,minSize);

    CC = bwconncomp(volFilt);
    tabCC = regionprops3(CC,'Volume','Centroid'); % Centroid non usato direttamente qui

    %% --- 2) Setup analisi slice-by-slice lungo Y (piani XZ) ---
    yDim = size(volume,1);
    numComponents = height(tabCC);

    startY = 1;
    stopY  = yDim;
    stepY  = 2;

    vecY = startY:stepY:stopY;

    % Matrice distanza vena-palmo: righe=componenti, colonne=campionamenti lungo Y
    matDistVeinPalm = nan(numComponents, numel(vecY));

    % Numero di piani XZ in cui la componente tocca bordo (colonna 1 o end)
    vecPianiBordo = zeros(1,numComponents);

    %% --- 3) Per ogni componente: calcolo distanze e piani "a bordo" ---
    for i = 1:numComponents
        volumeSize = tabCC.Volume(i,:);
        nPiani = 0;

        if volumeSize >= minSize
            % Ricostruisce la componente i-esima come maschera 3D
            comp = false(size(volume));
            comp(CC.PixelIdxList{i}) = true;

            parfor j = 1:numel(vecY)
                % NOTA: nel codice originale y è ottenuto da j*stepY (non da vecY(j))
                y = j * stepY;

                % Piano XZ (trasposto per convenzione)
                piano = squeeze(comp(y,:,:))';

                if nnz(piano) > 0
                    % Calcolo centroidi delle CC presenti sul piano
                    cc = bwconncomp(piano);
                    props = regionprops(cc, 'Centroid');
                    centroids = cat(1, props.Centroid);

                    % Scelgo il centroide con Z massimo (seconda coordinata nel piano XZ)
                    [~, idxMaxZ] = max(centroids(:,2));
                    centroid = centroids(idxMaxZ, :);

                    coordX = round(centroid(1));
                    coordZ = round(centroid(2));

                    % Quota palmo (senza pelle) in quel punto (y, x)
                    cordZPalm = indiciPalmoNoPelle(y, coordX);

                    % Distanza palmo - vena (positiva se la vena è "sotto" il palmo)
                    distVeinPalm = cordZPalm - coordZ;
                    matDistVeinPalm(i,j) = distVeinPalm;

                    % Verifica contatto col bordo del piano (prima o ultima colonna)
                    colonna1  = piano(:,1);
                    colonnaEnd = piano(:,end);

                    if nnz(colonna1) > 0 || nnz(colonnaEnd) > 0
                        nPiani = nPiani + 1;
                    end
                end
            end

            % Salva numero di piani a bordo per la componente i
            vecPianiBordo(1,i) = nPiani;
        end
    end

    %% --- 4) Costruzione feature statistiche per ogni componente ---
    % Matrice feature: 11 colonne (mean, median, std, min, max, range, var, p25, p75, pendMean, npianiXZ)
    mat = zeros(numComponents,11);

    for i = 1:numComponents
        rowVector = matDistVeinPalm(i, :);
        component = rowVector(~isnan(rowVector)); % sequenza distanze valida

        if ~isempty(component)
            means = mean(component);
            medians = median(component);
            std_devs = std(component);
            minSize_local = min(component); %#ok<NASGU> % (evito di sovrascrivere minSize input)
            maxs = max(component);
            ranges = range(component);
            variances = var(component);
            percentiles_25 = prctile(component, 25);
            percentiles_75 = prctile(component, 75);

            % "Pendenza media": smusso e calcolo derivata, poi media assoluta in percentuale
            smoothing = size(component,2);
            vecSmooth = smooth(component, smoothing, 'loess');
            dvSmooth = diff(vecSmooth);
            pmean = abs(mean(dvSmooth) * 100);

            % Numero di piani XZ coperti (campioni * passo)
            npianiXZ = numel(component) * stepY;

            mat(i,:) = [means, medians, std_devs, min(component), maxs, ranges, variances, ...
                        percentiles_25, percentiles_75, pmean, npianiXZ];
        end
    end

    % Tabella (principalmente per debug/plot)
    T = array2table(mat, ...
        'VariableNames', {'Mean', 'Median', 'StdDev', 'Min', 'Max', 'Range', 'Variance', ...
                          'Percentile25', 'Percentile75', 'PendMean', 'PianiXZ'}); %#ok<NASGU>

    %% --- 5) Definizione soglie euristiche ---
    % 5a) Soglia su distanza media palmo-vena
    vecDistMean = mat(:,1);
    vecDistMean = vecDistMean(vecDistMean ~= 0);
    mu = mean(vecDistMean);
    sigma = std(vecDistMean);
    sogliaDist = mu + sigma;

    % Vettori "orizzontali" per tracciare le soglie sui plot
    vecPosSogliaMeanDist = linspace(1, size(vecDistMean,1), 10);
    vecSogliaMeanDist = sogliaDist * ones(size(vecPosSogliaMeanDist));

    % 5b) Soglia su pendenza media
    sogliaPend = 5;
    vecSogliaPend = sogliaPend * ones(size(vecPosSogliaMeanDist));
    vecPendMean = mat(:,10);
    vecPendMean = vecPendMean(vecPendMean ~= 0);

    % 5c) Soglia su numero di piani XZ "coperti"
    sogliaPiani = 30;
    vecSogliaPiani = sogliaPiani * ones(size(vecPosSogliaMeanDist));
    vecPiani = mat(:,11);
    vecPiani = vecPiani(vecPiani ~= 0);

    % 5d) Soglia su numero di piani attaccati al bordo (20% dei piani XZ)
    % NOTA: nel codice originale usa mat(:,11)*(20/100) come soglia per ogni componente.
    vecSogliaPianiBordo = mat(:,11) * (20/100);

    %% --- 6) Filtraggio finale delle componenti secondo le regole ---
    volumeFinale = false(size(volume));
    numComponents = height(tabCC);

    for i = 1:numComponents
        volumeSize = tabCC.Volume(i,:);

        if volumeSize >= minSize
            % Ricostruisce componente
            comp = false(size(volume));
            comp(CC.PixelIdxList{i}) = true;

            % Feature chiave per le regole
            distMean = mat(i,1);
            pendMean = mat(i,10);
            nPianiXZ = mat(i,11);

            % Regole di eliminazione (euristiche)
            if nPianiXZ < sogliaPiani
                comp = false;
            elseif vecPianiBordo(i) > vecSogliaPianiBordo(i)
                comp = false;
            elseif distMean > sogliaDist && pendMean < sogliaPend
                comp = false;
            end

            % Accumulo nel volume finale
            volumeFinale = volumeFinale | comp;
        end
    end

    graficoVolshow(volumeFinale,'Volume rumore filtrato',utente,acquisizione,show);

    %% --- 7) Plot diagnostici (opzionale) ---
    if show == 1

        subplot(2,3,1);
        hold on;
        legends = strings(1, numComponents);
        for i = 1:numComponents
            rowVector = matDistVeinPalm(i, :);
            plot(vecY, rowVector,'LineWidth',2);
            legends(i) = sprintf('Componente %d', i);
        end
        xlabel('Y');
        ylabel('Distanza vena-palmo');
        title('Distanza vena-palmo delle cc');
        legend(legends, 'Location', 'best');
        hold off;

        subplot(2,3,2);
        x = 1:1:size(vecDistMean,1);
        scatter(x, vecDistMean,'x','LineWidth',2);
        hold on;
        plot(vecPosSogliaMeanDist, vecSogliaMeanDist, 'r--');
        xlabel('componente');
        ylabel('Distanza palmo-vena media per ogni piano XZ');
        title('Distanza dal palmo dei centrodi dei piani XZ');
        hold off;

        subplot(2,3,3);
        x = 1:1:size(vecPendMean,1);
        scatter(x, vecPendMean,'x','LineWidth',2);
        hold on;
        plot(vecPosSogliaMeanDist, vecSogliaPend, 'r--');
        xlabel('componente');
        ylabel('Valore assoluto pendenza media della componente abs(%)');
        ylim([0 max(vecPendMean)]);
        title('Pendenze medie delle componenti');
        hold off;

        subplot(2,3,4);
        x = 1:1:size(vecPiani,1);
        scatter(x, vecPiani,'x','LineWidth',2);
        hold on;
        plot(vecPosSogliaMeanDist, vecSogliaPiani, 'r--');
        xlabel('componente');
        ylabel('n.piani XZ');
        ylim([0 max(vecPiani)]);
        title('Numero di piani XZ della componente');
        hold off;

        subplot(2,3,5);
        x = 1:1:size(vecPianiBordo,2);
        scatter(x, vecPianiBordo,'x','LineWidth',2);
        hold on;
        plot(x, vecSogliaPianiBordo, 'r--');
        xlabel('componente');
        ylabel('n.piani bordo XZ');
        title('Numero di piani XZ della componente attaccati al bordo');
        hold off;
    end
end

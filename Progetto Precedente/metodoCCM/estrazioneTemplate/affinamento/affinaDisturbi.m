function [volAffinato,volPallini] = affinaDisturbi(volume)
%AFFINADISTURBI Rimuove disturbi 2D slice-by-slice e separa "pallini" (rumore piccolo) dalle vene.
%
%   La funzione opera per slice lungo Y (piani XZ) e, per ogni piano non vuoto:
%     1) riempie i buchi (imfill) per rendere le regioni più compatte,
%     2) raggruppa le CC vicine tra loro in base alla distanza tra centroidi
%        (costruendo un grafo e calcolando le componenti connesse del grafo),
%     3) per ciascun gruppo:
%          - filtra rumore piccolo "attaccato" alle vene separando aree piccole
%            (pallini) da aree grandi (vene) in base alla Area relativa,
%          - applica un'apertura morfologica adattiva sulle singole CC (imopen con raggio
%            derivato dall'EquivDiameter) per rimuovere appendici/artefatti sottili,
%          - se l'apertura elimina tutto, ripristina la CC originale,
%          - elimina eventuali frammenti staccati mantenendo solo le porzioni con Area
%            significativa rispetto alla più grande.
%     4) ricostruisce il volume 3D:
%          - volAffinato contiene le vene "pulite"
%          - volPallini contiene il rumore/piccole componenti rimosse
%
%   INPUT
%     volume      Volume 3D binario/logico. La funzione lavora su piani XZ lungo Y.
%
%   OUTPUT
%     volAffinato Volume 3D logico contenente le strutture venose affinate.
%     volPallini  Volume 3D logico contenente le componenti piccole rimosse ("pallini").
%
%   NOTE
%   - La funzione usa parfor sulla dimensione Y: le slice sono indipendenti.
%   - Le convenzioni di orientamento:
%       piano = squeeze(volume(y,:,:))'   (trasposta per avere X/Z come atteso)
%     e alla fine si ripristina nel volume con permute([2 1]).
%   - Alcune chiamate a visualizzaPianoXZ sono presenti per debug (show=0 fisso).
%

    % Numero di slice lungo Y (piani XZ)
    yDim = size(volume,1);

    % Output: inizializzo con input e volPallini vuoto
    volAffinato = volume;
    volPallini  = false(size(volume));

    %% --- Loop (parallelo) sulle slice Y ---
    parfor y = 1:yDim

        % Estrae il piano XZ alla coordinata y (trasposto per convenzione)
        piano = squeeze(volume(y,:,:))';

        % Processa solo se il piano contiene voxel attivi
        if nnz(piano) > 0

            %% 1) Riempimento buchi
            piano = imfill(piano,"holes");
            visualizzaPianoXZ(piano,y,0);

            %% 2) Raggruppamento CC vicine tramite distanza centroidi
            % Etichette 2D e centroidi delle componenti
            [labelMatrix, numComponents] = bwlabel(piano);
            props = regionprops(labelMatrix, 'Centroid');
            centroidi = cat(1, props.Centroid);

            % Matrice distanze tra centroidi
            distanze = pdist2(centroidi, centroidi);

            % Soglia di vicinanza basata sul diametro equivalente massimo
            cc = bwconncomp(piano);
            stats = regionprops(cc,'EquivDiameter');
            soglia = max([stats.EquivDiameter]) * 2;

            % Matrice adiacenza: "vicini" se distanza < soglia (escludo diagonale a 0)
            vicini = distanze < soglia & distanze > 0;

            % Grafo di vicinanza e componenti connesse del grafo (gruppi)
            G = graph(vicini);
            componenti = conncomp(G);
            numGruppi = max(componenti);

            % (solo per debug/organizzazione) maschere di gruppo
            immaginiGruppi = cell(1, numGruppi);

            % Accumulatori per il piano corrente
            pianoVena    = false(size(piano));
            pianoPallini = false(size(piano));

            %% 3) Ciclo sui gruppi di componenti "vicine"
            for k = 1:numGruppi
                % Maschera del gruppo k: include tutte le CC con stesso id di gruppo
                mask = ismember(labelMatrix, find(componenti == k));
                immaginiGruppi{k} = mask;

                % Piano corrente = solo gruppo k
                piano = mask;
                visualizzaPianoXZ(piano,y,0);

                %% 3.1) Filtraggio rumore "attaccato" alle vene (per area relativa)
                cc = bwconncomp(piano);
                stats = regionprops(cc,'Area');
                L = labelmatrix(cc);

                maxArea = max([stats.Area]);
                sogliaArea = maxArea * 0.1; % tengo le CC con area >= 10% della più grande

                areeValide  = find([stats.Area] >= sogliaArea);
                areePallini = find([stats.Area] <  sogliaArea);

                % Piano filtrato (vene) e pallini separati
                pianoFilt     = ismember(L, areeValide);
                pianoPallini  = pianoPallini | ismember(L, areePallini);

                %% 3.2) Itero sulle CC rimaste per pulizia morfologica adattiva
                pianoFinale = false(size(piano));

                % NOTA: nel codice originale si ricalcola su "piano" (non su pianoFilt).
                % Mantengo la stessa logica.
                cc = bwconncomp(piano);

                for i = 1:cc.NumObjects
                    % Estrae la singola componente
                    componente = false(size(pianoFilt));
                    componente(cc.PixelIdxList{i}) = true;

                    %% 4) Apertura morfologica adattiva (raggio da EquivDiameter)
                    statsComp = regionprops(componente, 'EquivDiameter');
                    maxDiamComp = max([statsComp.EquivDiameter]);

                    ray = round(maxDiamComp / 8);
                    componenteOpen = false(size(componente));

                    % Decrementa il raggio finché l'apertura non lascia qualcosa
                    while ~any(componenteOpen(:)) && ray > 0
                        se = strel('disk', ray);
                        componenteOpen = imopen(componente, se);
                        ray = ray - 1;
                    end

                    % Se anche così è vuoto, ripristina la componente originale
                    if ~any(componenteOpen(:))
                        componenteOpen = componente;
                    end

                    %% 4.1) Filtraggio frammenti staccati post-apertura (per area)
                    ccOpen = bwconncomp(componenteOpen);
                    statsOpen = regionprops(ccOpen, 'Area');

                    maxAreaOpen = max([statsOpen.Area]);
                    sogliaArea = maxAreaOpen * 0.5; % tengo solo pezzi >= 50% della CC più grande

                    areeValide = find([statsOpen.Area] >= sogliaArea);
                    LOpen = labelmatrix(ccOpen);

                    componenteFilt = ismember(LOpen, areeValide);

                    %% 5) Accumulo nel piano finale del gruppo
                    pianoFinale = pianoFinale | componenteFilt;
                end

                % Accumulo vene del gruppo
                pianoVena = pianoVena | pianoFinale;
            end

            %% 6) Scrittura dei risultati nel volume 3D (ripristino orientamento)
            volAffinato(y,:,:) = permute(pianoVena,    [2, 1]);
            volPallini(y,:,:)  = permute(pianoPallini, [2, 1]);
        end
    end
end

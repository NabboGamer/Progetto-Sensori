function [vettoreDistanze, matriceDiametri] = calcolaMinDistVenePalmo(volume, volumePalmo, utente, acquisizione)
%CALCOLAMINDISTVENEPALMO Calcola, per ogni piano XZ (indice y), la distanza minima
% tra le vene segmentate e il palmo (superficie/limite del tessuto) lungo la direzione z.
%
% Output:
%   vettoreDistanze  : vettore 1×yDim; per ogni y contiene la minima distanza (in voxel) vene↔palmo
%   matriceDiametri  : matrice 2×yDim:
%                      - riga 1: diametro stimato della vena nel piano y (NaN se non stimabile)
%                      - riga 2: distanza associata a quel diametro (qui: stessa min distanza usata sopra)
%
% Nota: La distanza è calcolata lungo colonna z (per ogni x), come:
%   distanza = (indicePalmo - indiceVene)
% dove indicePalmo è l'ultimo voxel non-zero del palmo nella colonna, e indiceVene
% è uno dei voxel più "profondi" della vena (si usa numVoxelVena per stabilità).

    disp(newline);
    disp('***Inizio calcolo distanza minima vene-palmo***');

    % 1) Azzero manualmente fasce laterali in x (taglio regioni note come spurie/rumorose)
    %    (qui vengono rimossi bordi/zone esterne del volume)
    volume(:,1:50,:)      = 0;
    volume(:,600:650,:)   = 0;
    volumePalmo(:,1:50,:) = 0;
    volumePalmo(:,600:650,:) = 0;

    % 2) Ulteriore taglio bordi con funzione dedicata
    volume      = tagliaBordi(volume);
    volumePalmo = tagliaBordi(volumePalmo);

    % 3) Creo un volume unito (OR logico) solo per visualizzare palmo + vene insieme
    volumePalmoVene = volume | volumePalmo;
    graficoVolshow(volumePalmoVene, 'Volume palmo unito al volume vene', utente, acquisizione, 0);

    % Dimensioni (convenzione: y,x,z)
    xDim = size(volumePalmoVene,2);
    yDim = size(volumePalmoVene,1);

    % Numero di voxel vena richiesti in una colonna per considerare la misura affidabile
    % (serve a evitare falsi positivi con 1 solo voxel isolato)
    numVoxelVena = 3;

    % Vettore output: una distanza minima per ogni piano y
    vettoreDistanze = nan(1, yDim);

    % Strutture per salvare diametri e la distanza a cui sono stati stimati
    matriceDiametri          = nan(2, yDim);
    vettoreDiametri          = nan(1, yDim);
    vettoreDistanzeDiametri  = nan(1, yDim);

    % Loop parallelo sui piani XZ (uno per ogni y)
    parfor y = 1:yDim

        % Estraggo il piano XZ delle vene e del palmo per questo y
        pianoXZVene = squeeze(volume(y,:,:))';
        pianoPalmo  = squeeze(volumePalmo(y,:,:))';

        % 4) Pulizia morfologica del piano vene:
        %    - erosione per eliminare pixel sottili/spuri
        %    - fill holes per compattare le regioni (chiudere piccoli buchi)
        pianoEroded  = imerode(pianoXZVene, strel('sphere',1));
        pianoFilling = imfill(pianoEroded, 'holes');

        % 5) Selezione delle componenti connesse "valide" per area (filtra rumore e regioni troppo grandi)
        CC = bwconncomp(pianoFilling);
        structCC = regionprops(CC, 'Area');
        L = labelmatrix(CC);

        % Tengo solo oggetti con area tra 20 e 2500 pixel (range empirico per vene plausibili)
        areeValide = find([structCC.Area] > 20 & [structCC.Area] < 2500);
        pianoCCvalide = ismember(L, areeValide);

        % 6) Stimo un diametro vena nel piano (funzione custom)
        %    (verosimilmente usa pianoCCvalide e la geometria del palmo per calcolare un diametro "sensato")
        diametroVena = calcolaDiametroVena(pianoCCvalide, pianoPalmo, y);

        % 7) Calcolo, per ogni x, la distanza vene↔palmo lungo z e poi scelgo la minima
        vettoreDistanzePiano = nan(1, xDim);

        for x = 1:xDim
            % Colonne lungo z a x fissato
            colonnaPalmo    = squeeze(pianoPalmo(:,x));
            colonnaCCvalide = squeeze(pianoCCvalide(:,x));

            % Indice del palmo: ultimo voxel non-zero (punto più profondo del palmo in quella colonna)
            indicePalmo = find(colonnaPalmo ~= 0, 1, 'last');

            % Indici delle vene: ultimi numVoxelVena voxel non-zero (parte più profonda della vena)
            indiceVene = find(colonnaCCvalide ~= 0, numVoxelVena, 'last');
            numIndici  = size(indiceVene,1);

            % Se ho abbastanza voxel vena, considero la distanza affidabile:
            % prendo indiceVene(1) perché find(...,'last') ritorna gli indici in ordine crescente,
            % quindi (1) è il più piccolo tra quelli selezionati, cioè quello più "alto" dei tre.
            % (La distanza viene comunque stabilizzata dal requisito dei 3 voxel.)
            if numIndici >= numVoxelVena
                altezzaPalmo = indicePalmo;
                altezzaVene  = indiceVene(1);
                distanzaVenePalmo = altezzaPalmo - altezzaVene; % distanza in voxel lungo z
                vettoreDistanzePiano(x) = distanzaVenePalmo;
            end
        end

        % 8) Per questo piano y salvo la distanza minima tra tutte le colonne x
        if any(~isnan(vettoreDistanzePiano))
            vettoreDistanze(y) = min(vettoreDistanzePiano);

            % Se ho anche un diametro stimato, salvo diametro e la distanza associata
            if ~isnan(diametroVena)
                vettoreDiametri(y) = diametroVena;
                vettoreDistanzeDiametri(y) = min(vettoreDistanzePiano);
            end
        end
    end

    % Compongo la matrice finale diametri:
    % riga 1 = diametri, riga 2 = distanze associate
    matriceDiametri(1,:) = vettoreDiametri;
    matriceDiametri(2,:) = vettoreDistanzeDiametri;

end

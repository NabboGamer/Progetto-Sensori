function [volumeFiltrato,tabellaCCFiltrata] = filtraCC(volume,indiciPalmoNoPelle,vecFine,model,stopRicorsione)
%FILTRACC Filtra le componenti connesse con un classificatore e (opzionale) recupero ricorsivo di vene.
% 
%   Questa funzione esegue la classificazione automatica delle componenti connesse (CC)
%   di un volume binario/segmentato per distinguere "vene" da "rumore" usando un
%   modello supervisionato (Random Forest / Bagging in model).
%
%   Pipeline:
%     1) Estrae le componenti connesse dal volume (bwconncomp)
%     2) Calcola proprietà 3D base (regionprops3)
%     3) Costruisce feature derivate (rapporti tra assi, surface/volume, ecc.)
%        + feature legate a distanza dalla superficie del palmo e a vecFine
%     4) Per ogni CC:
%          - crea il vettore di feature compatibile con il modello (rimuovendo
%            colonne non usate in training)
%          - predice isVena = 1 (vena) oppure 0 (rumore)
%          - se classificata come rumore ma molto grande, prova un "recupero"
%            (recuperaVena) per gestire errori di classificazione
%     5) Ricostruisce il volume finale mantenendo le CC predette come vene
%        + eventuali parti recuperate
%     6) Restituisce anche la tabella filtrata contenente solo le CC tenute (isVena==1)
%
%   INPUT
%     volume             Volume binario/logico da filtrare (voxel != 0 = oggetto).
%     indiciPalmoNoPelle Matrice 2D (Y,X) che fornisce la quota/profondità "palmo"
%                        in assenza di pelle, usata per stimare distanze dal centroide.
%     vecFine            Vettore indicizzato su Y, combinato con distanze per creare feature.
%     model              Modello di classificazione addestrato (es. fitcensemble).
%     stopRicorsione     Contatore massimo per limitare ricorsione nel recupero vene.
%                        Viene decrementato a ogni chiamata e propagato a recuperaVena.
%
%   OUTPUT
%     volumeFiltrato     Volume finale (uint8) con voxel attivi a 255.
%     tabellaCCFiltrata  Tabella delle CC mantenute, con proprietà + feature + isVena.
%
%   NOTE IMPORTANTI
%   - Le feature passate al modello sono ottenute rimuovendo alcune colonne dalla
%     tabella (Volume, EquivDiameter, SurfaceArea, PrincipalAxisLength, Centroid, distCentroidPelle).
%     Questo deve essere coerente con il dataset usato in addestramento.
%   - "Recupero vena": se una CC è predetta come rumore (0) ma Volume>20000,
%     viene chiamata recuperaVena per tentare di recuperare porzioni venose perse.

    %% --- 0) Gestione contatore ricorsione ---
    stopRicorsione = stopRicorsione-1;
    fprintf('stopRicorsione = %d\n',stopRicorsione);

    % Volume che accumula eventuali porzioni "recuperate" (inizialmente vuoto)
    volumeRecuperato = false(size(volume));

    %% --- 1) Estrazione CC e proprietà base ---
    CC = bwconncomp(volume);

    tabellaCC = regionprops3(CC, ...
        'Volume','PrincipalAxisLength','EquivDiameter','Extent','Solidity','SurfaceArea','Centroid');

    numComponents = height(tabellaCC);

    %% --- 2) Preallocazione feature derivate ---
    rapportoAssiYZ = zeros(numComponents, 1);
    rapportoAssiXZ = zeros(numComponents, 1);
    rapportoAssiXY = zeros(numComponents, 1);

    rapportoVolumeY = zeros(numComponents, 1);
    rapportoVolumeX = zeros(numComponents, 1);
    rapportoVolumeZ = zeros(numComponents, 1);

    rapportoSurfaceVolume = zeros(numComponents, 1);
    rapportoSurfaceYDim = zeros(numComponents, 1);
    rapportoSurfaceXDim = zeros(numComponents, 1);
    rapportoSurfaceZDim = zeros(numComponents, 1);

    distCentroidPelle  = zeros(numComponents, 1);
    rappFineBinDistCP  = zeros(numComponents, 1);

    rappDimXCentX = zeros(numComponents, 1);
    rappDimZCentZ = zeros(numComponents, 1);
    rappDimYCentY = zeros(numComponents, 1);

    % Predizioni finali: 1=vena, 0=rumore
    isVena = zeros(numComponents, 1);

    %% --- 3) Popolamento feature per ogni componente ---
    for i = 1:numComponents
        volumeSize          = tabellaCC.Volume(i,:);
        surfaceArea         = tabellaCC.SurfaceArea(i,:);
        principalAxisLength = tabellaCC.PrincipalAxisLength(i,:);
        centroids           = tabellaCC.Centroid(i,:);

        % Mappatura assi (come nel resto del progetto)
        xDim = principalAxisLength(3); % lungo X
        yDim = principalAxisLength(1); % lungo Y
        zDim = principalAxisLength(2); % lungo Z

        % Rapporti assi e "densità" volume/dimensione
        rapportoAssiYZ(i) = yDim / zDim;
        rapportoAssiXZ(i) = xDim / zDim;
        rapportoAssiXY(i) = xDim / yDim;

        rapportoVolumeY(i) = volumeSize / yDim;
        rapportoVolumeX(i) = volumeSize / xDim;
        rapportoVolumeZ(i) = volumeSize / zDim;

        % Rapporti superficie / dimensione e superficie / volume
        rapportoSurfaceYDim(i) = surfaceArea / yDim;
        rapportoSurfaceXDim(i) = surfaceArea / xDim;
        rapportoSurfaceZDim(i) = surfaceArea / zDim;
        rapportoSurfaceVolume(i) = surfaceArea / volumeSize;

        % Centroide (arrotondato a voxel)
        centroidX = round(centroids(1));
        centroidY = round(centroids(2));
        centroidZ = round(centroids(3));

        % Quota del palmo nel punto (centroidY, centroidX)
        palmoZ = indiciPalmoNoPelle(centroidY, centroidX);

        % Distanza centroide-pelle/palmo e feature combinata con vecFine
        distCentroidPelle(i) = palmoZ - centroidZ;
        rappFineBinDistCP(i) = vecFine(centroidY) / (palmoZ - centroidZ);

        % Rapporti dimensione/posizione del centroide
        rappDimXCentX(i) = xDim / centroidX;
        rappDimYCentY(i) = yDim / centroidY;
        rappDimZCentZ(i) = zDim / centroidZ;
    end

    %% --- 4) Aggiunta feature derivate alla tabella ---
    tabellaCC.rapportoSurfaceVolume = rapportoSurfaceVolume;
    tabellaCC.rapportoAssiYZ        = rapportoAssiYZ;
    tabellaCC.rapportoAssiXZ        = rapportoAssiXZ;
    tabellaCC.rapportoAssiXY        = rapportoAssiXY;
    tabellaCC.rapportoVolumeY       = rapportoVolumeY;
    tabellaCC.rapportoVolumeX       = rapportoVolumeX;
    tabellaCC.rapportoVolumeZ       = rapportoVolumeZ;
    tabellaCC.rapportoSurfaceYDim   = rapportoSurfaceYDim;
    tabellaCC.rapportoSurfaceXDim   = rapportoSurfaceXDim;
    tabellaCC.rapportoSurfaceZDim   = rapportoSurfaceZDim;
    tabellaCC.distCentroidPelle     = distCentroidPelle;
    tabellaCC.rappFineBinDistCP     = rappFineBinDistCP;
    tabellaCC.rappDimXCentX         = rappDimXCentX;
    tabellaCC.rappDimYCentY         = rappDimYCentY;
    tabellaCC.rappDimZCentZ         = rappDimZCentZ;

    %% --- 5) Classificazione CC + eventuale recupero ---
    for i = 1:numComponents
        volumeSize = tabellaCC.Volume(i,:);

        % Preparo la riga di feature in modo coerente con l'addestramento:
        % rimuovo colonne non usate dal modello
        componenteTabella = tabellaCC(i, :);
        componenteTabella.Volume = [];
        componenteTabella.EquivDiameter = [];
        componenteTabella.SurfaceArea = [];
        componenteTabella.PrincipalAxisLength = [];
        componenteTabella.Centroid = [];
        componenteTabella.distCentroidPelle = [];

        % Converto in array numerico e predico la classe
        componente = table2array(componenteTabella);
        isVena(i) = predict(model, componente(1:end));

        % Recupero: se predetta come rumore ma molto grande, provo a recuperare
        if isVena(i) == 0 && volumeSize > 20000
            [volFilt,stop] = recuperaVena(volume,CC,i,indiciPalmoNoPelle,vecFine,model,stopRicorsione);
            if stop > -1
                volumeRecuperato = volumeRecuperato | volFilt;
            end
        end
    end

    % Salvo le predizioni in tabella
    tabellaCC.isVena = isVena;

    %% --- 6) Ricostruzione volume filtrato (CC classificate come vene) ---
    idComponentiValidi = find(tabellaCC.isVena == 1);

    % Maschera binaria delle CC "valide"
    volumeFiltrato = ismember(labelmatrix(CC), idComponentiValidi);

    % Unisco eventuale volume recuperato
    volumeFiltrato = volumeFiltrato | volumeRecuperato;

    % Converto in uint8 e porto i voxel attivi a 255
    volumeFiltrato = uint8(volumeFiltrato);
    volumeFiltrato(volumeFiltrato == 1) = 255;

    fprintf('Numero di componenti mantenute: %d\n', size(idComponentiValidi,1));

    %% --- 7) Filtraggio tabella: tengo solo righe con isVena==1 ---
    tabellaCCFiltrata = tabellaCC;
    righeDaRimuovere = tabellaCCFiltrata.isVena == 0;
    tabellaCCFiltrata(righeDaRimuovere, :) = [];
end

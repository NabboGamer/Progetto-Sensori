function [pianoFinale] = binOffsetVena(Mat, xDim, zDim, y)
%BINOFFSETVENA Estende/propaga la binarizzazione lungo z a partire dalla zona delle vene
% in un singolo piano XZ (per una y fissata).
%
% Idea:
% - Mat contiene un volume binario/logico (y,x,z) già ottenuto da una prima binarizzazione.
% - Per il piano y corrente estraggo il piano XZ e calcolo le componenti connesse.
% - Uso i centroidi delle CC per stimare una quota di riferimento lungo z (idZcent):
%   prendo il minimo dei centroidi in z (cioè la vena più "superficiale" tra quelle trovate).
% - A partire da questa quota, propago verso profondità maggiori di un offset fisso (offsetVene),
%   copiando nel risultato tutti i voxel già attivi in Mat su quelle slice.
%
% Output:
% - pianoFinale (logical zDim×xDim): maschera binaria del piano XZ dopo la propagazione.

    % Inizializzo maschera di output del piano XZ (z,x)
    pianoFinale = false(zDim, xDim);

    % Estraggo il piano XZ relativo a y:
    % squeeze(Mat(y,:,:)) -> [x,z], trasposto -> [z,x]
    pianoXZ = squeeze(Mat(y, :, :))';

    % Trovo le componenti connesse nel piano binario
    CC = bwconncomp(pianoXZ);

    % Calcolo i centroidi delle CC (coordinate in formato [x, z] per una 2D image)
    tab = struct2table(regionprops(CC, 'Centroid'));

    % Estraggo la coordinata "z" dei centroidi:
    % tab.Centroid è una cell/array Nx1 di vettori [x, z], quindi prendo la seconda componente.
    colonnaCordZCentroid = tab.Centroid(:,2);

    % Scelgo come quota di riferimento il centroid più "superficiale" (z minimo),
    % arrotondato a indice intero.
    idZcent = round(min(colonnaCordZCentroid));

    % Offset fisso: quante slice verso il "basso" (profondità) voglio estendere la maschera
    offsetVene = 60;

    % Propago la maschera per offsetVene slice a partire da idZcent:
    % per ogni slice indice_z copio i voxel attivi presenti in pianoXZ dentro pianoFinale.
    for zplane = 1:offsetVene
        indice_z = idZcent + zplane;

        % (Consigliato: controllo bounds per evitare indice_z > zDim)
        % if indice_z > zDim, break; end

        % Leggo l'intera riga (su x) della slice indice_z
        rigaVoxelPiano = zeros(1, xDim);
        for x = 1:xDim
            rigaVoxelPiano(1, x) = pianoXZ(indice_z, x);
        end

        % Copio nel piano finale i voxel attivi (true) di quella slice
        for x = 1:xDim
            if rigaVoxelPiano(1, x)
                pianoFinale(indice_z, x) = true;
            end
        end
    end

end

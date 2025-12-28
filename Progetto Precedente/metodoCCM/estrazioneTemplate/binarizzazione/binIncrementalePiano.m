function [MatFinale] = binIncrementalePiano(MatFinale, Minv, indiciPalmoNoPelle, ...
                                            fine, inizio, sogliaIniziale, sogliaFinale, ...
                                            xDim, y)
%BININCREMENTALEPIANO Versione "per singolo piano" della binarizzazione incrementale.
% Applica la sogliatura incrementale solo sulla riga y (cioè su una sezione XZ),
% campionando lungo z a partire dagli indici del palmo (indiciPalmoNoPelle) e
% aggiornando direttamente il volume binario MatFinale.
%
% INPUT:
%   - MatFinale         : volume binario (yDim x xDim x zDim) già inizializzato/accumulato
%   - Minv              : volume invertito (stesse dimensioni di Mn), già mascherato
%   - indiciPalmoNoPelle: matrice (yDim x xDim) di indici z della superficie palmo (senza pelle)
%   - fine, inizio      : intervallo di profondità "virtuale" da iterare
%   - sogliaIniziale    : soglia al primo step
%   - sogliaFinale      : soglia all'ultimo step
%   - xDim              : dimensione lungo x (numero colonne)
%   - y                 : indice della riga/slice su cui lavorare (piano XZ fissato)
%
% OUTPUT:
%   - MatFinale         : volume binario aggiornato con i voxel che superano la soglia

    % Numero di iterazioni del loop (serve per normalizzare t)
    n_iterazioni = fine - inizio + 1;

    % Estrae la sezione XZ corrispondente alla riga y:
    % Minv(y,:,:) ha dimensione 1 x xDim x zDim
    % squeeze -> xDim x zDim
    % trasposta -> zDim x xDim, così si indicizza come pianoXZ(z,x)
    pianoXZ = squeeze(Minv(y, :, :))';

    % Scorre la profondità "virtuale" zplane
    for zplane = inizio:fine

        % Calcolo parametro t in [0,1] per interpolare la soglia
        t = (zplane - inizio) / (n_iterazioni - 1);

        % Soglia incrementale con andamento quadratico
        soglia = sogliaIniziale + t^2 * (sogliaFinale - sogliaIniziale);

        % Shift degli indici del palmo per campionare progressivamente "più in profondità"
        indici_nnzMNP = indiciPalmoNoPelle - zplane;

        % Campiona i voxel della sola riga y su tutte le x:
        % voxelM(1,x) prende Minv(y,x,indice_z) ma usando il piano XZ già estratto
        voxelM = zeros(1, xDim);
        for x = 1:xDim
            indice_z = indici_nnzMNP(y, x);
            if indice_z > 0
                % pianoXZ è indicizzato come (z,x)
                voxelM(1, x) = pianoXZ(indice_z, x);
            end
        end

        % Binarizzazione dei voxel campionati sul piano XZ con soglia corrente
        voxelM_bin = voxelM > soglia;

        % Scrive nel volume 3D finale: se voxel supera soglia, attivo il voxel corrispondente
        for x = 1:xDim
            if voxelM_bin(1, x)
                MatFinale(y, x, indici_nnzMNP(y, x)) = true;
            end
        end
    end
end

function [volBin] = binIncrementale(Mn, mascheraNeroTotale, indiciPalmoNoPelle, ...
                                    fine, sogliaIniziale, sogliaFinale)
% BININCREMENTALE Binarizzazione 3D "incrementale" lungo la profondità:
% per ciascun "piano" zplane (da 1 a fine) estrae, per ogni (y,x), un voxel
% del volume in corrispondenza di un indice di profondità derivato da
% indiciPalmoNoPelle, applica una soglia che varia progressivamente con zplane,
% e scrive nel volume binario finale solo i voxel che superano la soglia.
%
% INPUT:
%   - Mn                : volume originale (yDim x xDim x zDim), tipicamente uint8 [0..255]
%   - mascheraNeroTotale: maschera booleana (stesse dimensioni di Mn o compatibile)
%                         dei voxel da azzerare (zone inutili/rumore/nero)
%   - indiciPalmoNoPelle: matrice (yDim x xDim) di indici di profondità (z)
%                         associati alla superficie/struttura del palmo "senza pelle"
%   - fine              : numero massimo di iterazioni/piani considerati (depth step)
%   - sogliaIniziale    : soglia usata all'inizio (zplane=inizio)
%   - sogliaFinale      : soglia usata alla fine (zplane=fine)
%
% OUTPUT:
%   - volBin            : volume binario (yDim x xDim x zDim) con i voxel selezionati

    % Dimensioni del volume (attenzione: qui yDim = size(Mn,1), xDim = size(Mn,2))
    xDim = size(Mn,2);
    yDim = size(Mn,1);
    zDim = size(Mn,3);

    % Inversione intensità: rende "alte" le zone scure (utile se le vene sono più scure)
    Minv = 255 - Mn;

    % Azzeramento dei voxel in maschera nera totale (esclusione regioni non valide)
    Minv(mascheraNeroTotale) = 0;
    % volshow(Minv); % debug opzionale

    % Volume binario finale inizializzato a false
    MatFinale = false(yDim, xDim, zDim);

    % Intervallo di iterazione lungo zplane
    inizio = 1;
    n_iterazioni = fine - inizio + 1;

    % Scorre una profondità "virtuale" zplane da 1 a fine
    for zplane = inizio:fine

        % Calcolo del parametro normalizzato t in [0,1]
        % (serve per interpolare la soglia tra iniziale e finale)
        t = (zplane - inizio) / (n_iterazioni - 1);

        % Soglia incrementale non lineare (quadratica):
        % cresce (o decresce) più lentamente all'inizio e più velocemente verso la fine
        soglia = sogliaIniziale + t^2 * (sogliaFinale - sogliaIniziale);

        % Shift degli indici di profondità:
        % per ogni (y,x) "sposto" l'indice del palmo di zplane verso l'interno
        % (idea: campionare voxel a profondità crescente rispetto alla superficie palmo)
        indici_nnzMNP = indiciPalmoNoPelle - zplane;

        % voxelM conterrà, per ogni (y,x), l'intensità campionata a profondità indice_z
        voxelM = zeros(yDim, xDim);

        % Estrazione del voxel (y,x,indice_z) per ogni punto valido (indice_z > 0)
        for y = 1:yDim
            for x = 1:xDim
                indice_z = indici_nnzMNP(y, x);
                if indice_z > 0
                    voxelM(y, x) = Minv(y, x, indice_z);
                end
            end
        end

        % Binarizzazione 2D del piano campionato con la soglia corrente
        voxelM_bin = voxelM > soglia;

        % Riporta i pixel veri nel volume 3D finale, nella posizione (y,x,indice_z)
        for y = 1:yDim
            for x = 1:xDim
                if voxelM_bin(y, x)
                    MatFinale(y, x, indici_nnzMNP(y, x)) = true;
                end
            end
        end

        % fprintf('Iterazione %d: soglia = %.4f\n', zplane, soglia); % debug
    end

    % Output: volume binario costruito accumulando voxel sogliati lungo le iterazioni
    volBin = MatFinale;
end

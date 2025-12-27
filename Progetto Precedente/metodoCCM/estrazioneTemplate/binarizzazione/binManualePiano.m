function [MatFinale] = binManualePiano(MatFinale, Minv, indiciPalmoNoPelle, fine, inizio, soglia, xDim, y)
%BINMANUALEPIANO Binarizza (segmenta) un singolo piano XZ del volume per una y fissata,
% selezionando voxel in una fascia di profondità relativa rispetto alla superficie del palmo.
%
% Idea:
% - Minv è il volume di intensità (già invertito e mascherato) in coordinate (y,x,z).
% - indiciPalmoNoPelle(y,x) fornisce, per ogni colonna x, l'indice z della superficie del palmo
%   (senza pelle) nel piano corrispondente a y.
% - Scorro una profondità relativa zplane = inizio:fine: per ogni x prendo il voxel
%   a quota assoluta (indiciPalmoNoPelle(y,x) - zplane). Questo equivale a campionare
%   "zplane slice sotto la superficie".
% - Se il voxel campionato supera una soglia, lo marco come true in MatFinale
%   nella stessa posizione (y,x,z).
%
% Input:
%   MatFinale         : volume binario (logical) già allocato, in cui scrivere il risultato
%   Minv              : volume di intensità invertito (255 - Mn), con zone non valide già a 0
%   indiciPalmoNoPelle: mappa 2D (y,x) di indici z della superficie del palmo
%   fine, inizio      : intervallo di profondità relativa (in slice) da considerare sotto la superficie
%   soglia            : soglia di intensità per decidere se un voxel è "vena/struttura" (true)
%   xDim              : numero di colonne x del piano
%   y                 : indice del piano (riga y) che sto processando
%
% Output:
%   MatFinale         : MatFinale aggiornato con i voxel binarizzati nel piano y

    % Estrae il piano XZ corrispondente a questa y:
    % squeeze(Minv(y,:,:)) -> matrice [x,z], poi trasposto -> [z,x]
    % (così l'indice z è sulla prima dimensione, più comodo per l'accesso pianoXZ(indice_z,x)).
    pianoXZ = squeeze(Minv(y, :, :))';

    % Scorro la profondità relativa rispetto alla superficie (inizio..fine)
    for zplane = inizio:fine

        % Per questo offset relativo zplane, calcolo la quota assoluta da campionare:
        % indiciPNPzplane(y,x) = indiciPalmoNoPelle(y,x) - zplane.
        % (La variabile contiene la mappa completa y-x, ma sotto userò solo la riga y.)
        indiciPNPzplane = indiciPalmoNoPelle - zplane;

        % Campiono, per ogni x, il voxel del piano XZ alla quota calcolata.
        % Se l'indice va fuori volume (<=0), lascio 0 (come se fosse background).
        rigaVoxelPiano = zeros(1, xDim);
        for x = 1:xDim
            indice_z = indiciPNPzplane(y, x);
            if indice_z > 0
                rigaVoxelPiano(1, x) = pianoXZ(indice_z, x);
            end
        end

        % Binarizzo la riga campionata: true dove l'intensità supera la soglia scelta.
        rigaVoxelPiano_bin = rigaVoxelPiano > soglia;

        % Riporto i true nel volume binario 3D, nella posizione (y,x,indice_z) corrispondente.
        for x = 1:xDim
            if rigaVoxelPiano_bin(1, x)
                MatFinale(y, x, indiciPNPzplane(y, x)) = true;
            end
        end
    end

end

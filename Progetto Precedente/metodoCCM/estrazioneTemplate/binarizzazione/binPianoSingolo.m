function [pianoFinale] = binPianoSingolo(inizio,fine,pianoXZ,indiciPalmoNoPelle,xDim,zDim)
%BINPIANOSINGOLO Binarizza un singolo piano XZ (per una y fissata) in modo
% "allineato" alla superficie del palmo.
%
% Idea:
% - indiciPalmoNoPelle(x) indica, per ogni colonna x, la quota (indice z) della
%   superficie del palmo (senza pelle).
% - Scorro una profondità relativa z = inizio:fine misurata a partire dalla superficie:
%   per ogni x prelevo il pixel a quota (indiciPalmoNoPelle(x) - z) nel piano XZ.
% - Applico una soglia molto alta (soglia=254) sul valore prelevato:
%   se supera la soglia, segno come true quel voxel nella stessa posizione del volume.
%
% Input:
%   inizio,fine           : intervallo di profondità relativa (in "slice") sotto la superficie
%   pianoXZ               : matrice [zDim x xDim] (intensità)
%   indiciPalmoNoPelle    : vettore 1×xDim con indice z della superficie (per ogni x)
%   xDim, zDim            : dimensioni del piano (colonne x e righe z)
%
% Output:
%   pianoFinale           : maschera logica [zDim x xDim] con i voxel selezionati (true)
%
% Nota: questa funzione NON restituisce un'immagine 0/255, ma una maschera logica.

    % Soglia di binarizzazione (molto alta): seleziona solo i pixel quasi saturi.
    % Con Mn invertito (Minv = 255 - Mn) questo equivale a prendere i punti molto "forti".
    soglia = 254;

    % Inizializzo la maschera di output (tutto falso)
    pianoFinale = false(zDim, xDim);

    % Scorro la profondità relativa rispetto alla superficie: z = 1 significa 1 slice sotto la superficie,
    % z = 2 significa 2 slice sotto, ecc. (secondo la convenzione indiciPalmoNoPelle - z).
    for z = inizio:fine

        % rigaInv conterrà, per ogni x, il valore di intensità campionato a quota (indiciPalmoNoPelle(x) - z).
        % Se l'indice va fuori volume (<=0) lascio 0.
        rigaInv = zeros(1, xDim);

        for x = 1:xDim
            % Convertendo la profondità relativa z in indice assoluto lungo il piano:
            indice_z = indiciPalmoNoPelle(x) - z;

            % Controllo limite superiore (>=1) per evitare accessi fuori matrice
            if indice_z > 0
                rigaInv(1, x) = pianoXZ(indice_z, x);
            end
        end

        % Binarizzo la riga campionata: true dove l'intensità supera la soglia
        riga_bin = rigaInv > soglia;

        % Riporto i true nella posizione originale del piano (stessa quota indice_z)
        for x = 1:xDim
            if riga_bin(1, x)
                pianoFinale(indiciPalmoNoPelle(x) - z, x) = true;
            end
        end

    end

end

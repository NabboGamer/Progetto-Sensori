function [V] = tagliaBordi(V)
%TAGLIABORDI Smussa/taglia i bordi del volume azzerando i voxel in prossimità
%degli angoli (in pianta XY) per ogni slice lungo Z.
%
% La funzione applica quattro condizioni lineari sul piano (x,y) che
% identificano quattro regioni triangolari agli angoli dell'immagine:
% alto-sinistra, basso-sinistra, alto-destra, basso-destra. Tutti i voxel
% appartenenti a tali regioni vengono posti a 0, per ogni z.
%
% INPUT:
%   V : volume 3D (Y x X x Z). Può essere logico o numerico.
%
% OUTPUT:
%   V : volume 3D con gli angoli (in XY) azzerati su tutte le slice Z.
%
% NOTE:
%   - Lo "spessore" controlla quanto viene tagliato/smussato.
%   - L'operazione non dipende da z: la stessa maschera XY è applicata a
%     tutte le slice.

    % Definiamo lo spessore per il taglio degli angoli (ampiezza dello smusso)
    spessore = 180;  % Modifica questo valore per regolare il taglio

    % Iteriamo su ogni voxel del volume
    for z = 1:size(V, 3)      % dimensione Z (slice)
        for x = 1:size(V, 2)  % dimensione X (colonne)
            for y = 1:size(V, 1)  % dimensione Y (righe)

                % Smussa/taglia l'angolo in alto a sinistra:
                % condizione sotto la diagonale x+y = spessore
                if (x + y < spessore)
                    V(y, x, z) = 0;
                end

                % Smussa/taglia l'angolo in basso a sinistra:
                % regione "sopra" la retta y - x = (Y - spessore)
                if (y - x > size(V, 1) - spessore)
                    V(y, x, z) = 0;
                end

                % Smussa/taglia l'angolo in alto a destra:
                % regione "a destra" della retta x - y = (X - spessore)
                if (x - y > size(V, 2) - spessore)
                    V(y, x, z) = 0;
                end

                % Smussa/taglia l'angolo in basso a destra:
                % regione oltre la retta x + y = (2*Y - spessore)
                % (nota: qui si usa size(V,1) due volte, quindi la formula dipende da Y)
                if (x + y > (2 * size(V, 1)) - spessore)
                    V(y, x, z) = 0;
                end
            end
        end
    end
end

function diameter = getDiameter(moving, ydim)
%GETDIAMETER Stima un diametro caratteristico (EquivDiameter) da una slice del volume.
%
%   Questa funzione MATLAB stima un diametro rappresentativo
%   della struttura principale presente nel volume 3D MOVING. La stima viene
%   ottenuta estraendo un piano XZ (slice su asse Y) in una posizione scelta
%   vicino al centroide della componente connessa principale e calcolando
%   l'EquivDiameter delle componenti 2D presenti su quel piano.
%
%   Procedura:
%     1) Identifica la componente connessa principale nel volume (massimo Volume).
%     2) Ricava centroide e PrincipalAxisLength lungo Y della componente.
%     3) Seleziona una coordinata Y spostata di +/- (PrincipalAxisLength/4)
%        rispetto al centroide (per evitare sezioni "povere" o borderline).
%     4) Estrae la slice moving(y,:,:) e verifica che non sia vuota (nnz>0);
%        in caso contrario prova posizioni alternative (y - delta, poi centroide).
%     5) Sul piano 2D calcola l'EquivDiameter delle componenti connesse e
%        restituisce la media dei diametri equivalenti.
%
%   Input:
%     moving - Volume 3D (preferibilmente logico o 0/1) contenente la struttura.
%     ydim   - Dimensione lungo asse Y (tipicamente size(moving,1)), usata per
%              garantire che l'indice di slice resti nei limiti.
%
%   Output:
%     diameter - Diametro equivalente medio (in pixel) delle componenti 2D nella slice scelta.
%
%   Note:
%     - La slice viene trasposta con (') per mantenere una convenzione coerente
%       di orientamento (dipende da come sono organizzati gli assi nel volume).
%     - Se nella slice selezionata non ci sono voxel attivi, la funzione tenta
%       automaticamente slice alternative per evitare diametro non definito.


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1) Trova la componente connessa principale nel volume MOVING        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    CC_m = bwconncomp(moving);
    stats_m = regionprops3(CC_m, 'Volume', 'Centroid', 'PrincipalAxisLength');
    [~, idxMax] = max(stats_m.Volume);

    % Centroide (coordinate in forma [Y, X, Z] secondo regionprops3).
    cord_y_cent = round(stats_m.Centroid(idxMax, 1));

    % Lunghezza dell'asse principale lungo Y (prima componente di PrincipalAxisLength).
    y_length = stats_m.PrincipalAxisLength(idxMax, 1);

    % Spostamento rispetto al centroide per scegliere una slice "significativa".
    delta = y_length / 4;
    y = round(cord_y_cent + delta);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2) Controllo limiti: la slice deve restare in [1, ydim]             %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if y > ydim
        y = round(cord_y_cent - delta);
        if y < 1
            y = cord_y_cent;
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3) Estrazione del piano XZ alla quota Y selezionata e verifica non-vuoto %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    piano = squeeze(moving(y, :, :))';  % slice 2D (XZ) e trasposizione

    % Se il piano è vuoto, prova alternative: y - delta, poi il centroide.
    if nnz(piano) == 0
        y = round(cord_y_cent - delta);
        piano = squeeze(moving(y, :, :))';
        if nnz(piano) == 0
            y = cord_y_cent;
            piano = squeeze(moving(y, :, :))';
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 4) Diametro equivalente 2D e output
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    cc = bwconncomp(piano);
    stats = regionprops(cc, 'EquivDiameter');

    % Media degli EquivDiameter (se più componenti sono presenti nella slice).
    diameter = mean([stats.EquivDiameter]);
end

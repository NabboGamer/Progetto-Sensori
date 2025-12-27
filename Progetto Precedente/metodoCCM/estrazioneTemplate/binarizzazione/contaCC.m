function [numCC, pianoCCvalide] = contaCC(pianoFinaleBin, y)
%CONTACC Conta le componenti connesse (Connected Components, CC) in un piano binario
% e filtra quelle troppo piccole.
%
% Input:
%   pianoFinaleBin : immagine binaria (tipicamente uint8 0/255 oppure logical) del piano XZ
%   y              : indice del piano (usato solo per eventuali funzioni di debug/plot)
%
% Output:
%   numCC          : numero di componenti connesse "valide" dopo il filtraggio per area
%   pianoCCvalide  : maschera binaria che contiene solo le componenti con area > soglia
%
% Pipeline:
% 1) Trovo tutte le componenti connesse presenti nell'immagine binaria.
% 2) Calcolo l'area di ogni componente e tengo solo quelle con Area > 20 pixel.
% 3) Ricostruisco un'immagine binaria che contiene solo le componenti selezionate.
% 4) Ricalcolo le CC sul risultato filtrato e conto quante sono (tramite i centroidi).

    % Trova le componenti connesse nel piano binario (connettività standard di bwconncomp)
    CC = bwconncomp(pianoFinaleBin);

    % Calcola proprietà (Area) per ogni componente
    structCC = regionprops(CC, 'Area');

    % Converte l'output di bwconncomp in una label image:
    % L contiene l'etichetta intera della componente per ogni pixel (0 = background)
    L = labelmatrix(CC);

    % Seleziono solo le componenti con area sufficientemente grande (rimozione rumore)
    areeValide = find([structCC.Area] > 20);

    % Creo una maschera binaria che contiene solo le componenti con etichetta in areeValide
    pianoCCvalide = ismember(L, areeValide);

    % (Debug opzionale) visualizzazione del piano filtrato
    % visualizzaPianoXZ(pianoCCvalide, y, 1);

    % Ricalcolo le componenti connesse dopo il filtraggio
    CC_filt = bwconncomp(pianoCCvalide);

    % Estraggo i centroidi delle componenti filtrate (una riga per componente)
    tab_filt = struct2table(regionprops(CC_filt, 'Centroid'));

    % Il numero di componenti valide è il numero di centroidi trovati
    numCC = height(tab_filt);

    % Converto i centroidi in matrice Nx2 (se ce ne sono)
    centroids = cat(1, tab_filt.Centroid);

    % (Debug opzionale) visualizzazione dei centroidi sul piano originale
    if ~isempty(centroids)
        % visualizzaCentroidi(pianoFinaleBin, y, centroids, 0);
    end

end

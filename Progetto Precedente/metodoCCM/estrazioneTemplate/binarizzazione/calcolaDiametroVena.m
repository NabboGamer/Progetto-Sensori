function [diametro] = calcolaDiametroVena(pianoCCvalide, pianoPalmo, y)
% calcolaDiametroVena Stima il diametro della vena "più plausibile" tra le
% componenti connesse presenti in una slice, selezionando la componente più 
% vicina al palmo e filtrando per forma/dimensione.
%
% INPUT:
%   - pianoCCvalide : immagine binaria (ZxX) con le regioni candidate (vene) già validate
%   - pianoPalmo    : matrice (ZxX) che rappresenta il "profilo" del palmo (non-zero = palmo)
%   - y             : indice/slice (usato solo per eventuale visualizzazione/debug)
%
% OUTPUT:
%   - diametro      : diametro equivalente (EquivDiameter) della vena selezionata.
%                     NaN se nessuna vena valida viene trovata.

    % Valore di default: se non trovo una vena accettabile, resto a NaN
    diametro = NaN;

    % Trova le componenti connesse (regioni) nel piano binario delle candidate
    CC = bwconncomp(pianoCCvalide);

    % Estrae proprietà geometriche utili per ogni regione candidata
    % - Area: area in pixel
    % - EquivDiameter: diametro del cerchio con la stessa area (stima "robusta" della dimensione)
    % - Circularity: misura di quanto la forma è simile a un cerchio (0..1 circa)
    % - Centroid: centroide (x,z) della regione
    structCC = regionprops(CC, 'Area','EquivDiameter','Circularity','Centroid');

    % Converte la struct array in tabella per indicizzazioni più comode
    tabellaCC = struct2table(structCC);

    % Estrae tutti i centroidi in una matrice N x 2 (colonna 1 = x, colonna 2 = z)
    centroids = cat(1, tabellaCC.Centroid);

    % Se ho almeno una componente candidata
    if ~isempty(centroids)
        % Debug opzionale: mostra centroidi sulla slice (commentato)
        % visualizzaCentroidi(pianoCCvalide, y, centroids, 0);

        % Coordinate dei centroidi (arrotondate a pixel intero)
        % Nota: regionprops usa [x, y] -> qui la seconda coordinata è la "z" del tuo piano
        cordZcentroid = round(tabellaCC.Centroid(:,2))';
        cordXcentroid = round(tabellaCC.Centroid(:,1))';

        % Per ogni colonna X, trova la prima posizione Z (lungo righe) in cui il palmo è presente
        % max(...,[],1) restituisce anche l'indice della prima occorrenza del massimo (true=1)
        % -> cordZpalm(x) è la "quota" del palmo per quella colonna x
        [~, cordZpalm] = max(pianoPalmo ~= 0, [], 1);

        % Campiona la quota del palmo alle sole X dei centroidi delle vene candidate
        cordZpalmCentroid = cordZpalm(cordXcentroid);

        % Distanza (in pixel) tra palmo e centroide: più piccola => più vicino al palmo
        % (Attenzione: se la convenzione z cresce verso il basso, questo valore cambia segno/logica)
        distanzeCentroidPalmo = cordZpalmCentroid - cordZcentroid;

        % Seleziona la componente il cui centroide è "più vicino" al palmo
        % (min della distanza definita sopra)
        [~, idVena] = min(distanzeCentroidPalmo);

        % Estraggo la riga corrispondente alla vena selezionata
        vena = tabellaCC(idVena, :);

        % Filtro di plausibilità:
        % - EquivDiameter > 10 px: scarta oggetti troppo piccoli (rumore/artefatti)
        % - Circularity > 0.5: scarta forme troppo allungate/frastagliate
        if vena.EquivDiameter(1) > 10 && vena.Circularity(1) > 0.5
            diametro = vena.EquivDiameter(1);
        end
    end
end

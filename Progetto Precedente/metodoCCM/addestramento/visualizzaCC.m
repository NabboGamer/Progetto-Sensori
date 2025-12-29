function visualizzaCC(CC,volume,i)
%VISUALIZZACC Visualizza a schermo la proiezione 2D (XY) del volume e della i-esima componente connessa.
%
%   La funzione crea una figura a schermo intero con due subplot affiancati:
%     (1) Proiezione massima lungo Z del volume originale (piano XY).
%     (2) Proiezione massima lungo Z della sola i-esima componente connessa
%         estratta da CC.PixelIdxList{i}.
%   In entrambe le visualizzazioni viene applicato un flip lungo X (seconda
%   dimensione) per mantenere una convenzione di orientamento coerente.
%
%   INPUT
%     CC      Struttura restituita da bwconncomp, contenente PixelIdxList
%             (lista di voxel per ciascuna componente connessa).
%     volume  Volume 3D (tipicamente binario o intensità) da cui derivano le CC.
%     i       Indice della componente connessa da visualizzare (1 <= i <= CC.NumObjects).
%
%   NOTE
%   - La proiezione massima lungo Z è calcolata con:
%         max(volume, [], 3)
%     e produce una mappa 2D sul piano XY.
%   - Per la componente i-esima, viene costruito un volume logico component_i
%     con voxel veri solo nella CC selezionata.
%   - imagesc viene usato per mostrare le proiezioni; axis equal mantiene le
%     proporzioni corrette; colormap(gray) usa scala di grigi.

    % Crea una nuova figura
    figure;

    % Imposta la figura a schermo intero
    set(gcf, 'Position', get(0, 'Screensize'));

    %% --- 1) Proiezione del volume originale sul piano XY (max lungo Z) ---
    subplot(1, 2, 1); % 1 riga, 2 colonne, primo pannello

    % Proiezione massima lungo Z (ottengo una mappa 2D XY)
    projection_volume = max(volume, [], 3);

    % Specchia lungo X (seconda dimensione) per convenzione di orientamento
    projection_volume = flip(projection_volume, 2);

    % Visualizza la proiezione
    imagesc(projection_volume);
    title('Proiezione Volume Originale (XY)');
    axis equal;
    xlabel('X');
    ylabel('Y');
    colormap(gray);

    %% --- 2) Proiezione della i-esima componente connessa sul piano XY ---
    subplot(1, 2, 2); % secondo pannello

    % Costruisce un volume logico contenente solo la componente i-esima
    component_i = false(size(volume));
    component_i(CC.PixelIdxList{i}) = true;

    % Proiezione massima lungo Z della sola componente
    projection_component = max(component_i, [], 3);

    % Specchia lungo X (seconda dimensione) per coerenza con la prima vista
    projection_component = flip(projection_component, 2);

    % Visualizza la proiezione della componente
    imagesc(projection_component);
    title(['Proiezione Componente ', num2str(i), ' (XY)']);
    axis equal;
    xlabel('X');
    ylabel('Y');
    colormap(gray);

    % Titolo generale della figura
    sgtitle('Proiezioni sul Piano XY del Volume e della Componente Estratta');
end

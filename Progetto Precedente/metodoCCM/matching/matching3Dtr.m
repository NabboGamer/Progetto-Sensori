function score = matching3Dtr(fixed, moving)
%MATCHING3DTR Score di matching 3D (traslazione + rotazione) tra due volumi binari.
%
%   Questa funzione MATLAB calcola uno score di sovrapposizione
%   tra due volumi 3D (tipicamente binari/logici): FIXED rimane fermo, mentre
%   MOVING viene prima riallineato con una stima "rigida" (rotazione + traslazione)
%   e, se necessario, con una ricerca iterativa su combinazioni discrete di
%   traslazione e rotazione.
%
%   Strategia:
%     1) Allineamento "veloce":
%        - Seleziona la componente connessa principale di FIXED.
%        - In MOVING seleziona la componente con centroide più vicino a quello di FIXED.
%        - Stima una rotazione (da Orientation) e una traslazione (da differenza centroidi).
%        - Calcola lo score; se SCORE > 0.4 termina subito.
%     2) Ricerca iterativa:
%        - Prova combinazioni di traslazione (griglia discreta) e 7 rotazioni base
%          definite in R, con passo angolare DEG.
%        - Restituisce lo score migliore tra il punto 1) e il punto 2).
%
%   Il codice utilizza gpuArray per accelerare rotazione/traslazioni/score (richiede
%   Parallel Computing Toolbox e una GPU supportata ovvero GPU NVIDIA).
%
%   Input:
%     fixed  - Volume 3D (preferibilmente logico o 0/1) di riferimento.
%     moving - Volume 3D (preferibilmente logico o 0/1) da riallineare.
%
%   Output:
%     score  - Score finale (massimo tra score "veloce" e score iterativo).
% 
%   Note implementative:
%     - circshift usa ordine [righe, colonne, pagine] = [Y, X, Z]. Qui la traslazione
%       viene applicata come [t(2), t(1), t(3)] per allineare X/Y correttamente.
%     - Il padding viene usato per evitare "tagli" durante shift/rotazioni.
%
%   See also getDiameter, rotTemplate, computeScore, inizializzaCombinazioni, scoreTransRot.

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1) Estrazione componenti connesse + scelta dei centroidi da confrontare %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Trova componenti in FIXED e seleziona quella di volume massimo (componente principale).
    CC_f = bwconncomp(fixed);
    stats_f = regionprops3(CC_f, 'Volume', 'Centroid', 'Orientation');
    [~, idxMax] = max(stats_f.Volume);
    centroids_f = stats_f.Centroid(idxMax, :);

    % Trova componenti in MOVING e seleziona quella col centroide più vicino a FIXED.
    CC_m = bwconncomp(moving);
    stats_m = regionprops3(CC_m, 'Volume', 'Centroid', 'Orientation');
    centroids_m = stats_m.Centroid;

    distances = sqrt(sum((centroids_m - centroids_f).^2, 2));
    [~, idxNearest] = min(distances);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 2) Padding iniziale "minimo" in base alla traslazione stimata (centroidi) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    trans_diff = centroids_f - centroids_m(idxNearest, :);  % differenza centroidi (FIXED - MOVING)
    pad = ceil(abs(max(trans_diff)));                       % padding sufficiente a contenere lo shift stimato

    fixed  = padarray(fixed,  [pad, pad, pad], 0, 'both');
    moving = padarray(moving, [pad, pad, pad], 0, 'both');

    % Porta i volumi su GPU (operazioni successive accelerabili).
    moving_gpu = gpuArray(moving);
    fixed_gpu  = gpuArray(fixed);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 3) Allineamento "veloce": rotazione da Orientation + traslazione da centroidi %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    diameter = getDiameter(moving, size(moving, 1));  % diametro/scala caratteristica del template
    range    = round(diameter * 2);                   % raggio di ricerca/limite (euristico)
    step     = round(range / 3);                      % passo (euristico) per combinazioni traslazione

    score_c = 0;  % score del metodo "veloce" (c = coarse/centrale)

    % Se la traslazione stimata è "ragionevole" rispetto al range, prova l'allineamento diretto.
    if max(abs(trans_diff)) < range

        % Orientazioni stimate (da regionprops3): usate per ruotare MOVING verso FIXED.
        orientation_f = stats_f.Orientation(idxMax, :);
        orientation_m = stats_m.Orientation(idxNearest, :);

        % Rotazione del template moving per allineare orientazione.
        movingRot = rotTemplate(moving_gpu, orientation_f, orientation_m);
        
        % circshift accetta shift interi (numero di voxel/pixel)
        t = round(trans_diff);
        
        % Traslazione: circshift su GPU.
        % ATTENZIONE ordine assi: circshift([Y, X, Z]) => [t(2), t(1), t(3)].
        movingTrans_gpu = circshift(movingRot, [t(2), t(1), t(3)]);

        % Calcolo score su GPU e ritorno su CPU.
        score_gpu = computeScore(fixed_gpu, movingTrans_gpu);
        score_c   = gather(score_gpu);

        % Soglia di "buon match": se superata, termina subito.
        if score_c > 0.4
            score = score_c;
            return
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 4) Metodo iterativo: combinazioni di traslazione + set discreto di rotazioni %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Passo angolare (euristico) derivato dal diametro del template.
    deg = round(diameter / 10);

    % Padding più ampio per consentire la ricerca locale entro "range".
    fixed  = padarray(fixed,  [range, range, range], 0, 'both');
    moving = padarray(moving, [range, range, range], 0, 'both');

    % Inizializza combinazioni traslazione (tipicamente una griglia 7x7x7 = 343).
    T = inizializzaCombinazioni(range, step);

    % Set di 7 direzioni/assi base per rotazioni discrete (in combinazione con DEG).
    R = [ 0, 0, 0;
          1, 0, 0;
          0, 1, 0;
          0, 0, 1;
         -1, 0, 0;
          0,-1, 0;
          0, 0,-1];

    % Sposta su GPU (di nuovo, perché fixed/moving sono stati ripaddati su CPU).
    fixed_gpu  = gpuArray(fixed);
    moving_gpu = gpuArray(moving);

    % Ricerca del miglior score su combinazioni traslazione (T) e rotazione (R, deg).
    score_i = scoreTransRot(fixed_gpu, moving_gpu, T, R, deg);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 5) Output: massimo tra score "veloce" e score iterativo
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    score = max([score_c, score_i]);
end

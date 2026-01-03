function [score] = scoreTransRot(fixed_gpu,moving_gpu,T,R,deg)
%%SCORETRANSROT Cerca la migliore traslazione e rotazione (su GPU) massimizzando uno score di overlap.
%
%   Esegue una ricerca "a griglia" in due fasi:
%     1) Prova tutte le traslazioni (circshift) elencate in T, calcola lo score
%        per ciascuna e seleziona la traslazione che massimizza lo score.
%     2) A partire dal volume traslato migliore, prova tutte le rotazioni
%        definite dalle direzioni/assi in R (usando un angolo fisso deg),
%        calcola lo score e restituisce lo score massimo ottenuto.
%
%   INPUT:
%     fixed_gpu   - Volume 3D di riferimento su GPU (gpuArray).
%     moving_gpu  - Volume 3D da trasformare su GPU (gpuArray).
%     T           - Matrice (Nt x 3) di traslazioni da provare. Ogni riga è
%                   [s1 s2 s3] per circshift, cioè shift sulle dimensioni
%                   dell'array: [dim1 dim2 dim3] (spesso [Y X Z]).
%     R           - Matrice (Nr x 3) di assi/direzioni di rotazione da provare.
%                   Ogni riga è un vettore direzione (es. [1 0 0], [0 1 0], [0 0 1]).
%     deg         - Angolo (in gradi) applicato ad ogni rotazione (sempre lo stesso).
%
%   OUTPUT:
%     score       - Valore massimo dello score ottenuto dopo la fase di rotazione
%                   (quindi migliore combinazione: best traslazione + best rotazione).

    %% FASE 1: TRASLAZIONE (ricerca esaustiva tra le righe di T)
    niter_t = size(T,1);                     % numero di traslazioni candidate
    scores_gpu = gpuArray.zeros(niter_t, 1); % preallocazione su GPU

    for i = 1:niter_t
        % Applica la traslazione i-esima (shift sulle 3 dimensioni dell'array)
        movingTrans_gpu = circshift(moving_gpu, T(i,:));

        % Calcola lo score di overlap tra fixed e moving traslato
        scores_gpu(i) = computeScore(fixed_gpu, movingTrans_gpu);
    end

    % Riporta su CPU per trovare il massimo (max su CPU per semplicità)
    scores = gather(scores_gpu);
    [~, idMaxScore] = max(scores);

    % Applica definitivamente la migliore traslazione trovata
    moving_gpu_t = circshift(moving_gpu, T(idMaxScore,:));

    %% FASE 2: ROTAZIONE (ricerca esaustiva tra le righe di R)
    niter_r = size(R,1);                     % numero di assi/direzioni candidate
    scores_gpu = gpuArray.zeros(niter_r, 1); % reset preallocazione

    for i = 1:niter_r
        % Ruota il volume (già traslato) di "deg" gradi attorno all'asse R(i,:)
        % 'crop' mantiene le dimensioni del volume.
        movingRot_gpu = imrotate3(moving_gpu_t, deg, R(i,:), "crop");

        % Score dopo rotazione
        scores_gpu(i) = computeScore(fixed_gpu, movingRot_gpu);
    end

    % Seleziona lo score massimo tra le rotazioni provate
    scores = gather(scores_gpu);
    [score, idMax] = max(scores);

    % ---- Debug/Verifica ----
    % movingRot_gpu = imrotate3(moving_gpu_t, deg, R(idMax,:), "crop");
    % movingRot = gather(movingRot_gpu);
    % fixed = gather(fixed_gpu);
    % confrontaVolumi(fixed, movingRot);

end

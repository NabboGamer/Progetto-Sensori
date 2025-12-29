function [vecDiamFilt] = calcolaFeaturesFilling(volume)
%CALCOLAFEATURESFILLING Calcola una feature di "diametro medio" per slice (piani XZ) utile al filling.
%
%   La funzione scorre le slice lungo Y (piani XZ) di un volume binario/logico e,
%   per ogni piano non vuoto:
%     1) riempie eventuali buchi (imfill),
%     2) trova le componenti connesse 2D (bwconncomp),
%     3) calcola l'EquivDiameter di ciascuna CC (regionprops),
%     4) salva nel vettore vecDiam(y) la media dei diametri equivalenti del piano.
%
%   Alla fine rimuove i valori NaN (slice vuote) e restituisce un vettore compatto
%   contenente solo le stime valide.
%
%   INPUT
%     volume      Volume 3D binario/logico (tipicamente una singola vena o una CC).
%
%   OUTPUT
%     vecDiamFilt Vettore 1D contenente, per ciascun piano XZ "non vuoto", la media
%                 dell'EquivDiameter delle CC presenti su quel piano.
%                 (Le slice vuote vengono escluse).
%
%   NOTE
%   - Lavoro per slice Y in parallelo (parfor) perché i piani sono indipendenti.
%   - L'uso di squeeze(volume(y,:,:))' implica una convenzione di orientamento:
%     si trasporta il piano per ottenere una vista XZ coerente con il resto del progetto.
%   - EquivDiameter è il diametro della circonferenza con area equivalente alla CC,
%     quindi è una proxy dello "spessore"/dimensione trasversale delle strutture.

    % Numero di slice lungo Y
    yDim = size(volume,1);

    % Vettore diametri: inizialmente NaN per identificare slice vuote
    vecDiam = nan(1,yDim);

    %% --- Loop (parallelo) sulle slice Y ---
    parfor y = 1:yDim
        % Estrae il piano XZ alla coordinata y (trasposto per convenzione)
        piano = squeeze(volume(y,:,:))';

        % Considero solo i piani non vuoti
        if nnz(piano) > 0
            % Riempie buchi per rendere le regioni più compatte
            piano = imfill(piano,"holes");

            % Componenti connesse 2D e diametro equivalente
            cc = bwconncomp(piano);
            stats = regionprops(cc, 'EquivDiameter');

            % Media dei diametri equivalenti delle CC nel piano
            vecDiam(y) = mean([stats.EquivDiameter]);
        end
    end

    % Rimuove le slice vuote (NaN) e restituisce solo i valori validi
    vecDiamFilt = vecDiam(~isnan(vecDiam));
end

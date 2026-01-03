function score = computeScore(fixed, moving)
%%COMPUTESCORE Calcola uno score di sovrapposizione tra due volumi binari.
%   score = COMPUTESCORE(fixed, moving)
%
%   Calcola una misura di similarità basata sulla sovrapposizione dei voxel
%   "attivi" (non nulli) tra i due volumi. Lo score è equivalente al
%   coefficiente di Dice:
%
%       score = 2 * |fixed ∩ moving| / (|fixed| + |moving|)
%
%   dove |.| indica il numero di voxel attivi e ∩ indica l'intersezione.
%   Il risultato è in [0, 1] se i volumi sono binari/non negativi:
%     - 0  => nessuna sovrapposizione
%     - 1  => sovrapposizione perfetta
%
%   INPUT:
%     fixed  - Volume 2D/3D (tipicamente logico o numerico). I voxel > 0
%              vengono considerati "attivi".
%     moving - Volume 2D/3D della stessa dimensione di fixed.
%
%   OUTPUT:
%     score  - Valore scalare dello score (Dice).
%
%   NOTE:
%   - fixed & moving esegue una AND logica: è vero dove entrambi sono non zero.
% 

    % Numeratore: conteggio dei voxel in cui entrambi i volumi sono attivi
    % (intersezione).
    num = sum(fixed & moving, 'all');

    % Denominatore: somma dei voxel attivi nei due volumi (aree/volumi totali).
    % Uso >0 per contare come attivi anche input numerici (non solo logical).
    den = sum(fixed > 0, 'all') + sum(moving > 0, 'all');

    % Score normalizzato (Dice): moltiplico per 2 per avere 1 quando combaciano.
    score = (num / den) * 2;
end



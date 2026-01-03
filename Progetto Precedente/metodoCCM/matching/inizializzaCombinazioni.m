function [combinations] = inizializzaCombinazioni(range,step)
%%INIZIALIZZACOMBINAZIONI Genera tutte le combinazioni 3D di traslazioni in un intervallo.
%
%   Crea un vettore di valori equispaziati nell'intervallo [-range, +range]
%   con passo "step" e genera tutte le combinazioni possibili di terne
%   (x, y, z). Ogni riga della matrice di output rappresenta una combinazione.
%
%   INPUT:
%     range - Semilarghezza dell'intervallo (valori da -range a +range).
%     step  - Passo di campionamento (incremento tra valori successivi).
%
%   OUTPUT:
%     combinations - Matrice (N x 3) con tutte le combinazioni:
%                    ogni riga è [v1, v2, v3].
%                    Se vec ha n elementi, allora N = n^3.
%
%   NOTE:
%   - ndgrid genera tre griglie 3D contenenti tutte le terne possibili dei
%     valori di "vec". Con (:) le "srotoliamo" in vettori colonna e poi
%     le affianchiamo per ottenere una lista di combinazioni.

    % Vettore dei valori possibili nell'intervallo [-range, +range]
    vec = -range:step:range;

    % Genera tutte le terne (vec(i), vec(j), vec(k)) usando una griglia 3D.
    % grid1 contiene le componenti lungo la 1ª dimensione, grid2 la 2ª, grid3 la 3ª.
    [grid1, grid2, grid3] = ndgrid(vec, vec, vec);

    % Converte le tre griglie in una lista di terne: ogni riga è una combinazione.
    combinations = [grid1(:), grid2(:), grid3(:)];
end

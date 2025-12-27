function [V] = tagliaBordi(V)

% Definiamo lo spessore per il taglio degli angoli
spessore = 180;  % Cambia questo valore per regolare lo smusso

% Iteriamo su ogni voxel del volume
for z = 1:size(V, 3)  % dimensione Z
    for x = 1:size(V, 2)  % dimensione X
        for y = 1:size(V, 1)  % dimensione Y

            % Smussare l'angolo in alto a sinistra
            if (x + y < spessore)
                V(y, x, z) = 0;
            end

            % Smussare l'angolo in basso a sinistra
            if (y - x > size(V, 1) - spessore)
                V(y, x, z) = 0;
            end

            % Smussare l'angolo in alto a destra
            if (x - y > size(V, 2) - spessore)
                V(y, x, z) = 0;
            end

            % Smussare l'angolo in basso a destra
            if (x + y > (2 * size(V, 1)) - spessore)
                V(y, x, z) = 0;
            end
        end
    end
end



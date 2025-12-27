function [volBin] = binIncrementale(Mn,mascheraNeroTotale,indiciPalmoNoPelle,fine,sogliaIniziale,sogliaFinale)

    xDim = size(Mn,2);
    yDim = size(Mn,1);
    zDim = size(Mn,3);

    Minv = 255 - Mn;
    Minv(mascheraNeroTotale) = 0;
    % volshow(Minv);

    MatFinale = false(yDim,xDim,zDim);

    inizio = 1;
    n_iterazioni = fine - inizio + 1;

    for zplane = inizio:fine
    
        % Incremento soglia
        t = (zplane - inizio) / (n_iterazioni - 1);
        soglia = sogliaIniziale + t^2 * (sogliaFinale - sogliaIniziale);
    
        %Decremento gli indici per ottenere quelli corrispondenteall'iesimo palmo xy
        indici_nnzMNP = indiciPalmoNoPelle-zplane;

        voxelM = zeros(yDim, xDim);  
        for y = 1:yDim
            for x = 1:xDim
                indice_z = indici_nnzMNP(y, x);  
                if indice_z > 0
                    voxelM(y, x) = Minv(y, x, indice_z);  
                end
            end
        end
    
        voxelM_bin = voxelM > soglia;
    
        for y = 1:yDim
            for x = 1:xDim
                if voxelM_bin(y, x)
                    MatFinale(y, x, indici_nnzMNP(y, x)) = true;
                end
            end
        end

        % fprintf('Iterazione %d: soglia = %.4f\n', zplane, soglia);

    end

    volBin = MatFinale;

end


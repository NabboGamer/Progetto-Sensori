function [MatFinale] = binIncrementalePiano(MatFinale,Minv,indiciPalmoNoPelle,fine,inizio,sogliaIniziale,sogliaFinale,xDim,y)

    n_iterazioni = fine - inizio + 1;
    pianoXZ = squeeze(Minv(y, :, :))'; 

    for zplane = inizio:fine
        % Incremento soglia
        t = (zplane - inizio) / (n_iterazioni - 1);
        soglia = sogliaIniziale + t^2 * (sogliaFinale - sogliaIniziale);

        indici_nnzMNP = indiciPalmoNoPelle - zplane;

        % Applica la soglia solo sui piani XZ
        voxelM = zeros(1, xDim);  
        for x = 1:xDim
            indice_z = indici_nnzMNP(y, x); 
            if indice_z > 0 
                voxelM(1, x) = pianoXZ(indice_z,x);  
            end
        end

        % Binarizzazione dei voxel per il piano XZ
        voxelM_bin = voxelM > soglia;
        for x = 1:xDim
            if voxelM_bin(1, x)
                MatFinale(y, x, indici_nnzMNP(y, x)) = true;  
            end
        end
    end
    
end


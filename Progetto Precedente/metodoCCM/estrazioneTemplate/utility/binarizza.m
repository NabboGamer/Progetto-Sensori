function [binaryVolume] = binarizza(volume,tipo,soglia)
%BINARIZZA il volume in input

    if strcmp(tipo,'manuale')
        %Binarizzazione manuale
        threshold = soglia;  % Valore della soglia (da scegliere in base ai dati)
        binaryVolume = volume > threshold;
    end

    if strcmp(tipo,'manualeAdattiva')
        %Binarizzazione manuale
        binaryVolume = imbinarize(volume, soglia);
    end

    if strcmp(tipo,'otsu')
        %Binarizzazione con soglia Otsu
        threshold = graythresh(volume);  % Trova la soglia con Otsu
        binaryVolume = imbinarize(volume, threshold);
    end

    if strcmp(tipo,'adattiva')
        %Binarizzazione adattiva
        threshold = adaptthresh(volume,'neigh',[3 3 3],'Fore','bright');
        binaryVolume = imbinarize(volume, threshold);
    end

    if strcmp(tipo,'kmeans')
        %Binarizzazione tramite k-means clustering
        volumeVector = volume(:);  % Trasformare il volume in un vettore
        clusters = kmeans(volumeVector, 2);  % Cluster con 2 classi
        binaryVolume = reshape(clusters == 1, size(volume));  % Convertire i cluster in una matrice binaria
        inverted = 255 - binaryVolume;
        binaryVolume = inverted;

    end

    


    


end


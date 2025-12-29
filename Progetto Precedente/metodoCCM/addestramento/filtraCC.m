function [volumeFiltrato] = filtraCC(volume,dimVolumeMin)
%FILTRACC Filtra le componenti connesse di un volume mantenendo solo quelle sopra una soglia.
%
%   Calcola le componenti connesse (CC) presenti nel volume binario in input e
%   restituisce un volume binario che contiene esclusivamente le CC con numero
%   di voxel (Volume) maggiore o uguale a dimVolumeMin.
%
%   INPUT
%     volume         Volume binario (o convertibile a binario) da analizzare.
%                    I voxel diversi da 0 sono considerati appartenenti agli oggetti.
%     dimVolumeMin   Soglia minima (in voxel) del volume di una CC da mantenere.
%
%   OUTPUT
%     volumeFiltrato Volume logico/binario contenente solo le CC con Volume >= dimVolumeMin.
%
%   NOTE
%   - bwconncomp individua le componenti connesse nel volume.
%   - regionprops3 calcola le proprietà 3D delle CC (qui si usa solo 'Volume').
%   - labelmatrix assegna un'etichetta intera a ciascuna CC.
%   - ismember ricostruisce la maschera mantenendo solo le etichette selezionate.

    % Individua le componenti connesse nel volume (oggetti = voxel non nulli)
    CC = bwconncomp(volume);

    % Calcola il numero di voxel (Volume) per ciascuna componente connessa
    tabCC = regionprops3(CC, 'Volume');

    % Seleziona gli indici delle CC che superano (o eguagliano) la soglia minima
    CCval = find([tabCC.Volume] >= dimVolumeMin);

    % Converte l'oggetto CC in un volume etichettato (0 = sfondo, 1..N = CC)
    labeledVolume = labelmatrix(CC);

    % Mantiene solo le etichette corrispondenti alle CC selezionate
    volumeFiltrato = ismember(labeledVolume, CCval);
end

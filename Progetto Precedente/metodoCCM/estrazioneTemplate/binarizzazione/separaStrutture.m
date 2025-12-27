function [volumeGaussCleaned] = separaStrutture(volBin, utente, acquisizione, show)
%SEPARASTRUTTURE Pulisce e "separa" le strutture presenti in un volume binario.
%
% Scopo pratico:
% Partendo da volBin (volume binarizzato delle vene/strutture), applica una serie
% di operazioni morfologiche + smoothing per:
%  - rimuovere componenti piccole (rumore)
%  - regolarizzare/compattare le strutture
%  - ottenere un volume finale più pulito e coerente da visualizzare o usare in step successivi
%
% Input:
%   volBin      : volume binario/logical (o 0/255) da ripulire
%   utente,...  : usati solo per la visualizzazione
%   show        : flag per graficoVolshow
%
% Output:
%   volumeGaussCleaned : volume pulito finale (uint16) con valori 0/255

    % 1) Rimozione di piccoli oggetti: elimina tutte le componenti connesse
    % con meno di 500 voxel (filtraggio per area/volume).
    volumeCleaned = bwareaopen(volBin, 500);

    % Converto a uint16 e porto i true a 255 (formato 0/255 utile per visualizzazioni e funzioni custom)
    volumeCleaned = uint16(volumeCleaned);
    volumeCleaned(volumeCleaned == 1) = 255;

    % 2) Apertura morfologica 3D (erosione + dilatazione) con sfera di raggio 1:
    % serve a rimuovere piccoli artefatti/sporgenze e a separare connessioni sottili non desiderate.
    volumeOpen = imopen(volumeCleaned, strel('sphere', 1));

    % 3) Smoothing gaussiano 3D (sigma=1) per "ammorbidire" i bordi e colmare micro-discontinuità.
    % Padding "circular" evita bordi artificiali (si comporta come se il volume fosse periodico ai bordi).
    volumeGauss = imgaussfilt(volumeOpen, 1, "Padding", "circular");

    % 4) Ri-binarizzazione dopo smoothing:
    % uso una binarizzazione manuale con soglia 100 (funzione custom binarizza)
    % per tornare a un volume binario pulito.
    volumeGaussBin = binarizza(volumeGauss, 'manuale', 100);

    % 5) Seconda pulizia per area: ora tengo solo strutture più grandi (>= 2000 voxel),
    % eliminando residui rimasti dopo smoothing e re-soglia.
    volumeGaussCleaned = bwareaopen(volumeGaussBin, 2000);

    % Converto a uint16 e porto i true a 255 (0/255)
    volumeGaussCleaned = uint16(volumeGaussCleaned);
    volumeGaussCleaned(volumeGaussCleaned == 1) = 255;

    % Visualizzazione del volume finale pulito
    graficoVolshow(volumeGaussCleaned, 'Volume separato binarizzazione iniziale', utente, acquisizione, show);

end

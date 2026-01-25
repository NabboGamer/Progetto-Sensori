function [volSpesso, soglia] = inspessimento(volume, utente, acquisizione, soglia, show)
%INSPESSIMENTO Dilata/inspessisce le vene estrapolate per rendere le strutture più robuste.
%  Idea: ridurre rumore sottile, poi riconnettere e ispessire le vene tramite:
%  - erosione (separa / elimina filamenti troppo sottili)
%  - smoothing 3D gaussiano (riconnette e regolarizza)
%  - binarizzazione con soglia (estrazione finale "più spessa")
%
% INPUT:
%   volume       : volume 3D (tipicamente binario/logico) con vene estratte
%   utente       : id utente (per cache su disco)
%   acquisizione : id acquisizione (per cache su disco)
%   soglia       : soglia manuale per binarizzare dopo filtro gaussiano.
%                 Se soglia = -1 => viene stimata automaticamente
%   show         : flag per visualizzazione (0/1)
%
% OUTPUT:
%   volSpesso    : volume binario/uint8 finale "inspessito"
%   soglia       : soglia usata (data o calcolata)

    % Percorso dove salvare/leggere lo step intermedio
    folderPath = strcat(cd, '/stepIntermedi/', utente, '/', acquisizione);
    filename   = strcat(folderPath, '/volSpesso', '.mat');

    % Se esiste già il risultato, lo carica e termina (cache)
    if exist(filename, 'file') == 2
        disp('Volume spesso presente nella cartella, caricamento...');
        load(filename, 'volSpesso');
        graficoVolshow(volSpesso, 'Volume inspessito', utente, acquisizione, show);
        return;
    end

    % 1) Erosione morfologica 3D
    % Scopo: "assottigliare"/separare strutture e rimuovere micro-rumore,
    % così che il successivo smoothing+threshold ricostruisca preferibilmente
    % le componenti venose più consistenti.
    erodedVolume = imerode(volume, strel('sphere', 1));
    % graficoVolshow(erodedVolume,'Volume eroso',utente,acquisizione,show);

    % 2) Preparazione del tipo e filtro gaussiano 3D
    % Converte a uint8 e mappa 1 -> 255 per avere un volume "intensità"
    % su cui il filtro gaussiano abbia un senso numerico (sfondo 0, vene alte).
    erodedVolumeint = uint8(erodedVolume);
    erodedVolumeint(erodedVolumeint == 1) = 255;

    % Smoothing gaussiano (sigma=1): regolarizza e può "ricucire" gap piccoli
    % tra voxel venosi (effetto di riconnessione/maggior compattezza).
    volumeGauss = imgaussfilt3(erodedVolumeint, 1);

    % 3) Se la soglia non è fornita, la stima automaticamente
    if soglia == -1

        % vecNumCC(i) conterrà quante componenti connesse "grandi"
        % (>= 1000 voxel) risultano dalla binarizzazione con soglia i.
        vecNumCC = nan(1, 250);

        % Sweep di soglia 1..250 (parallelo) per capire come varia la
        % "frammentazione" in componenti connesse al variare della soglia.
        parfor i = 1:250

            % Binarizzazione del volume gaussiano con soglia i
            volBin = binarizza(volumeGauss, 'manuale', i);

            % Componenti connesse (default connectivity di bwconncomp dipende
            % dalla dimensionalità; in 3D tipicamente è 26 se non specificato)
            CC = bwconncomp(volBin);

            % Volume (numero di voxel) di ciascuna componente
            tabCC = regionprops3(CC, 'Volume');

            % Seleziona solo componenti "grandi" (>= 1000 voxel)
            numCCval = find([tabCC.Volume] >= 1000);

            % Numero di componenti grandi per quella soglia
            vecNumCC(i) = numel(numCCval);
        end

        % Calcolo soglia "ottima" a partire dalla curva #componenti vs soglia
        soglia = calcolaSogliaBinGauss(vecNumCC, 100, 1, 0);
    end

    % 4) Binarizzazione finale con la soglia scelta/calcolata
    volSpesso = binarizza(volumeGauss, 'manuale', soglia);

    % Visualizzazione del risultato finale
    graficoVolshow(volSpesso, 'volSpesso - Volume inspessito', "", "", show);

    % Creazione cartella se non esiste
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end

    % Salvataggio solo se non vuoto
    if nnz(volSpesso) > 0
        save(filename, 'volSpesso');
        disp('Volume spesso salvato con successo');
    else
        disp('Volume spesso vuoto NON salvato');
    end

end

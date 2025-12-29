function [tabellaCC] = iteraCC(volume,indiciPalmoNoPelle,vecFine,pathTabella)
%ITERACC Etichetta interattivamente le componenti connesse e costruisce una tabella di feature.
% 
%   La funzione:
%     1) individua le componenti connesse (CC) presenti in un volume binario,
%     2) calcola per ciascuna CC un insieme di proprietà 3D (regionprops3),
%     3) deriva ulteriori feature (rapporti tra assi, volume/superficie, distanza
%        del baricentro dalla pelle, ecc.),
%     4) mostra a video ogni CC e richiede all'utente una etichetta:
%           - 1 = vena
%           - 0 = rumore
%           - 2 = ignora (non usata nel dataset)
%           - -1 = annulla (interrompe e non salva la tabella)
%     5) salva la tabella finale su CSV (se non annullato).
%
%   INPUT
%     volume             Volume binario da analizzare (voxel != 0 considerati oggetti).
%     indiciPalmoNoPelle Matrice 2D indicizzata come (Y,X) che fornisce, per ogni punto del palmo,
%                        la quota/profondità della superficie del palmo (senza pelle).
%                        Usata per stimare la distanza del centroide dalla "pelle".
%     vecFine            Vettore 1D indicizzato su Y (riga) usato come feature globale per slice/righe.
%                        Viene combinato con la distanza centroide-pelle.
%     pathTabella        Percorso del file CSV su cui salvare la tabella delle CC etichettate.
%
%   OUTPUT
%     tabellaCC          Tabella con proprietà regionprops3 + feature derivate + label isVena.
%                        Le CC marcate come "2" (ignorate) vengono rimosse.
%
%   NOTE
%   - Le dimensioni lungo gli assi vengono ricavate da PrincipalAxisLength, con
%     l'associazione usata nel codice:
%         xDim = PrincipalAxisLength(3)
%         yDim = PrincipalAxisLength(1)
%         zDim = PrincipalAxisLength(2)
%   - La distanza centroide-pelle è calcolata come:
%         distCentroidPelle = palmoZ - centroidZ
%     dove palmoZ = indiciPalmoNoPelle(centroidY, centroidX).
%   - La funzione visualizzaCC(CC, volume, i) si assume mostri la i-esima CC.

    disp(newline);
    disp('********Inizio etichettatura********');

    %% --- 1) Estrazione componenti connesse e proprietà base ---
    CC = bwconncomp(volume);

    % Proprietà geometriche principali delle CC (una riga per componente)
    tabellaCC = regionprops3(CC, ...
        'Volume','PrincipalAxisLength','EquivDiameter','Extent','Solidity','SurfaceArea','Centroid');

    %% --- 2) Preallocazione vettori feature derivate ---
    rapportoAssiYZ = zeros(height(tabellaCC), 1);
    rapportoAssiXZ = zeros(height(tabellaCC), 1);
    rapportoAssiXY = zeros(height(tabellaCC), 1);

    rapportoVolumeY = zeros(height(tabellaCC), 1);
    rapportoVolumeX = zeros(height(tabellaCC), 1);
    rapportoVolumeZ = zeros(height(tabellaCC), 1);

    rapportoSurfaceVolume = zeros(height(tabellaCC), 1);
    rapportoSurfaceYDim = zeros(height(tabellaCC), 1);
    rapportoSurfaceXDim = zeros(height(tabellaCC), 1);
    rapportoSurfaceZDim = zeros(height(tabellaCC), 1);

    distCentroidPelle = zeros(height(tabellaCC), 1);
    rappFineBinDistCP = zeros(height(tabellaCC), 1);

    rappDimXCentX = zeros(height(tabellaCC), 1);
    rappDimZCentZ = zeros(height(tabellaCC), 1);
    rappDimYCentY = zeros(height(tabellaCC), 1);

    % Etichetta finale: 1=vena, 0=rumore, 2=ignora
    isVena = zeros(height(tabellaCC), 1);

    % Contatori di diagnostica (non indispensabili al dataset)
    classified_as_vein  = 0;
    classified_as_noise = 0;

    numComponents = height(tabellaCC);

    %% --- 3) Ciclo sulle componenti connesse: calcolo feature + labeling utente ---
    for i = 1:numComponents
        % Proprietà della CC i-esima
        volumeSize          = tabellaCC.Volume(i,:);
        surfaceArea         = tabellaCC.SurfaceArea(i,:);
        principalAxisLength = tabellaCC.PrincipalAxisLength(i,:);
        centroids           = tabellaCC.Centroid(i,:);

        % Assi principali (mappatura definita nel codice)
        xDim = principalAxisLength(3); % lunghezza lungo X
        yDim = principalAxisLength(1); % lunghezza lungo Y
        zDim = principalAxisLength(2); % lunghezza lungo Z

        % Rapporti dimensionali (forma/allungamento)
        rapportoAssiYZ(i) = yDim / zDim;
        rapportoAssiXZ(i) = xDim / zDim;
        rapportoAssiXY(i) = xDim / yDim;

        % Rapporti volume/dimensione (densità "lineare" lungo ciascun asse)
        rapportoVolumeY(i) = volumeSize / yDim;
        rapportoVolumeX(i) = volumeSize / xDim;
        rapportoVolumeZ(i) = volumeSize / zDim;

        % Rapporti superficie/dimensione e superficie/volume (complessità)
        rapportoSurfaceYDim(i) = surfaceArea / yDim;
        rapportoSurfaceXDim(i) = surfaceArea / xDim;
        rapportoSurfaceZDim(i) = surfaceArea / zDim;
        rapportoSurfaceVolume(i) = surfaceArea / volumeSize;

        % Coordinate del centroide (arrotondate a voxel)
        centroidX = round(centroids(1)); % coordinata lungo X
        centroidY = round(centroids(2)); % coordinata lungo Y
        centroidZ = round(centroids(3)); % coordinata lungo Z

        % Stima "quota pelle/palmo" nel punto (centroidY, centroidX)
        palmoZ = indiciPalmoNoPelle(centroidY, centroidX);

        % Distanza del centroide dalla superficie (pelle/palmo)
        distCentroidPelle(i) = palmoZ - centroidZ;

        % Feature combinata: valore vecFine alla riga centroidY normalizzato per distanza
        rappFineBinDistCP(i) = vecFine(centroidY) / (palmoZ - centroidZ);

        % Rapporti tra dimensione della CC e posizione del centroide (normalizzazioni geometriche)
        rappDimXCentX(i) = xDim / centroidX;
        rappDimYCentY(i) = yDim / centroidY;
        rappDimZCentZ(i) = zDim / centroidZ;

        % Visualizzazione della CC corrente (funzione esterna)
        visualizzaCC(CC,volume,i);

        % Messaggi informativi sul progresso
        fprintf('Componenti totali: %d. Componenti rimanenti: %d\n', numComponents, numComponents - i);
        fprintf('Volume size della componente: %d\n', volumeSize);

        % --- Input utente con validazione ---
        while true
            messaggio = strcat("Inserisci:\n", ...
                               "* 1 Per etichettare la componente come vena\n", ...
                               "* 0 Per etichettare la componente come rumore\n", ...
                               "* 2 Per escludere la componente dal processo\n", ...
                               "* -1 Per annullare le etichette dell'acquisizione corrente\n");
            user_input = input(messaggio);

            if user_input == 1
                classified_as_vein = classified_as_vein + 1;
                isVena(i) = 1;
                break; % input valido
            elseif user_input == 0
                classified_as_noise = classified_as_noise + 1;
                isVena(i) = 0;
                break; % input valido
            elseif user_input == 2
                disp('Componente connessa esclusa');
                isVena(i) = 2;
                break; % input valido
            elseif user_input == -1
                disp('Esecuzione interrotta, tabella non salvata.');
                break; % interrompe anche il for
            else
                disp('Input non valido, riprovare.');
            end
        end

        % Se richiesto annullamento, interrompo il processo
        if user_input == -1
            break;
        end

        % Chiude la finestra grafica della CC corrente
        close(gcf);
    end

    %% --- 4) Aggiunta feature derivate alla tabella ---
    tabellaCC.rapportoSurfaceVolume = rapportoSurfaceVolume;
    tabellaCC.rapportoAssiYZ = rapportoAssiYZ;
    tabellaCC.rapportoAssiXZ = rapportoAssiXZ;
    tabellaCC.rapportoAssiXY = rapportoAssiXY;
    tabellaCC.rapportoVolumeY = rapportoVolumeY;
    tabellaCC.rapportoVolumeX = rapportoVolumeX;
    tabellaCC.rapportoVolumeZ = rapportoVolumeZ;
    tabellaCC.rapportoSurfaceYDim = rapportoSurfaceYDim;
    tabellaCC.rapportoSurfaceXDim = rapportoSurfaceXDim;
    tabellaCC.rapportoSurfaceZDim = rapportoSurfaceZDim;
    tabellaCC.distCentroidPelle = distCentroidPelle;
    tabellaCC.rappFineBinDistCP = rappFineBinDistCP;
    tabellaCC.rappDimXCentX = rappDimXCentX;
    tabellaCC.rappDimYCentY = rappDimYCentY;
    tabellaCC.rappDimZCentZ = rappDimZCentZ;

    % Label finale
    tabellaCC.isVena = isVena;

    %% --- 5) Rimozione CC ignorate e salvataggio (se non annullato) ---
    % Elimina le righe etichettate come "ignorate" (2)
    tabellaCC(tabellaCC.isVena == 2, :) = [];

    % Salva solo se non è stato richiesto annullamento (-1)
    if user_input ~= -1
        writetable(tabellaCC,pathTabella);
        disp('Tabella salvata con successo');
    end

    disp(newline);
    disp('********Classificazione terminata********');
end

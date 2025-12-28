function [volIsolato] = isolaPatternVenoso(volume, utente, acquisizione, show)
%ISOLAPATERNVENOSO Separa/isola le strutture venose già estratte (volume binario),
%  rimuovendo rumore e piccole componenti con operazioni morfologiche 3D.
%
%  Obiettivo pratico:
%  - Eliminare componenti connessi troppo piccole (rumore)
%  - "Ripulire" la geometria (apertura morfologica)
%  - Tenere solo strutture più consistenti (presumibilmente vene)
%
% INPUT:
%   volume       : volume 3D (idealmente binario/logico) con vene + rumore
%   utente       : stringa/codice utente (per path salvataggi)
%   acquisizione : stringa/codice acquisizione (per path salvataggi)
%   show         : flag per visualizzazione finale (0/1)
%
% OUTPUT:
%   volIsolato   : volume 3D filtrato (uint16 con vene a 255, sfondo 0)

    % Percorso dove salvare/leggere risultati intermedi (cache su disco)
    folderPath = strcat(cd, '/stepIntermedi/', utente, '/', acquisizione);
    filename   = strcat(folderPath, '/volIsolato', '.mat');

    % Se il risultato esiste già, lo carica e termina per risparmiare tempo
    if exist(filename, 'file') == 2
        disp('Volume isolato presente nella cartella, caricamento...');
        load(filename, 'volIsolato');  % carica la variabile volIsolato dal .mat
        return;
    end

    % 1) Rimozione di componenti connesse piccole (filtro per area/volume)
    % bwareaopen(BW, P, conn) elimina tutti gli oggetti con meno di P voxel
    % usando la connettività 'conn' (in 3D: 6, 18, 26).
    % Qui: si eliminano oggetti < 500 voxel con connettività 6 (più "restrittiva").
    volumeCleaned = bwareaopen(volume, 500, 6);

    % Converte in uint16 (probabilmente per compatibilità con volshow/visualizzazioni)
    volumeCleaned = uint16(volumeCleaned);

    % Mappa i voxel "1" a 255 (comodo per vedere meglio il binario come immagine)
    volumeCleaned(volumeCleaned == 1) = 255;

    % Visualizzazione (qui show=0 quindi non mostra, ma chiamata lasciata "standard")
    graficoVolshow(volumeCleaned, 'Volume filtrato componenti piccole', utente, acquisizione, 0);

    % 2) Apertura morfologica 3D: imopen = erosione + dilatazione
    % Serve a rimuovere piccole asperità/rumore e "regolarizzare" le forme.
    % strel('sphere',1): elemento strutturante sferico di raggio 1 voxel.
    volumeOpen = imopen(volumeCleaned, strel('sphere', 1));
    graficoVolshow(volumeOpen, 'Volume aperto', utente, acquisizione, 0);

    % 3) Secondo passaggio di bwareaopen, più severo:
    % elimina oggetti < 1000 voxel usando connettività 26 (più "permissiva" nel collegare voxel).
    % Risultato: restano solo strutture più grandi/continue.
    volumeCleaned = bwareaopen(volumeOpen, 1000, 26);

    % Riconversione e rimappatura a 255 per coerenza con lo step precedente
    volumeCleaned = uint16(volumeCleaned);
    volumeCleaned(volumeCleaned == 1) = 255;

    % Visualizzazione finale (dipende dal flag show passato alla funzione)
    graficoVolshow(volumeCleaned, 'Volume isolato finale ', utente, acquisizione, show);

    % Output finale
    volIsolato = volumeCleaned;

    % Se la cartella non esiste, la crea
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end

    % Salva solo se non è vuoto (nnz = numero di voxel non-zero)
    if nnz(volIsolato) > 0
        save(filename, 'volIsolato');
        disp('Volume isolato salvato con successo');
    else
        disp('Volume isolato vuoto NON salvato');
    end

end

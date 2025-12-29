function [volumeFiltrato,tabellaCCFiltrata] = eliminaCCcorte(volume)
%ELIMINACCCORTE Elimina componenti connesse "corte" tramite soglie su estensione lungo Y e volume.
%
%   Questa funzione applica un filtro euristico alle componenti connesse (CC)
%   di un volume binario/logico, mantenendo solo quelle che rispettano requisiti
%   minimi di "lunghezza" e dimensione, con l'idea di preservare strutture venose
%   estese ed eliminare frammenti corti/rumore.
%
%   Criterio di mantenimento (heuristica):
%     - yDim > 150   (lunghezza principale lungo Y sufficientemente grande)
%     - Volume > 10000 voxel
%
%   INPUT
%     volume             Volume binario/logico da filtrare (voxel != 0 = oggetto).
%
%   OUTPUT
%     volumeFiltrato     Volume risultante contenente solo le CC mantenute.
%                        Viene convertito in uint16 e i voxel attivi sono impostati a 255.
%     tabellaCCFiltrata  Tabella delle sole CC mantenute (con proprietà + colonna isVena).
%
%   NOTE
%   - regionprops3 restituisce PrincipalAxisLength come vettore [L1 L2 L3] (assi principali),
%     ma l'associazione con X/Y/Z dipende dalla convenzione del progetto.
%     Qui il codice assume:
%         yDim = PrincipalAxisLength(1)
%         xDim = PrincipalAxisLength(2)
%         zDim = PrincipalAxisLength(3)
%     (xDim e zDim non vengono poi usate nel criterio, ma restano disponibili).
%   - Il nome "isVena" è usato come flag di validità (1 = mantiene, 0 = scarta).

    %% --- 1) Estrazione componenti connesse e proprietà base ---
    CC = bwconncomp(volume);
    tabellaCC = regionprops3(CC,'Volume','PrincipalAxisLength');

    % Flag mantenimento: 1 = mantiene, 0 = scarta
    isVena = zeros(height(tabellaCC), 1);

    numComponents = height(tabellaCC);

    %% --- 2) Applicazione euristica di selezione ---
    for i = 1:numComponents
        volumeSize = tabellaCC.Volume(i,:);
        principalAxisLength = tabellaCC.PrincipalAxisLength(i,:);

        % Convenzione assi (come da codice originale)
        yDim = principalAxisLength(1);
        xDim = principalAxisLength(2); %#ok<NASGU>
        zDim = principalAxisLength(3); %#ok<NASGU>

        % Mantiene solo CC sufficientemente lunghe e "grandi"
        if yDim > 150 && volumeSize > 10000
            isVena(i) = 1;
        end
    end

    % Aggiunge il flag alla tabella
    tabellaCC.isVena = isVena;

    %% --- 3) Ricostruzione volume filtrato dalle etichette valide ---
    idComponentiValidi = find(tabellaCC.isVena == 1);

    % Maschera con sole CC valide
    volumeFiltrato = ismember(labelmatrix(CC), idComponentiValidi);

    % Converto e imposto voxel attivi a 255 (utile per visualizzazione/salvataggio)
    volumeFiltrato = uint16(volumeFiltrato);
    volumeFiltrato(volumeFiltrato == 1) = 255;

    fprintf('Numero di componenti mantenute: %d\n', size(idComponentiValidi,1));

    %% --- 4) Filtraggio della tabella: tengo solo le righe valide ---
    tabellaCCFiltrata = tabellaCC;
    righeDaRimuovere = tabellaCCFiltrata.isVena == 0;
    tabellaCCFiltrata(righeDaRimuovere, :) = [];
end

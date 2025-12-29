function [volumePezzi] = recuperaPezzi(volume, componenti, volumeCCpiccole, indiciPalmoNoPelle, vecFine, model, utente, acquisizione, show)
%RECUPERAPEZZI Seleziona "pezzi" candidati da reinserire perché aiutano a connettere vene frammentate.
%
%   Questa funzione prova a recuperare porzioni eliminate/messe da parte ("componenti")
%   valutando se, una volta aggiunte al volume corrente delle vene (volume), esse:
%     - riducono il numero di componenti connesse (cioè connettono tra loro vene spezzate),
%     - tenendo conto anche dei "pallini" (CC piccole) vicini che potrebbero fungere da ponte.
%
%   In pratica, ogni "pezzo" viene testato con una euristica:
%     1) Si calcola quante CC ci sono nel volume corrente (vene) dopo un filtraggio/gauss leggero.
%     2) Si calcola quante CC ci sono nei pallini (piccole CC) dopo lo stesso trattamento.
%     3) Si crea un volumeUnito = volume OR pezzo OR (pallini vicini al pezzo),
%        e si riconta il numero di CC.
%     4) Se il numero di CC diminuisce "abbastanza" (fusioni reali), il pezzo viene marcato
%        come recuperabile e inserito in volumePezzi.
%
%   INPUT
%     volume             Volume binario/logico delle vene già accettate (baseline).
%     componenti         Volume binario/logico contenente i "pezzi" candidati al recupero.
%     volumeCCpiccole    Volume binario/logico di CC piccole (pallini) da usare come possibili ponti.
%     indiciPalmoNoPelle Matrice 2D (Y,X) quota palmo (feature contestuale) usata solo nel filtro opzionale.
%     vecFine            Vettore su Y (feature) usato solo nel filtro opzionale.
%     model              Modello RF usato per filtrare (opzionale) componenti troppo numerose/grandi.
%     utente, acquisizione, show  Parametri per graficoVolshow.
%
%   OUTPUT
%     volumePezzi         Volume binario/logico contenente solo i pezzi giudicati utili da recuperare.
%
%   NOTE
%   - Sono presenti euristiche e soglie (1000, 100, distanza_soglia = PrincipalAxisLength(1,1), ecc.).
%   - In alcuni punti è indicato "Possibile perdita" perché filtri troppo aggressivi possono scartare vene.
%   - La funzione usa parfor sui pallini: attenzione alle prestazioni se ci sono molte CC piccole.

    %% --- 0) Controllo densità: se troppe CC nei "componenti", provo a filtrare col modello ---
    tab = getTabellaCCVolume(componenti);
    numcc = height(tab);

    % Se ci sono troppe componenti, applico un filtraggio per ridurre i candidati (euristica)
    if numcc > 15
        [componenti,~] = filtraCC(componenti, indiciPalmoNoPelle, vecFine, model, 0); % Possibile perdita
    end

    %% --- 1) Pulizia dimensionale su componenti e pallini ---
    % Mantengo nei "componenti" solo CC >= 1000 voxel (il resto è troppo piccolo/instabile)
    [~,componenti] = dividiCCvolume(componenti, 1000);

    % Mantengo nei pallini solo CC >= 100 voxel (tolgo micro-rumore)
    [~,volumeCCpiccole] = dividiCCvolume(volumeCCpiccole, 100);

    % Output: pezzi recuperati (inizialmente vuoto)
    volumePezzi = false(size(volume));

    %% --- 2) Estrazione delle CC candidate (pezzi) ---
    CC = bwconncomp(componenti);
    tabellaCC = regionprops3(CC, 'Volume','PrincipalAxisLength','EquivDiameter','Extent','Solidity','SurfaceArea','Centroid');
    numComponents = height(tabellaCC);

    %% --- 3) Loop su ogni pezzo candidato: test "connessione" ---
    for i = 1:numComponents

        % Ricostruisco la i-esima componente candidata
        comp = false(size(componenti));
        comp(CC.PixelIdxList{i}) = true;

        % (Opzionale/commentato nel codice originale) Filtraggio ulteriore per componenti enormi
        % volSize = getTabellaCCVolume(comp).Volume(:,1);
        % if volSize > 50000
        %     [comp,~] = filtraCC(comp,indiciPalmoNoPelle,vecFine,model,0); % Possibile perdita
        %     if nnz(comp) == 0
        %         continue;
        %     end
        % end

        %% --- 3a) METODO con pallini e gauss "debole": selezione pallini vicini al pezzo ---
        % Centroide e dimensione principale del pezzo (usata come scala per la distanza soglia)
        cc_comp = bwconncomp(comp);
        props = regionprops3(cc_comp, 'Centroid','PrincipalAxisLength');

        coord_comp = [props.Centroid(1,1), props.Centroid(1,2), props.Centroid(1,3)];

        % Elenco CC dei pallini
        cc_pallini = bwconncomp(volumeCCpiccole);

        % Accumulatore dei pallini vicini e matrice coordinate (per escluderli dopo dal criterio)
        pallini = false(size(componenti));

        % Soglia distanza: qui si usa PrincipalAxisLength(1,1) (lunghezza principale lungo asse 1)
        distanza_soglia = (props.PrincipalAxisLength(1,1));

        % Memorizzo i centroidi dei pallini effettivamente "selezionati"
        matCordPallini = nan(cc_pallini.NumObjects, 3);

        % Scorro tutti i pallini e prendo quelli entro distanza_soglia dal pezzo (parallelo)
        parfor j = 1:cc_pallini.NumObjects
            pallino = false(size(volumeCCpiccole));
            pallino(cc_pallini.PixelIdxList{j}) = true;

            cc_pallino = bwconncomp(pallino);
            propsP = regionprops3(cc_pallino, 'Centroid');
            coord = [propsP.Centroid(1,1), propsP.Centroid(1,2), propsP.Centroid(1,3)];

            distanza = sqrt(sum((coord - coord_comp).^2, 2));

            if distanza <= distanza_soglia
                % NB: OR su variabile "pallini" dentro parfor può essere problematico in MATLAB
                % (dipende dalla versione e dalle regole sulle variabili ridotte).
                pallini = pallini | pallino; 
                matCordPallini(j,:) = coord;
            end
        end

        % Rimuovo righe NaN: restano solo i centroidi dei pallini selezionati
        matCordPallini = matCordPallini(~any(isnan(matCordPallini), 2), :);

        %% --- 3b) Conteggio CC baseline: vene + pallini (dopo gauss leggero) ---
        % Applico un filtro gauss + binarizzazione (custom) per stabilizzare le connessioni
        [volumeConn]  = filtGaussVol(volume,         2, 1);
        [palliniConn] = filtGaussVol(volumeCCpiccole,2, 1);

        % v = numero CC nel volume vene, p = numero CC nei pallini
        v = height(getTabellaCCVolume(volumeConn));
        p = height(getTabellaCCVolume(palliniConn));

        % Totale atteso senza "fusioni": (vene) + (pezzo da aggiungere) + (pallini)
        t = v + 1 + p;

        %% --- 3c) Conteggio CC dopo inserimento pezzo (e pallini vicini) ---
        volumeUnito = volume | comp | pallini;
        [volumeUnito] = filtGaussVol(volumeUnito, 2, 1);

        % cc = numero CC risultante dopo unione e smoothing
        cc = height(getTabellaCCVolume(volumeUnito));

        % Se t - cc > 1 significa che sono avvenute almeno 2 fusioni (euristica)
        if t - cc > 1

            %% --- 3d) Escludo dal conteggio le fusioni "dovute ai pallini" ---
            % Idea: conto quante CC del volumeUnito corrispondono (circa) ai pallini selezionati.
            pr = 0; % numero di "pallini rimasti" come CC separate in volumeUnito

            cc_vol_unito = bwconncomp(volumeUnito);
            for k = 1:cc_vol_unito.NumObjects
                comp_unita = false(size(volumeUnito));
                comp_unita(cc_vol_unito.PixelIdxList{k}) = true;

                cc_comp_unita = bwconncomp(comp_unita);
                propsU = regionprops3(cc_comp_unita, 'Centroid');
                coord = [propsU.Centroid(1,1), propsU.Centroid(1,2), propsU.Centroid(1,3)];

                % Confronto centroidi (tolleranza 5%) per capire se questa CC è "un pallino"
                diffCoord = abs(matCordPallini - coord);
                tolleranza = 0.05 * coord; % 5%
                righe_entro_5_percento = all(diffCoord < tolleranza, 2);

                if any(righe_entro_5_percento)
                    pr = pr + 1;
                end
            end

            % Criterio finale: considero solo le fusioni "tra vene/pezzo", scartando l'effetto pallini.
            % (v+1) = CC vene + pezzo; (cc - pr) = CC nel volume unito escluse quelle "pallino".
            if ((v + 1) - (cc - pr) > 1)
                volumePezzi = volumePezzi | comp;
            end
        end

        % Avanzamento
        fprintf('Completamento : %.2f%%\n', ((i/numComponents)*100));
    end

    %% --- 4) Visualizzazione finale ---
    graficoVolshow(volumePezzi,'Volume pezzi recuperati',utente,acquisizione,show);
end

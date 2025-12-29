function [compFilt,stopRicorsione] = recuperaVena(volume,CC,i,indiciPalmoNoPelle,vecFine,model,stopRicorsione)
%RECUPERAVENA Tenta di recuperare porzioni venose da una CC grande classificata come rumore.
%
%   Questa funzione viene tipicamente chiamata quando una componente connessa (CC)
%   molto grande è stata classificata come rumore dal modello, ma si sospetta che
%   contenga in realtà vene (o parti di vene).
%
%   Strategia:
%     1) Estrae la i-esima CC dal volume originale (CC.PixelIdxList{i})
%     2) Applica un inspessimento/morfologia adattiva dedicata al recupero
%        (inspessimentoRecuperoAdatt) per rendere la struttura più "analizzabile"
%     3) Divide la componente inspessita in CC piccole e grandi (soglia 1000 voxel)
%     4) Se le CC grandi risultanti sono più di una, rilancia il filtraggio
%        automatico (filtraCC con modello) sulle sole CC grandi
%     5) Riunisce al risultato anche le CC piccole (per non perdere dettagli utili)
%
%   La ricorsione viene controllata tramite stopRicorsione: quando diventa < 0,
%   la funzione termina immediatamente per evitare loop/ramificazioni eccessive.
%
%   INPUT
%     volume             Volume 3D di riferimento (serve per dimensioni e contesto).
%     CC                 Struttura da bwconncomp sul volume (contiene PixelIdxList).
%     i                  Indice della componente connessa da recuperare.
%     indiciPalmoNoPelle Matrice 2D (Y,X) quota del palmo senza pelle (feature contestuale).
%     vecFine            Vettore su Y usato come feature (coerente con filtraCC).
%     model              Modello di classificazione (es. fitcensemble).
%     stopRicorsione     Contatore/limite di ricorsione (decrementato in filtraCC).
%
%   OUTPUT
%     compFilt           Volume binario della componente "recuperata" (stessa size di volume).
%                        Se nessun recupero possibile, rimane tutto false.
%     stopRicorsione     Contatore ricorsione (qui non viene modificato direttamente,
%                        ma viene propagato alle chiamate successive).

    % Inizializza output vuoto (nessun voxel recuperato)
    compFilt = false(size(volume));

    % Se ho esaurito la ricorsione, esco subito
    if stopRicorsione < 0
        return;
    end

    %% --- 1) Estrazione della i-esima componente dal volume ---
    comp = false(size(volume));
    comp(CC.PixelIdxList{i}) = true; % Maschera della sola componente i-esima

    % (Debug opzionale)
    % graficoVolshow(comp, ['Componente ',num2str(i)], '', '', 1);

    %% --- 2) Inspessimento dedicato al recupero ---
    % Rende la componente più robusta/continua per favorire una nuova separazione in CC
    [compSpessa] = inspessimentoRecuperoAdatt(comp,0);

    %% --- 3) Separazione in CC piccole e grandi ---
    % Soglia fissa 1000 voxel: le piccole vengono preservate, le grandi rianalizzate
    [volumeCCPiccole,volumeCCGrandi] = dividiCCvolume(compSpessa,1000);

    % Numero di CC grandi risultanti (tabella volumi come conteggio)
    numComponents = height(getTabellaCCVolume(volumeCCGrandi));

    %% --- 4) Rilancio classificazione sulle CC grandi (se ha senso farlo) ---
    % Se dopo l'inspessimento e split ho più di una CC grande, allora
    % è probabile che la componente originale fosse un "aggregato" (vena+rumore o più vene)
    if numComponents > 1
        % Filtra le CC grandi usando il modello (può innescare ulteriori recuperi)
        [compFilt,~] = filtraCC(volumeCCGrandi,indiciPalmoNoPelle,vecFine,model,stopRicorsione);

        % Riaggiungo le CC piccole per non perdere dettagli potenzialmente utili
        compFilt = compFilt | volumeCCPiccole;
    end
end

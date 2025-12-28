function costanteDiametroVene = calcolaCostanteDiametroVene(Mn, mascheraNeroTotale, indiciPalmoNoPelle, vecFine, ...
                                                              sogliaIniziale, sogliaFinale, costanteDiametroVene, ...
                                                              numeroDiametriValidi, show)
% CALCOLACOSTANTEDIAMETROVENE Stima automaticamente il parametro
% "costanteDiametroVene" provando diversi valori e scegliendo quello che
% produce un andamento "stabile/ottimale" nel numero di componenti connesse
% significative (CC) dopo binarizzazione incrementale.
%
% Idea: aumento progressivamente un offset (tentativo) sul parametro "fine"
% della binarizzazione (max(vecFine)+tentativo). Per ogni tentativo:
%  1) binarizzo il volume
%  2) conto quante CC hanno Volume >= 3000 (quindi "vene candidate robuste")
% Ottengo così una curva (tentativo -> numero CC). La smusso (loess),
% calcolo la derivata discreta e cerco punti di variazione (local max/min)
% per selezionare un tentativo "informativo".
%
% INPUT principali:
%   - Mn: volume/immagine di input
%   - mascheraNeroTotale, indiciPalmoNoPelle: maschere per escludere zone non utili
%   - vecFine: vettore base di parametri "fine" (si usa max(vecFine))
%   - sogliaIniziale, sogliaFinale: parametri della binarizzazione incrementale
%   - costanteDiametroVene: valore massimo di tentativi da provare (range 0..costanteDiametroVene)
%   - numeroDiametriValidi: metrica di qualità/stabilità (usata per scegliere max/min dei punti di variazione)
%   - show: se 1, mostra i grafici di fitting/scelta
%
% OUTPUT:
%   - costanteDiametroVene: valore scelto (indice/tentativo finale)

    % Vettore che conterrà il numero di componenti connesse "valide"
    % per ogni tentativo (0..costanteDiametroVene)
    vecNumCC = nan(1, costanteDiametroVene + 1);

    % Asse x per i grafici: elenco tentativi
    vecTentativiCdv = 0:1:costanteDiametroVene;

    % Preallocazione (nota: in realtà MatBinaria viene ricalcolata dentro al parfor)
    MatBinaria = false(size(Mn));

    % Ciclo parallelo: prova tutti i valori del tentativo in parallelo
    parfor i = 1:(costanteDiametroVene + 1)

        % Mappo indice i -> tentativo reale (0..costanteDiametroVene)
        tentativo = i - 1;

        % Parametro "fine" usato nella binarizzazione:
        % baseline = max(vecFine), poi aggiungo l'offset tentativo
        fine = max(vecFine) + tentativo;

        % Binarizzazione incrementale del volume, tenendo conto delle maschere
        MatBinaria = binIncrementale(Mn, mascheraNeroTotale, indiciPalmoNoPelle, ...
                                     fine, sogliaIniziale, sogliaFinale);

        % Estrae le componenti connesse dal volume binario
        CC = bwconncomp(MatBinaria);

        % Calcola proprietà 3D delle CC; qui interessa solo il Volume
        tabCC = regionprops3(CC, 'Volume');

        % Filtra le CC "grandi": soglia sul volume (>= 3000 voxel)
        % -> l'idea è contare solo strutture consistenti, non rumore
        CCval = find([tabCC.Volume] >= 3000);

        % Salva quante CC valide risultano per questo tentativo
        vecNumCC(i) = numel(CCval);
    end

    % Smussa la curva numeroCC(tentativo) per ridurre rumore/oscillazioni
    % (finestra 10, metodo loess)
    vec_loess = smooth(vecNumCC, 10, 'loess');

    % Usa la versione smussata come curva "processata"
    vecProcessed = vec_loess;

    % Derivata discreta: evidenzia variazioni nel numero di CC al variare del tentativo
    dy = diff(vecProcessed);

    % Individua i punti di cambiamento: massimi/minimi locali della derivata
    % (cioè punti in cui la pendenza cresce o decresce "in modo significativo")
    maskLocalMax = islocalmax(dy);
    idLocalMax = find(maskLocalMax);

    maskLocalMin = islocalmin(dy);
    idLocalMin = find(maskLocalMin);

    puntiVariazione = [idLocalMax; idLocalMin];

    % Strategia di scelta del parametro:
    % - Se ho molti diametri validi (numeroDiametriValidi > 20) e ci sono punti di variazione,
    %   scelgo il più "tardivo" (max): privilegia un adattamento più spinto.
    % - Altrimenti, se ci sono punti di variazione, scelgo il più "precoce" (min):
    %   scelta più conservativa.
    % - Se non ci sono massimi/minimi locali, ripiego sul massimo di vecNumCC (argmax).
    if numeroDiametriValidi > 20 && nnz(puntiVariazione) > 0
        costanteDiametroVene = max(puntiVariazione);
    elseif nnz(puntiVariazione) > 0
        costanteDiametroVene = min(puntiVariazione);
    else
        [~, costanteDiametroVene] = max(vecNumCC);
    end

    % Stampa a console il valore scelto
    fprintf('Costante raggio vene applicata: %d\n', costanteDiametroVene);

    % Se richiesto, mostra grafici diagnostici:
    % - sopra: curva originale e curva smussata
    % - sotto: derivata della curva smussata
    if show == 1
        figure;

        subplot(2,1,1);
        plot(vecTentativiCdv, vecNumCC, 'b');
        hold on;
        plot(vecTentativiCdv, vec_loess, 'b', 'LineWidth', 2);
        xlabel('Costante diametro vene');
        ylabel('Numero CC');
        title('Confronto vettore numero cc originale e smussato');
        legend('originale','loess');
        hold off;

        subplot(2,1,2);
        plot(dy, 'r');
        xlabel('Costante diametro vene');
        ylabel('Derivata vettore CC');
        title('Derivata vettore CC smussato');

        sgtitle('Grafici fitting parametro costante diametro vene');
    end
end

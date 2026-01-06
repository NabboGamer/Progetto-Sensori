function [volBin, diametriValidi] = binarizzaVolume(Mn, mascheraNeroTotale, indiciPalmoNoPelle, vecFine, ...
                                                    matriceDiametri, sogliaIniziale, sogliaFinale, show)
%BINARIZZAVOLUME Esegue la binarizzazione 3D del volume (ricerca vene) su tutti i piani XZ (uno per ogni y).
%
% Il flusso ha due modalità:
% 1) FASE INIZIALE (sogliaIniziale=0 e sogliaFinale=0):
%    - binarizza ogni piano con una logica "manuale" (binManualePiano)
%    - poi applica un offset/raffinamento (binOffsetVena)
%    - produce direttamente volBin.
%
% 2) FASE FINALE (sogliaIniziale e sogliaFinale diversi da 0):
%    - stima una costante di diametro/raggio vene a partire da misure (matriceDiametri)
%      coerenti con vecFine (controllo di consistenza < 5%).
%    - usa questa costante per estendere il parametro 'fine' (vecFine + costanteDiametroVene)
%    - binarizza ogni piano in modo incrementale (binIncrementalePiano) usando le soglie fornite.
%
% Input:
%   Mn                : volume pre-processato (y,x,z) con intensità 0..255
%   mascheraNeroTotale: maschera booleana delle regioni da escludere (nero+acqua)
%   indiciPalmoNoPelle: mappa 2D (y,x) con indice z della superficie del palmo (senza pelle)
%   vecFine           : vettore 1×yDim con il parametro "fine" ottimo per ogni piano y
%   matriceDiametri   : [2×yDim] con (1) diametro stimato e (2) distanza/posizione associata
%   sogliaIniziale    : soglia iniziale (se 0 con sogliaFinale=0 -> fase iniziale)
%   sogliaFinale      : soglia finale (usata nella fase finale)
%   show              : flag per eventuali plot/debug in calcolaCostanteDiametroVene
%
% Output:
%   volBin            : volume binario (logical) che rappresenta le vene estratte
%   diametriValidi    : diametri accettati come "validi" (usati per stimare la costante)

    % Dimensioni del volume (convenzione: y,x,z)
    xDim = size(Mn, 2);
    yDim = size(Mn, 1);
    zDim = size(Mn, 3);

    % Inverto intensità e azzero le aree non utilizzabili:
    % - inversione (255-Mn) spesso serve a rendere "forti" le strutture scure
    % - mascheraNeroTotale elimina acqua/nero/regioni non affidabili
    Minv = 255 - Mn;
    Minv(mascheraNeroTotale) = 0;

    % MatFinale conterrà il risultato binario finale 3D
    MatFinale = false(yDim, xDim, zDim);

    % MatBin è un buffer iniziale (all-false) passato alle funzioni di binarizzazione piano-per-piano
    MatBin = false(yDim, xDim, zDim);

    % ------------------------- MODALITÀ 1: FASE INIZIALE -------------------------
    if sogliaIniziale == 0 && sogliaFinale == 0
        disp(newline);
        disp('***Binarizzazione fase iniziale in corso***');

        % Processo indipendente per ogni piano y -> parallelizzabile
        parfor y = 1:yDim
            % Parametro "fine" ottimo per questo piano (derivato da vecFine)
            fine = vecFine(y);

            % Binarizzazione "manuale" del piano y usando Minv e la superficie del palmo:
            % - fine determina fino a che profondità relativa considerare i voxel utili
            % - (1,250) qui sono parametri passati alla funzione (range o soglie interne)
            MatBinaria = binManualePiano(MatBin, Minv, indiciPalmoNoPelle, fine, 1, 250, xDim, y);

            % Raffinamento con un offset sulla vena (tipicamente per regolarizzare/spostare la maschera)
            pianoFinale = binOffsetVena(MatBinaria, xDim, zDim, y);

            % binOffsetVena sembra restituire una matrice [x,z] o [z,x]:
            % permute per riallineare in [x,z] -> [1, xDim, zDim] e assegnare in MatFinale(y,:,:)
            MatFinale(y,:,:) = permute(pianoFinale, [2, 1]);
        end

        % Output volume binario finale
        volBin = MatFinale;

    % ------------------------- MODALITÀ 2: FASE FINALE -------------------------
    else
        disp(newline);
        disp('***Inizio fitting costante raggio vene***');

        % Stimo una costante (diametro/raggio) delle vene valida globalmente:
        % seleziono solo i diametri coerenti con la posizione vecFine (errore < 5%).
        diametri = nan(1, yDim);

        for y = 1:yDim
            diametro = matriceDiametri(1, y);
            distDiametro = matriceDiametri(2, y);

            % Considero solo misure non-NaN e consistenti rispetto a vecFine(y)
            if ~isnan(diametro) && ~isnan(distDiametro)
                valoreFine = vecFine(y);
                differenzaPercentuale = abs(valoreFine - distDiametro) / valoreFine * 100;
                if differenzaPercentuale < 5
                    diametri(y) = diametro;
                end
            end
        end

        % Tengo solo i diametri validi e calcolo la costante come media (arrotondata)
        diametriValidi = diametri(~isnan(diametri));
        if ~isempty(diametriValidi)
            costanteDiametroVene = round(mean(diametriValidi));
        else
            costanteDiametroVene = 0;
        end

        % Log a console
        numeroDiametriValidi = numel(diametriValidi);
        fprintf('Costante raggio vene calcolata: %d, numero diametri validi : %d\n', ...
                costanteDiametroVene, numeroDiametriValidi);

        % Buffer binario 3D
        MatBinaria = false(yDim, xDim, zDim);

        % Eventuale raffinamento della costante tramite una funzione dedicata (con soglie e debug)
        if costanteDiametroVene > 0
            [costanteDiametroVene] = calcolaCostanteDiametroVene(Mn, mascheraNeroTotale, indiciPalmoNoPelle, vecFine, ...
                                                                sogliaIniziale, sogliaFinale, costanteDiametroVene, ...
                                                                numeroDiametriValidi, show);
        end

        disp(newline);
        disp('***Binarizzazione fase finale in corso***');

        % Binarizzazione finale: per ogni piano y estendo la profondità "fine"
        % aggiungendo la costante stimata, e applico una binarizzazione incrementale
        % usando sogliaIniziale e sogliaFinale.
        parfor y = 1:yDim
            fine = vecFine(y) + costanteDiametroVene;

            MatBinaria = binIncrementalePiano(MatBin, Minv, indiciPalmoNoPelle, fine, 1, ...
                                                sogliaIniziale, sogliaFinale, xDim, y);

            % Qui MatBinaria viene scritto/letto piano-per-piano, e MatFinale raccoglie l'output
            MatFinale(y,:,:) = MatBinaria(y,:,:);
        end

        % Output volume binario finale
        volBin = MatFinale;
    end
    
end

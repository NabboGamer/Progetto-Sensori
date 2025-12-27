function [volumePalmo,mascheraNeroPalmo,mascheraNeroTotale] = calcolaMaschere(Mstart,mascheraAcqua,offsetPalmo,offsetPelle)
%CALCOLAMASCHERE Calcola:
% - volumePalmo: volume che contiene solo il palmo (rimuovendo la parte "sopra" il palmo)
% - mascheraNeroPalmo: maschera delle regioni da azzerare nella zona palmo (fino a offsetPalmo dalla base del palmo)
% - mascheraNeroTotale: unione di mascheraNeroPalmo e mascheraAcqua (tutto ciò che va rimosso)
%
% Convenzione assunta: Mstart e mascheraAcqua sono già orientati e allineati
% (stesse dimensioni y-x-z). La terza dimensione è la profondità (z).

    volumePalmo = Mstart;

    % Dimensioni
    xDim = size(volumePalmo,2);
    yDim = size(volumePalmo,1);
    zDim = size(volumePalmo,3);

    % Inizializzo la maschera del "nero palmo" (voxel da rimuovere in zona palmo)
    mascheraNeroPalmo = false(yDim,xDim,zDim);

    % --- Rimozione pelle / aggiornamento maschera acqua ---
    % Trovo, per ogni colonna (y,x), l'indice z del primo voxel "acqua" (true/non-zero)
    % lungo la profondità. In pratica è una stima del bordo acqua↔tessuto.
    [~, indiciAcqua] = max(mascheraAcqua ~= 0, [], 3);

    % Ripeto offsetPelle volte: l'idea è "spostare" quel bordo verso l'alto
    % per scartare uno spessore superficiale (pelle) e aggiornare coerentemente mascheraAcqua.
    for z = 1:offsetPelle
        indiciAcqua = indiciAcqua - 1;  % arretra di 1 slice (scarto progressivo verso la superficie)

        for x = 1:xDim
            for y = 1:yDim

                if z == 1
                    % Queste operazioni vengono fatte una sola volta (alla prima iterazione):

                    % 1) Creo volumePalmo: per ogni colonna (y,x) individuo l'ultimo voxel non zero
                    %    (altezzaPalmo = "base" del palmo lungo z) e azzero tutto ciò che sta sopra
                    %    (da z=1 a altezzaPalmo-1). In questo modo in volumePalmo rimane solo palmo.
                    colonnaMat = squeeze(volumePalmo(y,x,:));
                    altezzaPalmo = find(colonnaMat ~= 0, 1,'last');
                    volumePalmo(y,x,1:altezzaPalmo-1) = 0;

                    % 2) Creo mascheraNeroPalmo: sempre per la stessa colonna, segno come "nero"
                    %    (da rimuovere) la parte che va da z=1 fino a (altezzaPalmo - offsetPalmo).
                    %    In pratica definisco una fascia iniziale che non voglio considerare (pre-palmo /
                    %    regione non utile) lasciando "utile" solo la parte più profonda del palmo.
                    colonnaMat = squeeze(volumePalmo(y,x,:));
                    altezzaPalmo = find(colonnaMat ~= 0, 1,'last');
                    mascheraNeroPalmo(y,x,1:altezzaPalmo-offsetPalmo) = true;
                end

                % Aggiorno mascheraAcqua aggiungendo uno strato di acqua (pelle scartata):
                % per ogni colonna, accendo a true la slice indicata da indiciAcqua(y,x).
                % Se l'indice scende sotto 1, l'acquisizione è incoerente/corrotta.
                if indiciAcqua(y,x) < 1
                    disp('Acquisizione corrotta');
                else
                    mascheraAcqua(y,x,indiciAcqua(y,x)) = true;
                end

            end
        end
    end

    % Maschera totale di ciò che va rimosso: nero del palmo + acqua (inclusa la pelle scartata)
    mascheraNeroTotale = mascheraNeroPalmo | mascheraAcqua;

    % Rendo binario/normalizzato il volume del palmo: tutti i voxel non-zero diventano 255
    % (utile per visualizzazione o passaggi successivi basati su presenza/assenza).
    volumePalmo(volumePalmo ~= 0) = 255;

end

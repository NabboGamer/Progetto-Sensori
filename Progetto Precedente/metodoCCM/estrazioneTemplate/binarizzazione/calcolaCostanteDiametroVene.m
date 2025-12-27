function [costanteDiametroVene]=calcolaCostanteDiametroVene(Mn,mascheraNeroTotale,indiciPalmoNoPelle,vecFine,sogliaIniziale,sogliaFinale,costanteDiametroVene,numeroDiametriValidi,show)

    vecNumCC = nan(1,costanteDiametroVene+1);
    vecTentativiCdv = [0:1:costanteDiametroVene];

    MatBinaria = false(size(Mn));

    parfor i = 1:costanteDiametroVene+1
        tentativo = i - 1;
        fine = max(vecFine) + tentativo;
        [MatBinaria] = binIncrementale(Mn,mascheraNeroTotale,indiciPalmoNoPelle,fine,sogliaIniziale,sogliaFinale);

        CC = bwconncomp(MatBinaria);
        tabCC = regionprops3(CC, 'Volume');
        CCval = find([tabCC.Volume] >= 3000);
        vecNumCC(i) = numel(CCval);

    end

    vec_loess = smooth(vecNumCC, 10, 'loess');

    vecProcessed = vec_loess;
    dy = diff(vecProcessed);

    %Prendo l'ultimo local minimo o local massimo
    maskLocalMax = islocalmax(dy);
    idLocalMax = find(maskLocalMax);
    maskLocalMin = islocalmin(dy);
    idLocalMin = find(maskLocalMin);
    puntiVariazione = [idLocalMax;idLocalMin];

    if numeroDiametriValidi > 20 && nnz(puntiVariazione) > 0
        % disp('Costante dv scelta pari al massimo dei punti di variazione');
        costanteDiametroVene = max(puntiVariazione);
    elseif nnz(puntiVariazione) > 0
        % disp('Costante dv scelta pari al minimo dei punti di variazione');
        costanteDiametroVene = min(puntiVariazione);
    else
        % disp('Non ci sono massimi e minimi locali');
        [~,costanteDiametroVene] = max(vecNumCC);
    end

    fprintf('Costante raggio vene applicata: %d\n',costanteDiametroVene);

    if show == 1
        figure;
        subplot(2,1,1);
        plot(vecTentativiCdv,vecNumCC, 'b'); 
        hold on;
        plot(vecTentativiCdv,vec_loess, 'b', 'LineWidth', 2); 
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
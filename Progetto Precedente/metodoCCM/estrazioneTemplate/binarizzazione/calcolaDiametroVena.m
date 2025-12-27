function [diametro] = calcolaDiametroVena(pianoCCvalide,pianoPalmo,y)
        
        diametro = NaN;

        CC = bwconncomp(pianoCCvalide);
        structCC = regionprops(CC, 'Area','EquivDiameter','Circularity','Centroid');
        tabellaCC = struct2table(structCC);
        centroids = cat(1,tabellaCC.Centroid);
        if ~isempty(centroids)
            % visualizzaCentroidi(pianoCCvalide,y,centroids,0);

            cordZcentroid = round(tabellaCC.Centroid(:,2))';
            cordXcentroid = round(tabellaCC.Centroid(:,1))';
            [~,cordZpalm] = max(pianoPalmo ~= 0, [], 1);
            cordZpalmCentroid = cordZpalm(cordXcentroid);
            distanzeCentroidPalmo = cordZpalmCentroid-cordZcentroid;
            [~,idVena] = min(distanzeCentroidPalmo);
            vena = tabellaCC(idVena, :);

            if vena.EquivDiameter(1) > 10 && vena.Circularity(1) > 0.5
                diametro = vena.EquivDiameter(1);
            end
            
        end
        













end


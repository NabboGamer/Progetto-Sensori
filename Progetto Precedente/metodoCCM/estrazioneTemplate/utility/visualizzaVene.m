function visualizzaVene(volumeFinale,X,Y,Z,Xc,Yc,utente,acquisizione)
%%Crea il grafico finale del pattern venoso estratto

    volumeFinale = uint8(volumeFinale);
    volumeFinale(volumeFinale == 1) = 255;

    % % Passaggi per migliorare la visualizzazione delle vene
    % 
    % volumeFinale = uint8(volumeFinale);
    % volumeFinale(volumeFinale == 1) = 255;
    % volumeFinale = imgaussfilt3(volumeFinale, 4,"padding","symmetric");
    % volumeFinale = binarizza(volumeFinale,'otsu',120);
    % % volshow(volumeFinale);
    % 
    % volumeFinale = uint8(volumeFinale);
    % volumeFinale(volumeFinale == 1) = 255;
    % volumeFinale = imgaussfilt3(volumeFinale, 10,"padding","circular");
    % volumeFinale = binarizza(volumeFinale,'manuale',170);
    % % volshow(volumeFinale);


    % 6.1)Riporto la matrice alle dimensioni originali 
    xDim = size(X,1);
    yDim = size(Y,1);
    xcDim = size(Xc,1);
    ycDim = size(Yc,1);

    pad_x = xDim - xcDim; 
    pad_y = yDim - ycDim;  
    
    pad_x_before = floor(pad_x / 2);
    pad_x_after = pad_x - pad_x_before;
    
    pad_y_before = floor(pad_y / 2);
    pad_y_after = pad_y - pad_y_before;
    
    volumeFinale_padded = padarray(volumeFinale, [pad_y_before, pad_x_before, 0], 0, 'pre');  
    volumeFinale_padded = padarray(volumeFinale_padded, [pad_y_after, pad_x_after, 0], 0, 'post');  
    
    % 6.2) Creo la matrice intensità e trasparenza
    inverted = 255 - volumeFinale_padded;
    
    trasp = volumeFinale_padded;
    trasp = flip(trasp, 3);
    trasp = permute(trasp, [3,2,1]);
    
    volumeVene = inverted;
    volumeVene = flip(volumeVene, 3);
    volumeVene = permute(volumeVene, [3,2,1]);

    %%---------------------Visualizzazione standard------------------%%
    
    % 6.3) Visualizzazione 3D del pattern venoso
    hFig3D = figure('Name', 'Render 3D', 'NumberTitle', 'off');
    loadingText = text(0.5, 0.5, 0.5, 'Caricamento...', 'HorizontalAlignment', 'center', 'FontSize', 14);
    view(310+180, 40);

    figure(hFig3D);

    % Utilizza la funzione vol3dd per creare la visualizzazione 3D
    h = vol3dd('cdata', flip(shiftdim(volumeVene, 1), 1), 'alpha', flip(shiftdim(trasp, 1), 1), 'texture', '2D', 'xdata', [Y(1), Y(end)], 'ydata', [X(1), X(end)], 'zdata', [Z(1), Z(end)]);
    colormap(gray(256));
    set(gcf, 'Color', 'w');
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k', 'FontSize', 12, 'XDir', 'reverse', 'YDir', 'reverse', 'ZDir', 'reverse');
    axis tight;
    xlabel('y [mm]');
    ylabel('x [mm]');
    zlabel('z [mm]');
    grid on;
    title([utente,'-',acquisizione]);
    delete(loadingText);

    %%-----------------------------------------------------------------%%



    %%------------------Visualizzazione con isosurface-----------------%%

    % volumeData = volumeFinale_padded;  % Sostituisci con il tuo volume
    % isoValue = 0;
    % 
    % figure;
    % hIso = isosurface(X, Y, Z, volumeData, isoValue);  % Usa X_mm, Y_mm, Z_mm per gli assi in mm
    % 
    % % Visualizzare la isosuperficie con rendering
    % p = patch(hIso);             % Crea un oggetto patch per la visualizzazione
    % isonormals(X, Y, Z, volumeData, p);    % Calcola e applica le normali per il rendering
    % p.FaceColor = 'green';          % Colore della superficie
    % p.EdgeColor = 'none';         % Disattiva il colore dei bordi
    % 
    % % Impostare le proprietà della scena
    % % daspect([1 1 1]);             % Imposta il rapporto degli assi
    % view(3);                      % Vista 3D
    % camlight;                     % Aggiunge una luce alla scena
    % lighting gouraud;             % Imposta l'illuminazione Gouraud
    % 
    % % Etichettare gli assi in mm
    % xlabel('x [mm]');
    % ylabel('y [mm]');
    % zlabel('z [mm]');
    % 
    % % Abilitare la griglia
    % grid on;
    % axis equal;

    %%-------------------------------------------------------------%%




end


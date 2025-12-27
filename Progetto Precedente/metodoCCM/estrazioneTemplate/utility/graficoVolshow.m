function graficoVolshow(volumeData ,testo, utente, acquisizione,show)

    if show == 0
        return;
    end

    %%----------------VERSIONE MATLAB 2023-----------------------%%
    % titolo = [testo,' - ',utente, '_0',acquisizione];
    % 
    % % Step 1: Creare un uifigure
    % hFig = uifigure('Name', '3D Volume Viewer', 'Position', [100 100 800 600]);
    % 
    % % Step 2: Aggiungere un pannello per volshow
    % hPanel = uipanel(hFig, 'Position', [20 60 760 500]);
    % 
    % % Step 3: Visualizzazione del volume usando volshow nel pannello
    % hVol = volshow(volumeData, 'Parent', hPanel);
    % 
    % % Step 4: Aggiungere un titolo con uilabel
    % uilabel(hFig, 'Text', titolo, ...
    %         'Position', [150 570 500 20], 'FontSize', 14, 'HorizontalAlignment', 'center');
    %%------------------------------------------------------------%%

    %%----------------VERSIONE MATLAB 2024------------------------%%
    titolo = [testo, ' - ', utente, '_0', acquisizione];  % Stringa per il titolo
    
    % Step 1: Creare un uifigure
    hFig = uifigure('Name', '3D Volume Viewer', 'Position', [100 100 800 600]);
    
    % Step 2: Creare un oggetto Viewer3D come contenitore per volshow
    hViewer = viewer3d(hFig, 'Position', [20 60 760 500]);
    
    % Step 3: Visualizzazione del volume usando volshow
    hVol = volshow(volumeData, 'Parent', hViewer);  % Specifica hViewer come genitore
    
    % Step 4: Aggiungere un titolo con uilabel e testo bianco
    uilabel(hFig, 'Text', titolo, ...
            'Position', [150 570 500 20], ...
            'FontSize', 14, ...
            'HorizontalAlignment', 'center', ...
            'FontColor', 'white');
    %%------------------------------------------------------------%%

end


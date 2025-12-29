if ~exist(pathSaveImg3D, 'dir')
   mkdir(pathSaveImg3D);  
end

% Nome del file e percorso completo
filename = fullfile(pathSaveImg3D, [utente,'_0',acquisizione,'.png']);  % Cambia con il nome che desideri

% Salva la figura
saveas(gcf, filename);  % Salva la figura come PNG (o puoi scegliere un altro formato come .fig, .jpg, ecc.)
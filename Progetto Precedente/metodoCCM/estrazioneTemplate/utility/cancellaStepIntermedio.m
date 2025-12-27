function cancellaStepIntermedio(utente,acquisizione,step)

    folderPath = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione);
    filename = strcat(folderPath,'/',step,'.mat');

    if exist(filename, 'file') == 2
        delete(filename)
    end
    
end
function rinominaStepIntermedio(utente,acquisizione,oldStep,newStep)

    folderPath = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione);
    oldFileName = strcat(folderPath,'/',oldStep,'.mat');
    newFileName = strcat(folderPath,'/',newStep,'.mat');

    if exist(oldFileName, 'file') == 2
        movefile(oldFileName, newFileName);
    end
    
end
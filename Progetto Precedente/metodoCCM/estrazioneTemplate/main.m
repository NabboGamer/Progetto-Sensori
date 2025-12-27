%% MANUELE CAPECE - CHIARA CAPORALE - GIANFRANCO MANFREDA
%% Estrae i template per tutte o selezionate acquisizioni di un utente
close all;
clear all;
close(findall(0, 'Type', 'figure', 'Name', '3D Volume Viewer'));
clc 
aggiungiPath;
%%%%%%%%%%%%%%%%%%%%%%%%%
utenteStart = "Bianconi";
utenteEnd = "Bianconi";
stepAcquisizione = 1;
pathMatfiles = [cd,'/..','/Matfiles/'];
%%%%%%%%%%%%%%%%%%%%%%%%%
elementi = dir(pathMatfiles);
nomi_cartelle = {elementi([elementi.isdir] & ~ismember({elementi.name}, {'.', '..'})).name};
estrazioneTotale = 1;

disp('Estrazione completa database iniziata');

for j = 1:length(nomi_cartelle)
    currentFolderName = nomi_cartelle{j};
    trattinoPos = strfind(currentFolderName, '-');
    utente = currentFolderName(1:trattinoPos(1)-1);
    tipo = currentFolderName(trattinoPos(1)+1:end);

    if (string(utente) >= utenteStart) && (string(utente) <= utenteEnd) && tipo == 's'
        pathCartella = [pathMatfiles,utente,'-',tipo,'/'];
        files = dir(pathCartella);
        fileNames = {files(~[files.isdir]).name};
        disp(strcat("Estrazione completa ",utente," iniziata"));

        for i = 1:stepAcquisizione:length(fileNames)
            currentFileName = fileNames{i};
            underscorePos = strfind(currentFileName, '_');
            acquisizione = currentFileName(underscorePos(1)+2:end-4);

            pathVolBin = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione,'/volBinFinal','.mat');
            pathVecFineBin = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione,'/vecFineBin','.mat');
            pathVolIsolato = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione,'/volIsolato','.mat');
            pathVolSpesso = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione,'/volSpesso','.mat');
            pathVolFilt = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione,'/volFilt','.mat');
            pathVolAff = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione,'/volAff','.mat');
        
            % if exist(pathVolBin,     'file') == 2 &&...
            %    exist(pathVecFineBin, 'file') == 2 &&...
            %    exist(pathVolIsolato, 'file') == 2 &&...
            %    exist(pathVolSpesso,  'file') == 2 &&...
            %    exist(pathVolFilt,    'file') == 2 &&...
            %    exist(pathVolAff,     'file') == 2 
            %     continue;
            % end

            try
               
                estraiTemplate;
                close all;
                close(findall(0, 'Type', 'figure', 'Name', '3D Volume Viewer'));
                
            catch ME
                disp(ME.message); 
            end
        end

    end
    
end

 clear estrazioneTotale;

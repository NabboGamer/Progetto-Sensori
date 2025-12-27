%% Estrae i template per tutte le acquisizioni di un utente
close all;
close(findall(0, 'Type', 'figure', 'Name', '3D Volume Viewer'));
clc 
%%%%%%%%%%%%%%%%%%%%%%%%%
utenteStart = "Sprovera";
utenteEnd = "Ungaro";
stepAcquisizione = 2;
%%%%%%%%%%%%%%%%%%%%%%%%%
pathUtenti = [cd,'/..','/..','/Codice FUSION - metodo LuongoScavone/Biometric_data/Matfiles/'];
elementi = dir(pathUtenti);
nomi_cartelle = {elementi([elementi.isdir] & ~ismember({elementi.name}, {'.', '..'})).name};
estrazioneTotale = 1;


disp('Estrazione completa database iniziata');

for j = 1:length(nomi_cartelle)
    currentFolderName = nomi_cartelle{j};
    trattinoPos = strfind(currentFolderName, '-');
    utente = currentFolderName(1:trattinoPos(1)-1);
    tipo = currentFolderName(trattinoPos(1)+1:end);

    if (string(utente) >= utenteStart) && (string(utente) <= utenteEnd) && tipo == 's'
        pathCartella = [cd,'/..','/..','/Codice FUSION - metodo LuongoScavone/Biometric_data/Matfiles/',utente,'-',tipo,'/'];
        files = dir(pathCartella);
        fileNames = {files(~[files.isdir]).name};
        disp(strcat("Estrazione completa ",utente," iniziata"));

        for i = 1:stepAcquisizione:length(fileNames)
            currentFileName = fileNames{i};
            underscorePos = strfind(currentFileName, '_');
            acquisizione = currentFileName(underscorePos(1)+2:end-4);

            pathVolBin = strcat(cd,'/volumiBinarizzati/',utente,'/volBin_',acquisizione,'.mat');
            pathVecFine = strcat(cd,'/vettoriFine/',utente,'/vecFineBin_',acquisizione,'.mat');
        
            % if exist(pathVolBin, 'file') == 2 && exist(pathVecFine, 'file') == 2
            %     continue;
            % end

            try

                % cancellaStepIntermedio(utente,acquisizione,'volFilt');
                % cancellaStepIntermedio(utente,acquisizione,'volAff');
                % rinominaStepIntermedio(utente,acquisizione,['vecFineBin_',acquisizione],'vecFineBin');
                % rinominaStepIntermedio(utente,acquisizione,['volBinFinal',acquisizione],'volBinFinal');
                
                %Per estrarre i template in modo automatico
                estraiTemplate;
                close all;
                close(findall(0, 'Type', 'figure', 'Name', '3D Volume Viewer'));
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            catch ME
                disp(ME.message); 
            end
        end

    end
    
end

 clear estrazioneTotale;

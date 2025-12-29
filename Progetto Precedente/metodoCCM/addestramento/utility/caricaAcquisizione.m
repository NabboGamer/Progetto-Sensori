try
    
    % folderPath = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione);
    % filename = strcat(folderPath,'/acquisizione','.mat');
    % 
    % if exist(filename, 'file') == 2
    %     disp('Acquisizione presente nella cartella, caricamento...');
    %     load(filename);
    %     return;
    % end

    load(pathMatrice);

    % if ~exist(folderPath, 'dir')
    %     mkdir(folderPath);
    % end
    % 
    % save(filename, 'M', 'X', 'Y', 'Z');
    % disp('Acquisizione salvata con successo');

catch ME
    disp(ME.message); 
    error(sprintf('Acquisizione %s_0%s corrotta o non trovata!\nProvare con un''altra acquisizione', utente, acquisizione));
end
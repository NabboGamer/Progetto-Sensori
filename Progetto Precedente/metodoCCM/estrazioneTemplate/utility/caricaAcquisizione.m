try
    load(pathMatrice);
catch ME
    disp(ME.message); 
    error(sprintf('Acquisizione %s_0%s corrotta o non trovata!\nProvare con un''altra acquisizione', utente, acquisizione));
end
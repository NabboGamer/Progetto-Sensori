function [pathMatrice,pathSaveImg3D] = definisciPath(path,utente,tipo,acquisizione)
    %%Dato in input il percorso in cui si trovano i file mat restituisce il
    %%percorso contenente l'acquisizione su cui estrarre il template
    pathMatrice = [path,utente,'-',tipo,'/',utente,'_0',acquisizione,'.mat'];
    pathSaveImg3D = [cd,'/template/',utente,'/immagini3D'];

end


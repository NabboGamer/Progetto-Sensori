%% MANUELE CAPECE - CHIARA CAPORALE - GIANFRANCO MANFREDA
%% Lettura del file mat
%---------Inserire utente e acquisizione per estrazione singola-------%
if ~exist('estrazioneTotale', 'var')
    close all;
    close(findall(0, 'Type', 'figure', 'Name', '3D Volume Viewer'));
    clc 
    utente = 'Brienza'; 
    tipo = 's';
    acquisizione = '00';
    pathMatfiles = [cd,'/..','/Matfiles/'];
    aggiungiPath;
end
%---------------------------------------------------------------------%
[pathMatrice,pathSaveImg3D] = definisciPath(pathMatfiles,utente,tipo,acquisizione);
caricaAcquisizione;
printTestoCornice(strcat("Estrazione template ",utente,"_0",acquisizione),'+');
avviaPoolParallelo;

tic;
%% 1) Cropping della matrice M
[Mc,Xc,Yc,Yi] = cropMatrice(M,X,Y);

%% 2) Estrapolazione del volume contenente le vene
[volumePalmo,Mnp,mascheraAcqua,mascheraNeroPalmo,mascheraNeroTotale,indiciPalmoNoPelle] = estrapolaVolumeVene(Mc,Z,utente,acquisizione,200,1);

%% 3) Binarizzazione del volume
[volumeBin,vecFine] = effettuaBinarizzazione(Mnp,volumePalmo, mascheraAcqua, mascheraNeroTotale,indiciPalmoNoPelle, utente, acquisizione, size(Yc,1),0);

%% 4) Isolamento del pattern venoso
volIsolato = isolaPatternVenoso(volumeBin,utente,acquisizione,0);

%% 5) Inspessimento del pattern venoso
[volSpesso,sogliaGauss] = inspessimento(volIsolato,utente,acquisizione,-1,0);

%% 6) Filtraggio delle componenti connesse
[volFilt] = filtraComponentiConnesse(volSpesso,5000,indiciPalmoNoPelle,vecFine,utente,acquisizione,0);

%% 7) Smoothing delle vene
[volumeAffinato] = affinaVene(volFilt,indiciPalmoNoPelle,vecFine,utente,acquisizione,0);

%% 8) Visualizzazione del pattern venoso estratto
visualizzaVene(volumeAffinato,X,Yi,Z,Xc,Yc,utente,acquisizione);

%% 9) Salvataggio del template
salvaTemplate;

elapsedTime = toc;  
disp(newline);
fprintf('Durata estrazione template: %.2f secondi\n', elapsedTime);
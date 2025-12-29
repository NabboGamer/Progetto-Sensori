%% MANUELE CAPECE - CHIARA CAPORALE - GIANFRANCO MANFREDA
%Permette di visualizzare il volume contenente il template estratto
%sovrapposto al volume originale
close all;
close(findall(0, 'Type', 'figure', 'Name', '3D Volume Viewer'));
clc 
%%%%%%%%%%%%%%%%%%%%
utente = 'Carriero'; 
tipo = 's';
acquisizione = '04';
pathMatfiles = [cd,'/..','/Matfiles/'];
%%%%%%%%%%%%%%%%%%%%
aggiungiPath;
[pathMatrice,pathSaveImg3D] = definisciPath(pathMatfiles,utente,tipo,acquisizione);
%---------------------------------------------------------------------%
caricaAcquisizione;
[Mc,Xc,Yc,Yi] = cropMatrice(M,X,Y);
[volumePalmo,Mnp,mascheraAcqua,mascheraNeroPalmo,mascheraNeroTotale,indiciPalmoNoPelle] = estrapolaVolumeVene(Mc,Z,utente,acquisizione,200,1);
[volumeBin,vecFine] = effettuaBinarizzazione(Mnp,volumePalmo, mascheraAcqua, mascheraNeroTotale,indiciPalmoNoPelle, utente, acquisizione, size(Yc,1),0);
[volIsolato] = isolaPatternVenoso(volumeBin,utente,acquisizione,0);
[volSpesso,sogliaGauss] = inspessimento(volIsolato,utente,acquisizione,-1,0);
[volumeAffinato] = affinaVene(0,0,0,utente,acquisizione,0);
%---------------------------------------------------------------------%
volInt = uint8(volumeAffinato);
volInt(volInt == 1) = 255;
volumeUnito = Mnp+volInt;
volumeUnito(volInt > 255) = 255;
graficoVolshow(volumeUnito,'Volume unito originale-template',utente,acquisizione,1);
% visualizzaVene(volumeAffinato,X,Yi,Z,Xc,Yc,utente,acquisizione);

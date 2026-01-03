%% MANUELE CAPECE - CHIARA CAPORALE - GIANFRANCO MANFREDA
%Permette di visualizzare la differenza di posizione e orientamento di due
%template.
close all;
clear all;
close(findall(0, 'Type', 'figure', 'Name', '3D Volume Viewer'));
clc 
%------------------------------
% nameTemp1 = "Celi";acTemp1 = "02"; 
% nameTemp2 = "Gruosso";acTemp2 = "10"; 
% nameTemp1 = "D'Onofrio"; acTemp1 = "02";
% nameTemp2 = "D'Onofrio"; acTemp2 = "18";
% nameTemp1 = "Di Giacomo"; acTemp1 = "08";
% nameTemp1 = "Celi"; acTemp1 = "17";
% nameTemp1 = "De Luca"; acTemp1 = "14";
% nameTemp2 = "Molinaro"; acTemp2 = "09";
nameTemp1 = "Fruggiero"; acTemp1 = "07";
nameTemp2 = "Fruggiero"; acTemp2 = "19";
%------------------------------
%---------------------------------------------------------------------%
pathCartella = strcat(cd, '/..','/estrazioneTemplate/stepIntermedi');
pathTemp1 = strcat(pathCartella,"/",nameTemp1,"/",acTemp1,"/volAff.mat");
pathTemp2 = strcat(pathCartella,"/",nameTemp2,"/",acTemp2,"/volAff.mat");
%---------------------------------------------------------------------%
volTemp1 = load(pathTemp1).volumeFilled;
volTemp2 = load(pathTemp2).volumeFilled;
% graficoVolshow(volTemp1 ,nameTemp1, '', '',1);
% graficoVolshow(volTemp2 ,nameTemp2, '', '',1);

confrontaVolumi(volTemp1,volTemp2);

% tic
% score = matching3Dtr(volTemp1,volTemp2);
% toc





%% STATISTICHE_MATCHING_ML
% Questo script:
% 1) Carica un file .mat di risultati contenente la tabella T (match tra coppie di utenti).
% 2) Etichetta ogni confronto come "genuino" (stesso utente) o "impostore" (utenti diversi),
%    basandosi sul nome file/username presente in T.Utente1 e T.Utente2.
% 3) Costruisce le distribuzioni degli score (0–100) per genuini e impostori.
% 4) Normalizza le distribuzioni, le plotta e calcola:
%    - FAR (False Acceptance Rate) al variare della soglia
%    - FRR (False Rejection Rate) al variare della soglia
%    - EER (Equal Error Rate) come punto di minima differenza tra FAR e FRR
% 5) Salva vettori e tabelle in .mat nella cartella di output selezionata.
%
% Assunzioni sul formato dei nomi:
% - T.Utente1 / T.Utente2 sono stringhe del tipo "...XX" (es: nome + 2 char finali),
%   e l'ultima cifra rappresenta una specie di indice acquisizione.

close all;
clear all;
clc;

%% Selezione file risultati e cartella di output
[fileRisultati, path] = uigetfile('*.mat','Seleziona il file .mat dei risultati');
pathCompleto = [path fileRisultati];
load(pathCompleto);

pathStatistiche = uigetdir('', 'Seleziona cartella dove salvare le Statistiche');

% Timestamp (qui calcolato ma non utilizzato nel seguito)
% timeStr = strrep(datestr(now),':','-');

% Costruzione nome cartella di output basata sul nome del file sorgente
k = strfind(fileRisultati,'.mat');
sourceStr = fileRisultati(1:k-1);

% Cartella in cui salvare tutte le statistiche di questo run
sName = [pathStatistiche, '/', sourceStr];
mkdir(sName);

%% Etichettatura genuino/impostore dentro la tabella T
% L'idea è estrarre un "nome utente" da Utente1 e Utente2 e confrontarlo.
matchT = size(T);

for i = 1:matchT(1)

    % --- Parsing Utente1 ---
    Ut1 = char(T.Utente1(i));
    Ut1 = strrep(Ut1,'.mat','');                 % rimuove estensione se presente
    nomeUt1 = Ut1(1:(length(Ut1)-2));            % rimuove le ultime 2 posizioni (assunzione sul formato)
    cifreUt1 = str2num(Ut1(end));                % ultima cifra (non usata nello script)

    % --- Parsing Utente2 ---
    Ut2 = char(T.Utente2(i));
    Ut2 = strrep(Ut2,'.mat','');
    nomeUt2 = Ut2(1:(length(Ut2)-2));
    cifreUt2 = str2num(Ut2(end));                % ultima cifra (non usata nello script)

    % Se i nomi base coincidono -> genuino, altrimenti impostore
    if (strcmp(nomeUt1,nomeUt2) == 1)
        T.Genuino(i) = 1;
    else
        T.Genuino(i) = 0;
    end
end

%% Separazione in coppie genuine/impostor e costruzione tabelle
genuino   = 0;
impostore = 0;

% Ogni riga: {Utente1, Utente2, Score_percentuale}
tabellaGenuinoML   = cell(1,3);
tabellaImpostoreML = cell(1,3);

match = size(T);
for i = 1:match(1)

    pri = T{i,4};

    if (pri == 1)
        % ---- GENUINO ----
        genuino = genuino + 1;

        tabellaGenuinoML(genuino,1) = {T.Utente1(i)};
        tabellaGenuinoML(genuino,2) = {T.Utente2(i)};

        % Score in percentuale (0–100) con saturazione a 100 se > 1
        scoml = (T{i,3});
        if (scoml <= 1)
            sml = round((scoml) * 100);
            tabellaGenuinoML(genuino,3) = {sml};
        else
            tabellaGenuinoML(genuino,3) = {'100'};
        end

    else
        % ---- IMPOSTORE ----
        impostore = impostore + 1;

        tabellaImpostoreML(impostore,1) = {T.Utente1(i)};
        tabellaImpostoreML(impostore,2) = {T.Utente2(i)};

        % Score in percentuale (0–100) con saturazione a 100 se > 1
        scomci = (T{i,3});
        if (scomci <= 1)
            smci = round((scomci) * 100);
            tabellaImpostoreML(impostore,3) = {smci};
        else
            tabellaImpostoreML(impostore,3) = {'100'};
        end
    end
end

%% Conversione in table (più comoda per analisi)
TabGenML = cell2table(tabellaGenuinoML,   'VariableNames',{'Utente1' 'Utente2' 'Score'});
TabImpML = cell2table(tabellaImpostoreML, 'VariableNames',{'Utente1' 'Utente2' 'Score'});

%% Istogrammi discreti (1..100) delle frequenze degli score
% vec_gen(k) = quante occorrenze dello score k (in percentuale) per genuini
% vec_imp(k) = quante occorrenze dello score k (in percentuale) per impostori
vec_gen = zeros(1,100);
vec_imp = zeros(1,100);

% ---- Frequenze genuini ----
dime = size(TabGenML);
for i = 1:dime(1)
    valore = TabGenML.Score(i);  % atteso: intero 0..100

    % NOTA: con indicizzazione MATLAB, valore=0 non è indicizzabile -> viene ignorato
    if (valore ~= 0)
        vec_gen(1,valore) = vec_gen(1,valore) + 1;
    end
end

% Salvataggio
s = strcat(sName, '/vec_gen.mat');
save(s ,'vec_gen');

% ---- Frequenze impostori ----
dime = size(TabImpML);
for i = 1:dime(1)
    valore = TabImpML.Score(i);

    if (valore ~= 0)
        vec_imp(1,valore) = vec_imp(1,valore) + 1;
    end
end

% Salvataggio
s = strcat(sName, '/vec_imp.mat');
save(s ,'vec_imp');

%% Normalizzazione delle curve (scala 0..1)
max_genuino        = max(vec_gen);
vett_norm_genuino  = vec_gen / max_genuino;

max_impostore      = max(vec_imp);
vett_norm_impostore = vec_imp / max_impostore;

% Salvataggio normalizzati nella cartella di output sName
s = strcat(sName, '/vettore_norm_genuini.mat');
save(s,'vett_norm_genuino');

s = strcat(sName, '/vettore_norm_impostori.mat');
save(s,'vett_norm_impostore');

%% Plot delle frequenze NORMALIZZATE
approssimazione = 0.01;               % step della soglia (e risoluzione asse x nel plot distribuzioni)
intervalli = 1/approssimazione;       % numero intervalli su [0,1] (es: 100)

figure1 = figure;
axes1 = axes('Parent',figure1,'FontSize',10);
xlim(axes1,[0 1]);
ylim(axes1,[0 1.05]);
box(axes1,'on');
hold(axes1,'all');

% impostori
plot1 = plot(approssimazione:approssimazione:1, vett_norm_impostore,'Parent',axes1);
set(plot1(1),'DisplayName','impostor');
xlabel('Score','FontSize',12);
ylabel('frequency','FontSize',12);
hold on;

% genuini
plot2 = plot(approssimazione:approssimazione:1, vett_norm_genuino,'Color','red');
set(plot2(1),'Color',[1 0 0],'DisplayName','genuine');

legend1 = legend(axes1,'show');
set(legend1,'Location','NorthWest');

%% Calcolo FAR (False Acceptance Rate)
% FAR(t) = P(score >= t | impostore)
% Qui: per ogni soglia, si conta quanta massa degli impostori resta sopra la soglia.
indice = 0;
for soglia = 0:approssimazione:1
    indice = indice + 1;

    if (soglia > 0)
        somma = 0;

        % Somma delle frequenze impostori sotto soglia (approssimazione discreta)
        for i = 1:(soglia/approssimazione)
            if (vec_imp(1,i) > 0)
                somma = somma + vec_imp(1,i);
            end
        end

        % Quota sopra soglia
        vettore_FAR(1,indice) = (sum(vec_imp) - somma) / sum(vec_imp);
    else
        % A soglia 0, tutto passa -> FAR = 1
        vettore_FAR(1,indice) = 1;
    end
end

s = strcat(sName, '/vettore_far.mat');
save(s,'vettore_FAR');

%% Calcolo FRR (False Rejection Rate)
% FRR(t) = P(score < t | genuino)
% Qui: per ogni soglia, si conta quanta massa dei genuini cade sotto soglia.
indice = 0;
for soglia = 0:approssimazione:1
    indice = indice + 1;

    if (soglia > 0)
        somma = 0;

        % Somma delle frequenze genuini sotto soglia (approssimazione discreta)
        for i = 1:(soglia/approssimazione)
            if (vec_gen(1,i) > 0)
                somma = somma + vec_gen(1,i);
            end
        end

        vettore_FRR(1,indice) = somma / sum(vec_gen);
    else
        % A soglia 0, nessun genuino viene rifiutato -> FRR = 0
        vettore_FRR(1,indice) = 0;
    end
end

s = strcat(sName, '/vettore_frr.mat');
save(s,'vettore_FRR');

%% Interpolazione (per avere curve più "lisce")
% Si interpola FAR e FRR da 101 punti (step 0.01) a 1001 punti (~step 0.001).
far_interp = interp1(1:intervalli+1, vettore_FAR, 1:0.1:intervalli+1, 'cubic');
frr_interp = interp1(1:intervalli+1, vettore_FRR, 1:0.1:intervalli+1, 'cubic');

%% Plot FAR e FRR
figure2 = figure;
axes1 = axes('Parent', figure2);
ylim(axes1, [0 1.05]);
xlim(axes1, [0 1]);
box(axes1, 'on');
hold(axes1, 'all');

% Asse x in threshold (0..1) con passo 0.001
plot1 = plot(0:0.001:1, far_interp);
set(plot1(1), 'DisplayName', 'FAR');
xlabel('threshold t', 'FontSize', 12);
ylabel('error probability', 'FontSize', 12);
hold on;

plot2 = plot(0:0.001:1, frr_interp, 'Color', 'red');
set(plot2(1), 'Color', [1 0 0], 'DisplayName', 'FRR');

legend5 = legend(axes1, 'show');
set(legend5, 'Position', [0.152380952380951 0.684126984126991 0.15 0.1]);

%% Calcolo EER (Equal Error Rate)
% EER = punto in cui FAR e FRR sono più vicini (minima differenza assoluta).
dimensione = size(far_interp);
dimensionecolonne = dimensione(2);

EER_Y = zeros(1, dimensionecolonne);  % differenze |FAR - FRR|
EER_X = zeros(1, dimensionecolonne);  % threshold associata (0..1 con step 0.001)

for i = 1:dimensionecolonne
    EER_Y(1,i) = abs(far_interp(1,i) - frr_interp(1,i));
    EER_X(1,i) = i * 0.001;
end

% Punto con minima differenza
[eer_y_3D, eer_x2] = min(EER_Y);

% Threshold EER (0..1). Si usa (eer_x2-1)*0.001 per riallineare l'indice a 0.
eer_x_ML = (eer_x2-1) * 0.001;

% Valore EER (prendiamo FAR al punto selezionato; a EER idealmente FARFRR)
eer_y_ML = far_interp(eer_x2);

fprintf('Equal Error Rate (EER):\n');
fprintf('Errore (FAR/FRR): %.3f\n', eer_y_ML);

%% Salvataggi finali in cartella di output
s = strcat(sName, '/EER_ML.mat');
save(s, 'eer_x_ML', 'eer_y_ML');

t = strcat(sName, '/tab.mat');
save(t, 'T');

ti = strcat(sName, '/tab_imp.mat');
save(ti, 'TabImpML');

tg = strcat(sName, '/tab_gen.mat');
save(tg, 'TabGenML');

%% CALCOLA_SCORE_MATCHING3D  Crea una tabella di score per il matching 3D di template selezionati
%  MANUELE CAPECE - CHIARA CAPORALE - GIANFRANCO MANFREDA
%
%  DESCRIZIONE
%  Questo script:
%   1) legge un file Excel contenente, per ciascun utente, l’elenco delle acquisizioni da usare;
%   2) carica i template (file .mat, tipicamente un volume 3D) dalle cartelle di step intermedi;
%   3) esegue i confronti a coppie (pairwise matching) tra tutti i template caricati;
%   4) salva (o riprende) una tabella con gli score in formato .mat.
%
%  INPUT (da file / cartelle)
%   - listeTemplate/<NOME_LISTA>.xlsx
%       Tabella con colonne attese:
%         * Utente        : string con nome cartella utente
%         * Acquisizioni  : string contenente una lista tipo "[01,02,03]" (formato compatibile con l'estrazione sotto)
%   - <pathCartella>/<utente>/<acquisizione>/volAff.mat
%       File .mat contenente il template/volume da confrontare.
%
%  OUTPUT
%   - <pathTab>/tab_<NOME_LISTA>.mat
%       File .mat contenente la tabella T con colonne:
%         * Utente1, Utente2, Score
%
%  DIPENDENZE
%   - effettuaConfronti(...)
%
%  NOTE
%   - Se l’esecuzione precedente è stata interrotta, lo script prova a caricare la tabella già salvata
%     e proseguire (logica demandata a effettuaConfronti).
%   - Lo script considera solo le sottocartelle dentro pathCartella (una per utente).
%
%  ESEMPIO
%   Impostare NOME_LISTA in modo coerente con il file presente in listeTemplate/
%   e lanciare lo script.

%% Pulizia ambiente di lavoro
clear all; %#ok<CLALL>
clc;

%% ----------- Definizione dei percorsi ------------ %
nomeLista = 'listaTemplateProva';  % Nome (senza estensione) del file Excel in "listeTemplate/"
pathCartella = strcat(cd, '/..','/estrazioneTemplate/stepIntermedi');  % Cartella che contiene le sottocartelle utente
% ----------------------------------------------- %

% Percorso del file Excel con la lista di acquisizioni
pathLista = strcat('listeTemplate/', nomeLista, '.xlsx');

% Nome base della tabella salvata su disco
nomeTab = strcat('tab_', nomeLista);

% Cartella di output per le tabelle
pathTab = strcat(cd, '/tabelle');

%% Lettura lista (Excel)
lista = readtable(pathLista);

%% Ricavo elenco utenti come sottocartelle di pathCartella
files = dir(pathCartella);
isFolder = [files.isdir];
utenti = {files(isFolder).name};
utenti = utenti(~ismember(utenti, {'.', '..'})); % rimuove cartelle speciali

%% Mappa (dizionario) template: chiave = "utente_0acquisizione", valore = volume/template caricato
templates = containers.Map;

% Reset GPU (utile se effettuaConfronti o altre funzioni usano GPU e si vuole partire “puliti”)
reset(gpuDevice);

%% 1) Caricamento dei template
for i = 1:length(utenti)

    utente = utenti{i};

    % Filtra la tabella Excel per l'utente corrente
    datiUtente = lista(strcmp(lista.Utente, utente), :);

    % Estrae la stringa contenente la lista acquisizioni (es. "[01,02,03]")
    % NOTA: qui si assume che per ogni utente esista una riga e che "Acquisizioni" sia cell array di char/string
    listaTemplate = datiUtente.Acquisizioni{1};

    % Pulisce parentesi quadre e separa per virgola
    listaTemplate = erase(listaTemplate, {'[', ']'});
    listaTemplate = split(listaTemplate, ',');
    listaTemplate = cellstr(listaTemplate);

    % Se l’utente ha almeno una acquisizione indicata, carica i relativi template
    if ~isempty(listaTemplate{1})

        for j = 1:size(listaTemplate, 1)

            acquisizione = listaTemplate{j};

            % Percorso del file .mat del template/volume (volAff.mat)
            pathFile = strcat(pathCartella, '/', utente, '/', acquisizione, '/volAff.mat');

            % Import del contenuto del .mat (importdata può restituire struct o variabile, a seconda del file)
            dati = importdata(pathFile);

            % Chiave univoca del template (usata poi nei confronti)
            nomeTemplate = strcat(utente, '_0', acquisizione);

            % Salvataggio nella mappa
            templates(nomeTemplate) = dati;
        end
    end
end

%% 2) Calcolo degli score (matching pairwise)
n = templates.Count;         % Numero di template caricati
score = zeros(n);            % Matrice score (può essere usata/riempita dentro effettuaConfronti)
niter = n * (n-1) / 2;       % Numero di confronti unici (triangolo superiore senza diagonale)
nomi = keys(templates);      % Lista chiavi template (nomiTemplate)

fprintf('Numero iterazioni: %d\n', niter);

%% Carico la tabella se una precedente esecuzione si fosse interrotta, altrimenti ne creo una nuova
pathTabMat = [pathTab, '/', nomeTab, '.mat'];

if isfile(pathTabMat)
    % Se esiste già, si riparte dalla tabella salvata
    load(pathTabMat); % atteso che contenga almeno la variabile "T"
else
    % Tabella nuova: una riga per confronto, con colonne (Utente1, Utente2, Score)
    T = table( ...
        repmat({''}, niter, 1), ...
        repmat({''}, niter, 1), ...
        nan(niter, 1), ...
        'VariableNames', {'Utente1', 'Utente2', 'Score'} ...
    );
end

%% Tabella di supporto (opzionale) per eventuale matching parallelo / sincronizzazione
% -------------------------------------------------- %
% TS = load('tabelle/tabellaSupportoUnita.mat').TUF;
TS = table();
% -------------------------------------------------- %

%% Esecuzione confronti e timing
tic
[T] = effettuaConfronti(nomi, templates, n, niter, score, pathTab, nomeTab, T, TS);
toc

function [vecFineBin] = calcolaVecFineBin(Mn, mascheraNeroTotale, mascheraAcqua, indiciPalmoNoPelle, utente, acquisizione)
%CALCOLAVECFINEBIN Stima, per ogni riga y del volume, un indice "fine" ottimo
% per la binarizzazione lungo z (parametro 'fine' usato in binPianoSingolo).
%
% Idea: per ogni piano XZ (fissato y), provo diversi valori di 'fine' e misuro
% quante componenti connesse (CC) ottengo dopo binarizzazione. Il vettore vecCC(fine)
% (numero di CC al variare di 'fine') tende a mostrare picchi: i primi picchi
% indicano tipicamente soglie/intervalli in cui emergono strutture (vene).
% L'indice ottimo per quel piano viene scelto come:
% - media dei primi due picchi (se presenti >=2),
% - altrimenti il primo picco,
% - NaN se non ci sono picchi.
%
% Output:
%   vecFineBin: vettore 1×yDim con l'indice ottimo 'fine' per ciascun piano y.
%
% Nota: salva/ricarica il risultato su disco per evitare ricalcoli.

    % Percorso dove salvare/caricare il vettore risultato per questa acquisizione
    folderPath = strcat(cd,'/stepIntermedi/',utente,'/',acquisizione);
    filename = strcat(folderPath,'/vecFineBin','.mat');

    % Se esiste già, lo carico e termino (cache dei risultati)
    if exist(filename, 'file') == 2
        disp('Vettore fine binarizzazione presente nella cartella, caricamento...');
        load(filename,'vecFineBin');
        return;
    end

    % Dimensioni del volume (convenzione: y,x,z)
    xDim = size(Mn, 2);
    yDim = size(Mn, 1);
    zDim = size(Mn, 3);

    % Inverto il contrasto: Minv = 255 - Mn
    % (utile se le vene/strutture di interesse sono più scure e voglio farle risultare più "forti")
    Minv = 255 - Mn;

    % Azzero tutte le zone sicuramente non utili (nero+acqua) tramite maschera totale
    Minv(mascheraNeroTotale) = 0;

    % Parametro di inizio usato per binarizzare: qui fissato a 1 (costante)
    inizio = 1;

    % Vettore finale (uno per ogni y); inizializzo a NaN (caso: nessun picco trovato)
    vecFineBin = nan(1,yDim);

    % Ricavo, per ogni (y,x), l'indice z del primo voxel marcato come acqua.
    % Serve a limitare il range delle iterazioni 'fine' per non andare in zone non affidabili.
    [~, id_mascheraAcqua] = max(mascheraAcqua ~= 0, [], 3);

    % Scelgo un limite globale (conservativo): il minimo tra tutti gli indici acqua, -1.
    % In pratica, "fino a qui sicuramente non sto entrando nell'acqua".
    fineIterazione = min(id_mascheraAcqua(:)) - 1;

    %%------------------ Setup progresso (parfor) ------------------%%
    % DataQueue permette di stampare progresso anche dentro un parfor.
    D = parallel.pool.DataQueue;
    afterEach(D, @nUpdateProgress);
    numCompleted = 0;
    function nUpdateProgress(~)
        numCompleted = numCompleted + 1;
        percentComplete = (numCompleted / yDim) * 100;
        fprintf('Progresso: %.2f%% completato\n', percentComplete);
    end
    %%--------------------------------------------------------------%%

    % Loop parallelo sui piani XZ (uno per ogni y)
    parfor y = 1:yDim

        % vecCC(fine) conterrà il numero di componenti connesse ottenute per ogni valore di 'fine'
        vecCC = zeros(1, fineIterazione);

        % Estraggo il piano XZ corrispondente a questa y:
        % squeeze(Minv(y,:,:)) -> [x,z], poi trasposto -> [z,x] (convenzione attesa dalle funzioni successive)
        pianoXZ = squeeze(Minv(y, :, :))';

        % Estraggo gli indici "palmo senza pelle" per questo y (vettore lungo x)
        idPalmoNoPellepiano = indiciPalmoNoPelle(y,:);

        % Scansiono tutti i possibili valori di 'fine' (da 1 a fineIterazione)
        for fine = 1:fineIterazione

            % Genero la maschera/binarizzazione del piano XZ usando l'intervallo [inizio, fine]
            % e l'informazione geometrica (idPalmoNoPellepiano)
            pianoFinale = binPianoSingolo(inizio, fine, pianoXZ, idPalmoNoPellepiano, xDim, zDim);

            % Converto la maschera logica in immagine binaria uint8 (0/255), richiesta da contaCC
            pianoFinaleBin = uint8(pianoFinale);
            pianoFinaleBin(pianoFinale)  = 255;
            pianoFinaleBin(~pianoFinale) = 0;

            % Conteggio delle componenti connesse nel piano binarizzato (metrica di "quanto si spezza" la segmentazione)
            [numCC, ~] = contaCC(pianoFinaleBin, y);
            vecCC(fine) = numCC;
        end

        % Trovo i picchi nel numero di CC: i picchi indicano cambiamenti netti nella segmentazione
        % al variare di 'fine' (punti candidati "ottimi").
        [~, locazioni] = findpeaks(vecCC, 'MinPeakProminence', 1);
        locazioniSorted = sort(locazioni);

        % Scelta dell'indice ottimo per questo piano:
        % - se ho almeno due picchi: uso la media dei primi due (stima robusta dell'intervallo utile)
        % - se ho un solo picco: uso quello
        % - se non ho picchi: NaN
        if size(locazioniSorted,2) > 1
            primiDuePicchi = locazioniSorted(:,1:2);
            idOptPiano = mean(primiDuePicchi);
        else
            if isempty(locazioniSorted)
                idOptPiano = NaN;
            else
                idOptPiano = locazioniSorted(1);
            end
        end

        % Salvo l'indice ottimo nel vettore finale
        vecFineBin(y) = idOptPiano;

        % Aggiorno la stampa del progresso (thread-safe tramite DataQueue)
        send(D, y);
    end

    % Creo la cartella di output se non esiste
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end

    % Salvo vecFineBin solo se contiene almeno un valore non nullo (evito di salvare risultati vuoti)
    if nnz(vecFineBin) > 0
        save(filename,'vecFineBin');
        disp('Vettore fine binarizzazione salvato con successo');
    else
        disp('Vettore fine binarizzazione vuoto NON salvato');
    end

end

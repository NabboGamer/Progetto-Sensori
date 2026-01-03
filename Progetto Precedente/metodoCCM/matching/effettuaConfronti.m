function T = effettuaConfronti(nomi,templates,n,niter,score,pathTab,nomeTab,T,TS)
%EFFETTUACONFRONTI Esegue confronti pairwise tra template 3D e aggiorna una tabella risultati.
%
%   Questa funzione MATLAB calcola il punteggio di matching tra tutte le coppie (i,j) con i<j
%   dei template associati ai nomi in NOMI. I punteggi vengono inseriti nella
%   tabella T (colonne: Utente1, Utente2, Score) e salvati progressivamente
%   su disco dopo ogni ciclo esterno su i.
%
%   La funzione evita ricalcoli:
%   - Se la riga corrente in T (indice k) contiene già uno Score valido
%     (non NaN), passa alla coppia successiva.
%   - Se è fornita una tabella di supporto TS, prova a recuperare lo Score
%     già calcolato per la coppia (Utente1,Utente2) e, se disponibile,
%     lo copia in T.
%
%   INPUT:
%     nomi     - Cell array (1xN) di string/char con gli identificativi utenti.
%     templates- Mappa/dizionario indicizzata da nomi: templates(nome) -> template.
%     n        - Numero di utenti/template da considerare (tipicamente numel(nomi)).
%     niter    - Numero totale di confronti attesi (serve solo per la % di progresso).
%     score    - Matrice NxN dove salvare i punteggi calcolati (solo triangolo sup.).
%     pathTab  - Cartella di salvataggio della tabella.
%     nomeTab  - Nome del file .mat su cui salvare la variabile T.
%     T        - Tabella risultati preallocata/già esistente (con colonne coerenti).
%     TS       - Tabella di supporto (opzionale) con risultati preesistenti.
%
%   OUTPUT:
%     T        - Tabella risultati aggiornata.
%
%   NOTE:
%   - Il matching viene eseguito da matching3Dtr(tmp1,tmp2); eventuali errori
%     vengono catturati e lo score viene impostato a NaN.
%   - Il salvataggio avviene ad ogni iterazione del ciclo esterno (i) per
%     garantire checkpoint in caso di interruzioni.
%
%   See also: matching3Dtr

    % Contatore lineare delle coppie (i,j) con i<j: indica la riga in tabella T.
    k = 0;

    % Scorro tutti gli utenti come primo elemento della coppia.
    for i = 1:n
        % Recupero il template del primo utente dalla mappa/dizionario.
        tmp1 = templates(nomi{i});

        % Confronto tmp1 con tutti i template successivi (evito duplicati e diagonale).
        for j = (i+1):n
            k = k + 1;

            % Recupero il template del secondo utente.
            tmp2 = templates(nomi{j});

            %------------------- SALTI / RECUPERI -------------------%

            % 1) Se in T alla riga k esiste già uno score valido, non ricalcolo.
            rigaCorrente = T(k,:);
            if ~isnan(rigaCorrente.Score)
                continue;
            end

            % 2) Se esiste una tabella di supporto TS, provo a recuperare lo score.
            if ~isempty(TS)
                % Cerco la riga in TS che matcha la coppia (Utente1,Utente2).
                rowIndex = strcmp(TS.Utente1, nomi{i}) & strcmp(TS.Utente2, nomi{j});

                % Se trovato e lo score non è NaN, copio direttamente in T e salto.
                if ~isnan(TS(rowIndex,:).Score)
                    T(k,:) = TS(rowIndex,:);
                    continue;
                end
            end

            %------------------- MATCHING 3D -------------------%

            % Calcolo del punteggio di matching tra i due template.
            % In caso di errore (es. template corrotti o mismatch dimensionale),
            % assegno NaN per segnalare fallimento.
            try
                score(i,j) = matching3Dtr(tmp1, tmp2);
            catch
                score(i,j) = NaN;
            end

            % Aggiorno la tabella risultati alla riga k con la coppia e lo score.
            T(k,:) = {nomi{i}, nomi{j}, score(i,j)};

            % Stampo una percentuale di avanzamento rispetto al numero totale di confronti.
            fprintf('Progresso: %.2f%% completato\n', (double(k) / double(niter)) * 100);
        end

        % Salvataggio incrementale della tabella per non perdere progressi.
        save(strcat(pathTab,'\',nomeTab), 'T');
    end
end

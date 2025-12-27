% Controlla se esiste un parpool attivo
pool = gcp('nocreate');  % 'nocreate' non crea un pool se non esiste

% Se il pool è vuoto (non esiste), ne crea uno nuovo
if isempty(pool)
    disp('Nessun parpool attivo. Creazione di un nuovo parpool...');
    success = false;
    maxAttempts = 5;  % Numero massimo di tentativi
    attempt = 1;
    
    while ~success && attempt <= maxAttempts
        try
            parpool('local');  % Crea un parpool locale con il numero di core predefinito
            success = true;  % Se parpool si avvia, imposta success a true
            disp('Parpool avviato con successo.');
        catch ME
            disp(['Tentativo ' num2str(attempt) ' fallito: ' ME.message]);
            attempt = attempt + 1;
            pause(2);  % Attende 2 secondi prima di riprovare
        end
    end
    
    if ~success
        error('Impossibile avviare il parpool dopo %d tentativi.', maxAttempts);
    end
else
    disp('Parpool già attivo.');
end


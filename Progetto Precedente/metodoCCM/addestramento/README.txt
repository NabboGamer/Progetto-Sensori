Descrizione cartella "addestramento"
Questa cartella contiene tutti gli script necessari per creare il dataset ed addestrare il classificatore binario.

"etichettaCC"
Permette di etichettare le componenti connesse di una determinata acquisizione. Crea un dataset in formato csv contenente le features e le etichette per ogni componente connessa dell'acquisizione selezionata. Salva il dataset nella cartella dataset.
Specificare:
-utente
-acquisizione
-percorso in cui si trovano i file mat
-tipo (nel caso in cui si utilizzano i file mat presenti in metodoCCM)

"creaDatasetUtente"
Permette di etichettare le componenti connesse di selezionate acquisizioni di un utente.
Specificare:
-utente
-listaAcquisizioni : acquisizioni per cui si vuole etichettare le componenti connesse
-percorso in cui si trovano i file mat
-tipo (nel caso in cui si utilizzano i file mat presenti in metodoCCM)

"creaDataset"
Recupera i dataset per utente e crea il dataset concatenato su cui addestrare il classificatore. Il dataset unito prende il nome di datasetUnito.csv e viene salvato nella cartella dataset.

"addestraModello"
Addestra un modello di classificatore binario basato sul bagging di alberi decisionali. 
Salva il modello nella cartella corrente con il nome modelloRF.mat
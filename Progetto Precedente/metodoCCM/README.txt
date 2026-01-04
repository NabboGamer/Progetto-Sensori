Per eseguire i codici presenti nelle 3 cartelle si consiglia di scaricare Google drive desktop e lasciare i percorsi predefiniti.
Così facendo il codice funzionerà in modo automatico dato che è basato su percorsi relativi.

- La cartella "estrazioneTemplate" contiene i codici per estrarre i template 3D
- La cartella "addestramento" contiene i codici per addestrare un classificatore binario
- La cartella "matching" contiene i codici per effettuare il matching 3D
- La cartella "Matfiles" contiene i file mat risultanti dall'esecuzione dello script "fromUOBtoMAT_dbCompleto"
  in cui le acquisizioni .uob vengono convertite il file .mat
- Il file Excel listaAcquisizioni.xlsx contiene la lista di tutti gli utenti presenti nel database Luongo-Scavone

NB.
-I template estratti nella cartella "estrazioneTemplate/stepIntermedi" sono relativi a 43 utenti del database Luongo-Scavone. In particolare solamente quelli etichettati come 's' nel file listaAcquisizioni.xlsx. La colonna 'tipo' indica:
	-s: (strong) le vene si vedono chiaramente
	-l: (low) le vene si vedono appena
	-n: (none) non si distinguono delle vene
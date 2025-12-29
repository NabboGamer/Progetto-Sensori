# Appunti presi durante l'analisi del progetto precedente

## OSSERVAZIONE SU PARAGRAFO: 7.1.2 Assunzioni
Dubbio sulla seconda assunzione stabilite a monte del progetto infatti viene detto:

_"I primi voxel con intensità prossima a 0 che si osservano scansionando il volume nella direzione Z a partire dal palmo della mano e dirigendosi verso il fondo rappresentano delle vene."_

In generale non è detto e come assunzione è poco generale piuttosto fragile. Il primo voxel scuro non implica una vena perché lungo una A-line (o colonna Z) si possono avere voxel scuri per: rumore/speckle e micro-zone anecogene casuali; ombre acustiche (shadowing) dietro strutture più riflettenti.

Potrebbe essere rinforzata (senza stravolgere il metodo) nel seguente modo:
Non “primo voxel scuro”, ma primo tratto scuro persistente per k voxel consecutivi e coerente su un intorno.

*TODO: VERIFICARE ESATTAMENTE COME È IMPLEMENTATO NEL CODICE PER CARPIRE SE CISI FERMA AL PRIMO VOXEL OPPURE EFFETTIVAMENTE SI VALUTA UN INTORNO DI VOXEL*


## OSSERVAZIONE SU PARAGRAFO: 7.4 ESTRAPOLAZIONE
Nella funzione ```estrapolaVolumeVene``` vengono impostati harcoded i parametri:
- ```offsetPelle = 10```
- ```offsetPalmo = 200```
Bisogna capire se questa è la soluzione ottimale...


## OSSERVAZIONE SU PARAGRAFO: 7.5.1 Calcolo del vettore fine binarizzazione
Viene detto che: "Per evitare di considerare componenti non di interesse ma conservare solo le vene è stato provato che la media dei primi due massimi riesce a considerare bene la vena principale, obbiettivo di questa fase.". Ma non mi è chiaro da dove venga questa affermazione, e come faccio a validarla veramente...

Nella funzione ```contaCC(...)``` viene utilizzata come dimensione di una componente connessa per essere considerata ```20 pixel```. Bisognerebbe valuare il perchè di questa scelta e capire se è una scelta ottima/accettabile.

## OSSERVAZIONE SU PARAGRAFO: 7.5.3 Calcolo vettore distanza minima tra le vene e il palmo
Viene fatta la seguente assunzione "La coordinata Z del palmo meno la prima coordinata a partire dal palmo che contiene 3 pixel consecutivi pari a 1." come faccio a die che funziona in senso generale...

## OSSERVAZIONE SU PARAGRAFO: 7.8
La procedura è estremamente complicata bisognerebbe capire se è utile in senso generale e se magari può essere snellita.
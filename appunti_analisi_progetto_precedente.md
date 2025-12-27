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


## OSSERVAZIONE SU PARAGRAFO: 7.5 BINARIZZAZIONE

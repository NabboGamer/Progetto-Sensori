Descrizione cartella estrazioneTemplate
La cartella contiene tutti gli script e le funzioni necessarie ad estrarre il template 3D dal volume contenente il palmo della mano salvato come file .mat.
Per estrarre i template bisogna eseguire lo script "estrazioneTemplate" o "main"

"estrazioneTemplate"
Permette di estrarre il template di una determinata acquisizione. 
Specificare:
-utente
-acquisizione
-percorso in cui si trovano i file mat
-tipo (nel caso in cui si utilizzano i file mat presenti in metodoCCM)

"main"
Permette di estrarre in modo automatico più template.
Specificare:
-utenteStart: stringa corrispondente all'utente da cui si vuole partire ad estrarre i template in ordine alfabetico
-utenteEnd: stringa corrispondente all'utente finale per cui si vuole estrarre i template in ordine alfabetico
-stepAcquisizione: passo con cui vengono scelte le acquisizioni di un utente su cui estrarre i template. Se si vogliono estrarre 
tutti i template impostare step 1. Step 2 estrae un template ogni due e così via.
Questi parametri servono nel caso si voglia effettuare l'estrazione in contemporanea su più PC in parallelo.

"visualizzaTemplate"
Permette di visualizzare il volume contenente il template estratto sovrapposto al volume originale
Specificare:
-utente
-acquisizione
-percorso in cui si trovano i file mat
-tipo (nel caso in cui si utilizzano i file mat presenti in metodoCCM)

IMPORTANTE
Durante l'esecuzione di estrazioneTemplate vengono salvati i volumi risultanti da ogni fase nella cartella stepIntermedi.
La cartella contiene i risultati di ogni fase per ogni utente e acquisizione. In questo modo si risparmia tempo nell'estrazione del template qualora alcuni step precedenti siano stati già eseguiti. Le funzioni eseguono lo script se non è presente il risultato intermedio altrimenti lo caricano dalla cartella.
Il template 3D finale prende il nome di 'volAff.mat' (corrispondente al risultato dell'ultima fase del processo di estrazione, affinamento)



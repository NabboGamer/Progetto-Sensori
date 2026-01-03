Descrizione cartella "matching"
In questa cartella sono presenti tutti gli script necessari ad effettuare il matching 3D.

"identificazioneMatching3D"
Crea la tabella contenente gli score per il matching 3D delle acquisizioni selezionate. Salva la tabella nella cartella tabelle.
Specificare:
-nome: nome del file Excel contenente la lista delle acquisizioni per utente selezionate su cui effettuare il matching.
-pathCartella: percorso della cartella contente i file mat dei template3D suddivisi per utente.
-TS: lo script offre la possibilità di caricare una tabella contenente degli score calcolati in precedenza in modo tale da non ripetere
 l'esecuzione della funzione matching3Dtr.

"confrontaTemplate"
Permette di visualizzare la differenza di posizione e orientamento di due template.
Specificare:
-nameTemp1 : nome utente1
-acTemp1: acquisizione utente 1
-nameTemp2 : nome utente2
-acTemp2: acquisizione utente 2
-pathCartella: percorso in cui sono contenuti i template in formato .mat

"statistics_3D"
Selezionata la tabella e il percorso presso cui salvare i risultati stampa i grafici distribuzione genuini/impostori e FAR/FRR nonché il valore di EER.

La cartella "listeTemplate" contiene i file Excel con le acquisizioni selezionate su cui effettuare il matching.
-Il file "listaTemplateFinale" contiene le 159 acquisizioni utilizzate per calcolare il matching finale.
-Il file "listaTemplateProva" contiene le 76 acquisizioni utilizzate per effettuare la prima prova di matching e ricavare i tempi di calcolo del matching.
-Il file "listaTemplateEsclusi" contiene le acquisizioni che non sono valide ai fini del calcolo dello score e per questo sono state escluse.
-Il file "listaTemplateTEST" contiene delle acquisizioni di prova per controllare il funzionamento di identificazioneMatching3D.

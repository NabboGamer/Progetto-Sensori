function [volBinFinal, vecProcessed] = effettuaBinarizzazione(Mnp, volumePalmo, mascheraAcqua, mascheraNeroTotale, ...
                                                              indiciPalmoNoPelle, utente, acquisizione, yDim, show)
%EFFETTUABINARIZZAZIONE Pipeline completa di binarizzazione del volume del palmo
% per estrarre le strutture venose.
%
% Flusso generale:
% 1) Stima del parametro "fine" per ogni piano y (vecFineBin), cioè fino a che profondità
%    relativa rispetto al palmo conviene binarizzare.
% 2) Post-processing di vecFineBin (interpolazione + smoothing) -> vecProcessed.
% 3) Binarizzazione iniziale del volume usando vecProcessed (senza soglie incrementali).
% 4) Pulizia/separazione strutture nel volume binario (filtraggio morfologico).
% 5) Calcolo distanza minima vene↔palmo e stima diametri (vecDist, matriceDiametri).
% 6) Post-processing di vecDist (interpolazione + smoothing) -> vecDistProcessed.
% 7) Stima automatica della soglia iniziale (sogliaIniziale) tramite sweep e conteggio CC.
% 8) Binarizzazione finale incrementale usando sogliaIniziale e vincolo sui diametri.
% 9) Salvataggio su disco di volBinFinal per caching.
%
% Input:
%   Mnp                : volume del palmo pre-processato (tipicamente già ripulito da nero/acqua)
%   volumePalmo        : volume binario/maschera del palmo (usato per distanze vene↔palmo)
%   mascheraAcqua      : maschera acqua/background
%   mascheraNeroTotale : maschera totale delle zone da escludere (nero palmo + acqua)
%   indiciPalmoNoPelle : mappa (y,x) della superficie del palmo senza pelle
%   utente, acquisizione: usati per percorsi file e visualizzazioni
%   yDim               : numero di piani y attesi (lunghezza desiderata dei vettori)
%   show               : abilita grafici/debug (soprattutto nel fitting soglia)
%
% Output:
%   volBinFinal        : volume binario finale (vene estratte)
%   vecProcessed       : vettore "fine" processato (fase iniziale), utile per debug o step successivi

    % Stampa un titolo a console (utility)
    printTestoCornice("Binarizzazione del volume", '*');

    % Percorso cache per salvare/caricare il risultato finale
    folderPath = strcat(cd,'/stepIntermedi/', utente, '/', acquisizione);
    filename   = strcat(folderPath, '/volBinFinal', '.mat');

    % -------------------- 1) Calcolo e smoothing del vettore "fine" --------------------
    % vecFineBin: per ogni y, stima l'indice fine ottimo per la binarizzazione piano-per-piano
    vecFineBin = calcolaVecFineBin(Mnp, mascheraNeroTotale, mascheraAcqua, indiciPalmoNoPelle, utente, acquisizione);

    % vecProcessed: interpolazione NaN + smoothing -> vettore fine più regolare e completo (lunghezza yDim)
    vecProcessed = processaVettore(vecFineBin, 'iniziale', yDim, 0);

    % Se il volume binario finale è già stato calcolato in precedenza, lo carico e termino
    if exist(filename, 'file') == 2
        disp('Volume binarizzato presente nella cartella, caricamento...');
        load(filename, 'volBinFinal');
        return;
    end

    % -------------------- 2) Binarizzazione iniziale (senza soglie incrementali) --------------------
    % Chiamo binarizzaVolume in modalità "fase iniziale" (sogliaIniziale=0, sogliaFinale=0).
    % matriceDiametri qui non serve -> passo 0.
    volBin = binarizzaVolume(Mnp, mascheraNeroTotale, indiciPalmoNoPelle, vecProcessed, 0, 0, 0);

    % Pulizia/regularizzazione del volume binario iniziale per eliminare rumore e separare strutture
    volumeSeparato = separaStrutture(volBin, utente, acquisizione, 0);

    % -------------------- 3) Stima distanza vene↔palmo e diametri --------------------
    % vecDist: per ogni y, distanza minima vene-palmo (in voxel)
    % matriceDiametri: diametri stimati + distanze associate (usati nel fitting finale)
    [vecDist, matriceDiametri] = calcolaMinDistVenePalmo(volumeSeparato, volumePalmo, utente, acquisizione);

    % Smusso anche il vettore distanze per ottenere un andamento più regolare e senza NaN
    vecDistProcessed = processaVettore(vecDist, 'finale', yDim, 0);

    % -------------------- 4) Stima automatica della soglia iniziale --------------------
    % Trova una soglia iniziale "buona" facendo uno sweep di soglie e analizzando il numero di CC valide
    sogliaIniziale = calcolaSogliaIniziale(Mnp, mascheraNeroTotale, indiciPalmoNoPelle, vecDistProcessed, show);

    % -------------------- 5) Binarizzazione finale (incrementale) --------------------
    % Ora binarizzo di nuovo il volume, in modalità "fase finale":
    % - uso vecDistProcessed come vecFine (profondità per piano)
    % - uso matriceDiametri per stimare/raffinare una costante di diametro vene
    % - uso sogliaIniziale come soglia di partenza e 255 come soglia finale
    volBinFinal = binarizzaVolume(Mnp, mascheraNeroTotale, indiciPalmoNoPelle, vecDistProcessed, ...
                                  matriceDiametri, sogliaIniziale, 255, show);

    % -------------------- 6) Salvataggio del risultato --------------------
    % Creo la cartella se non esiste
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end

    % Salvo solo se il volume non è vuoto (nnz = numero di voxel non-zero/true)
    if nnz(volBinFinal) > 0
        save(filename, 'volBinFinal');
        disp('Volume binarizzato salvato con successo');
    else
        disp('Volume binarizzato vuoto NON salvato');
    end

end

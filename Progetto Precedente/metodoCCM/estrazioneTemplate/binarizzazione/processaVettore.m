function [vecProcessed] = processaVettore(vecFine, fase, yDim, show)
%PROCESSAVETTORE Post-processa un vettore (tipicamente vecFineBin) per renderlo
% continuo e meno rumoroso.
%
% Obiettivi:
% 1) Riempire i valori mancanti (NaN) tramite interpolazione.
% 2) Smussare il vettore per ridurre il rumore e ottenere un andamento regolare.
% 3) (Opzionale) Visualizzare il confronto tra vettore grezzo e varie tecniche di smoothing.
% 4) Garantire che il vettore in uscita abbia lunghezza esattamente yDim
%    (se mancano campioni in coda, li replica con l'ultimo valore disponibile).
%
% Input:
%   vecFine : vettore originale (può contenere NaN e rumore)
%   fase    : stringa/numero usato solo nel titolo del grafico
%   yDim    : lunghezza desiderata del vettore in uscita (tipicamente numero di piani y)
%   show    : 1 per mostrare il grafico comparativo, 0 altrimenti
%
% Output:
%   vecProcessed : vettore interpolato + smussato (qui si seleziona la variante rlowess)

    % -------------------- 1) Interpolazione dei NaN --------------------
    % Costruisco l'asse x (indici del vettore)
    x = 1:length(vecFine);

    % Interpolo linearmente i valori mancanti (NaN) usando solo i campioni validi.
    % Nota: interp1 restituisce NaN anche agli estremi se mancano punti per interpolare lì.
    vettore_interpolato = interp1(x(~isnan(vecFine)), vecFine(~isnan(vecFine)), x, 'linear');

    % Se rimangono NaN all'inizio (tipico quando i primi valori di vecFine sono NaN),
    % li riempio copiando il primo valore valido disponibile (vecFine(valoriNan+1)).
    valoriNan = size(vettore_interpolato(isnan(vettore_interpolato)), 2);
    if valoriNan > 0
        disp(['*********', num2str(valoriNan), ' Valori mancanti all''inizio del vettore!*********'])
        for i = 1:valoriNan
            vettore_interpolato(i) = vecFine(valoriNan+1);
        end
    end

    % -------------------- 2) Smoothing (riduzione rumore) --------------------
    % smoothing = ampiezza finestra / livello di levigatura.
    % Valore alto -> andamento più regolare ma rischio di "appiattire" dettagli locali.
    smoothing = 150;

    % Calcolo diverse versioni smussate per confronto (non tutte vengono poi usate):
    vec_moving   = smooth(vettore_interpolato, smoothing, 'moving');   % media mobile
    vec_lowess   = smooth(vettore_interpolato, smoothing, 'lowess');   % regressione locale robusta
    vec_loess    = smooth(vettore_interpolato, smoothing, 'loess');    % come lowess ma con fit quadratico
    vec_sgolay   = smooth(vettore_interpolato, smoothing, 'sgolay');   % Savitzky-Golay
    vec_rlowess  = smooth(vettore_interpolato, smoothing, 'rlowess');  % lowess robusta
    vec_rloess   = smooth(vettore_interpolato, smoothing, 'rloess');   % loess robusta
    vec_gaussian = imgaussfilt(vettore_interpolato, smoothing/3);      % filtro gaussiano 1D

    % -------------------- 3) Plot di confronto (opzionale) --------------------
    if show == 1
        figure;
        plot(vecFine, 'b');                 % vettore originale (con NaN e rumore)
        hold on;

        % Sovrappongo le varie curve smussate per scegliere visivamente la migliore
        plot(vec_moving,   'r', 'LineWidth', 2);
        plot(vec_lowess,   'g', 'LineWidth', 2);
        plot(vec_loess,    'b', 'LineWidth', 2);
        plot(vec_sgolay,   'k', 'LineWidth', 2);
        plot(vec_rlowess,  'c', 'LineWidth', 2);
        plot(vec_rloess,   'm', 'LineWidth', 2);
        plot(vec_gaussian, 'y', 'LineWidth', 2);

        xlabel('Piano XZ (y)');
        ylabel('Coordinata fine binarizzazione (z)');
        title(['Confronto vettore fine binarizzazione originale e smussato fase ', fase]);
        legend('originale','moving','lowess','loess','sgolay','rlowess','rloess','gaussian');
        hold off;
    end

    % Scelgo come uscita la versione smussata robusta (meno sensibile a picchi/outlier)
    vecProcessed = vec_rlowess;

    % -------------------- 4) Forzo la lunghezza a yDim --------------------
    % Se il vettore processato è più corto di yDim, appendo valori in coda
    % replicando l'ultimo valore (padding costante).
    dimVecProcessed = size(vecProcessed, 1);
    componentiDaAggiungere = yDim - dimVecProcessed;

    if componentiDaAggiungere > 0
        disp(['*********', num2str(componentiDaAggiungere), ' Valori mancanti alla fine del vettore!*********'])
        vettoreNuovo = zeros(componentiDaAggiungere, 1);
        vettoreNuovo(:,:) = vecProcessed(end);
        vecProcessed = [vecProcessed; vettoreNuovo];
    end

end

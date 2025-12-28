function [soglia] = calcolaSogliaBinGauss(vec, smoothing, step, show)
%CALCOLASOGLIABINGAUSS calcola automaticamente una soglia di binarizzazione a partire da una curva
%  vec = numero di componenti connesse (CC) ottenute variando la soglia.
%
%  Idea: la curva #CC vs soglia spesso è rumorosa. Si applica uno smoothing,
%  poi si analizza la derivata (diff) per trovare un punto "caratteristico"
%  (qui: il primo massimo locale della derivata), che corrisponde a una zona
%  dove la curva cambia rapidamente (transizione tra troppa frammentazione e
%  perdita di strutture).
%
% INPUT:
%   vec       : vettore (tipicamente lungo N soglie testate) con #CC per soglia
%   smoothing : parametro di smussamento (finestra o intensità a seconda del metodo)
%   step      : fattore di scala per convertire indice -> valore reale di soglia
%   show      : flag per mostrare grafici diagnostici
%
% OUTPUT:
%   soglia    : soglia calcolata (in scala reale, moltiplicata per step)

    % --- 1) Smussamento del vettore con diversi metodi ---
    % Nota: qui calcoli più versioni, ma poi ne usi solo una (loess).
    % Questo può essere utile in fase di test per confrontare i risultati.
    % vec_moving   = smooth(vec, smoothing, 'moving');
    % vec_lowess   = smooth(vec, smoothing, 'lowess');
    vec_loess    = smooth(vec, smoothing, 'loess');
    % vec_sgolay   = smooth(vec, smoothing, 'sgolay');
    % vec_rlowess  = smooth(vec, smoothing, 'rlowess');
    % vec_rloess   = smooth(vec, smoothing, 'rloess');
    % vec_gaussian = imgaussfilt(vec, smoothing/3);

    % Scelta del vettore smussato da usare per la stima soglia
    vecProcessed = vec_loess;

    % --- 2) Analisi della derivata discreta ---
    % dy(k) = vecProcessed(k+1) - vecProcessed(k)
    % Evidenzia dove la curva cresce/decresce più rapidamente.
    dy = diff(vecProcessed);

    % --- 3) Ricerca di un "punto caratteristico" tramite picchi nella derivata ---
    % Trova i massimi locali di dy (zone di crescita rapida).
    % In pratica, il primo massimo viene usato come indice di soglia.
    [~, maxLocalIdx] = findpeaks(dy);

    % Prende il primo massimo locale: punto iniziale di transizione
    firstMax = maxLocalIdx(1);

    % --- 4) Calcolo soglia finale ---
    % Usa l'indice del primo massimo come soglia in "unità indice"
    soglia = round(firstMax);

    % Converte in scala reale: se le soglie esplorate sono step, 2*step, ...
    soglia = soglia * step;

    fprintf('Soglia binarizzazione gauss calcolata: %d\n', soglia);

    % --- 5) Plot diagnostici opzionali ---
    if show == 1
        figure;

        % Confronto curva originale e smussata (qui loess)
        subplot(2,1,1);
        plot(vec, 'b');
        hold on;
        plot(vec_loess, 'b', 'LineWidth', 2);
        xlabel('Soglia (indice)');
        ylabel('Numero CC');
        title('Confronto vettore numero CC originale e smussato');
        legend('originale','loess');
        hold off;

        % Derivata del vettore smussato
        subplot(2,1,2);
        plot(dy, 'b');
        xlabel('Soglia (indice)');
        ylabel('Derivata vettore CC');
        title('Derivata numero CC del vettore smussato');

        sgtitle('Grafici fitting parametro soglia binarizzazione gauss');
    end
end

function visualizzaCentroidi(pianoXZ,y,centroids,inFigure)
    
    if inFigure == 1
        figure;
    end

    imshow(pianoXZ, []);
    
    set(gca, 'YDir', 'normal');  % Imposta l'asse Y normale (non invertito)
    
    xlabel('Asse X');
    ylabel('Asse Z');
    
    axis on;
    
    title(['Piano XZ per y = ',num2str(y)]);

    hold on
    plot(centroids(:,1),centroids(:,2),'r*')
    hold off
    

end

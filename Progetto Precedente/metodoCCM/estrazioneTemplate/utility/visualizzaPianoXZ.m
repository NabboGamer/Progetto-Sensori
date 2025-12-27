function visualizzaPianoXZ(pianoXZ,y,inFigure)
    
    if inFigure == 1
        figure;
    end

    imshow(pianoXZ, [],'InitialMagnification', 'fit');
    set(gca, 'YDir', 'normal');
    
    xlabel('Asse X');
    ylabel('Asse Z');
    
    axis on;
    
    title(['Piano XZ per y = ',num2str(y)]);
    

end


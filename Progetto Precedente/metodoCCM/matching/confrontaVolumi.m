function confrontaVolumi(vol1,vol2)
    %Visualizza due volumi con colori diversi, verde e rosso.
    redChannel = vol1;  
    greenChannel = vol2; 
    blueChannel = zeros(size(vol2)); 
    combinedVolume = cat(4, redChannel, greenChannel, blueChannel);
    volshow(combinedVolume);

end


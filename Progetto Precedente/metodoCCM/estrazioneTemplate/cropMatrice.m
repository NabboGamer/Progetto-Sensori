function [M_cropped,X_cropped,Y_interpolated_cropped,Y_interpolated] = cropMatrice(M,X,Y)
%Ridimensiona la matrice M effettuando un cropping delle dimensioni X e Y

    % 1.1) Crop della matrice M e del vettore X
    xDim = size(M,2);
    yInterpDim = size(M,3);
    yDim = size(Y,1);
    
    final_size_X = 650;
    final_size_Y = 650;
    
    startX = floor((xDim - final_size_X) / 2) + 1;
    endX = startX + final_size_X - 1;
    startY = floor((yInterpDim - final_size_Y) / 2) + 1;
    endY = startY + final_size_Y - 1;
    
    M_cropped = M(:,startX:endX,startY:endY);
    X_cropped = X(startX:endX,:);
    
    % 1.2) Interpolazione del vettore Y e successivo crop
    y_original = linspace(1, yDim, yDim);
    y_new = linspace(1, yDim, yInterpDim);
    Y_interpolated = interp1(y_original, Y, y_new, 'linear');
    Y_interpolated = Y_interpolated(:);
    Y_interpolated_cropped = Y_interpolated(startY:endY,:);

end


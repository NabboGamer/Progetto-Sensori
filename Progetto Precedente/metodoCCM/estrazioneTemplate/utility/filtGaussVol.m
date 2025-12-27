function [volIntGaussBin] = filtGaussVol(vol,size,thresBin)

    volInt = uint8(vol);
    volInt(volInt == 1) = 255;
    volIntGauss = imgaussfilt3(volInt,size);
    volIntGaussBin = binarizza(volIntGauss,'manuale',thresBin);

end

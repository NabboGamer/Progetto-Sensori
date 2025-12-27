function [volLow,volHigh] = dividiCCvolume(volume,dim)

    CC = bwconncomp(volume);
    tabCC = regionprops3(CC, 'Volume');
    CC_l = find([tabCC.Volume] < dim);
    CC_h = find([tabCC.Volume] >= dim);
    labeledVolume = labelmatrix(CC);
    volLow = ismember(labeledVolume, CC_l);
    volHigh = ismember(labeledVolume, CC_h);

end


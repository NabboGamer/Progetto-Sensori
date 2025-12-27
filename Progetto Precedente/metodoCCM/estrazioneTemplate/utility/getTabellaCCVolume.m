function [tabellaCC] = getTabellaCCVolume(volume)

    CC = bwconncomp(volume);
    tabellaCC = regionprops3(CC, 'Volume');

end


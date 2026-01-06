function [volumePalmo,Mnp,mascheraAcqua,mascheraNeroPalmo,mascheraNeroTotale,indiciPalmoNoPelle] = estrapolaVolumeVene(M,Z,utente,acquisizione,offsetPalmo,show)
%%Estrapola la porzione di volume acquisito contenente il pattern venoso

    % 2.1) Rilevazione del palmo
    % soglia di intensità per la rilevazione della superficie (0 - 255)
    tresh = 64;
    filter_siz = 20;
    
    % Parametri di profondità e spessore in mm
    depth = 0.2;
    thick = 0.2;
    trans_flag = 1; % Flag per abilitare/disabilitare la trasparenza

    % Costruisco un volume di "quote" (SURF) grande quanto M:
    % in ogni voxel metto un numero che rappresenta la sua posizione lungo z.
    % Esempio (colonna z): prima del flip sarebbe [0,1,2,...,N-1].
    %
    % Con flip(...,1) la colonna diventa [N-1, N-2, ..., 0]:
    % così i voxel più vicini alla superficie (secondo la convenzione dei dati)
    % hanno un valore di SURF più alto.
    %
    % Questo è utile perché dopo maschero con la soglia:
    %   SURF(M <= tresh) = 0
    % e poi con:
    %   maxSurf = squeeze(max(SURF));
    % il massimo lungo z restituisce, per ogni (x,y), l'indice del voxel sopra soglia
    % più "superficiale" (cioè il primo palmo incontrato lungo la profondità).
    SURF = flip( repmat( uint16((0:size(M,1)-1))', [1, size(M,2), size(M,3)] ), 1 );
    
    % Maschero SURF usando l'intensità di M: dove M è sotto soglia (acqua/rumore)
    % azzero SURF, lasciando indici di profondità solo nei voxel "validi" (M > tresh).
    SURF(M <= tresh) = 0;
    
    % Essendo SURF una mappa di indici, il max restituisce l'indice di profondità
    % del voxel sopra-soglia più vicino alla superficie (secondo la convenzione data dal flip).
    % Il risultato è una mappa 2D (x-y) della superficie stimata.
    maxSurf = squeeze(max(SURF));
    
    % Libero memoria: SURF è grande quanto M e non serve più dopo maxSurf.
    clear SURF
    
    % Filtraggio passa-basso sulla superficie
    h = fspecial('average', [filter_siz filter_siz]); % Crea un filtro medio
    surf_f = imfilter(maxSurf, h, 'replicate');  % Applica il filtro
    
    % Conversione da millimetri a indici di slice lungo z:
    % Z è il vettore delle profondità, quindi dz = Z(2)-Z(1) è il passo (mm/slice).
    % Dividendo una distanza in mm per dz ottengo quante slice corrispondono a:
    % - depth_ind: offset in profondità rispetto alla superficie stimata
    % - thick_ind: spessore (in numero di slice) della fascia considerata
    depth_ind = round(depth / (Z(2)-Z(1)));
    thick_ind = round(thick / (Z(2)-Z(1)));
    
    % Indice massimo valido lungo z (coerente con la numerazione 0..Nz-1 usata in SURF)
    max_dpth = size(M,1) - 1;
    
    % Sposto la superficie stimata (surf_f) di "depth_ind" slice per ottenere una quota
    % di riferimento leggermente più interna/esterna (a seconda della convenzione z),
    % e limito il risultato per non superare il fondo del volume.
    surf_filt = min(surf_f - depth_ind, max_dpth);
    
    % In questa sezione costruisco A: una "mappa alpha" (0..255) grande quanto M.
    % A non serve come intensità, ma come maschera graduata attorno alla superficie stimata:
    % - A = 0    : voxel da considerare "sopra" la fascia (da rendere trasparente / eliminare)
    % - A = 255  : voxel "sotto" la fascia (da mantenere opaco / valido)
    % - valori intermedi: transizione morbida (rampa) in uno spessore definito da thick_ind.
    
    % Inizializzo A con la stessa dimensione di M (valori poi sovrascritti)
    A = M;
    
    % DPTH_IND: volume di indici di profondità (come SURF), stesso size di M.
    % Ogni voxel contiene l'indice z (ribaltato con flip per rispettare la convenzione di profondità).
    DPTH_IND = flip(repmat(uint16((0:size(M,1)-1))', [1, size(M,2), size(M,3)]), 1);
    
    % Definisco lo spessore della fascia di transizione (in numero di slice).
    % ramp_dim è reso pari (2*round(thick_ind/2)) così la fascia è simmetrica attorno alla superficie.
    ramp_dim = 2 * round(thick_ind / 2);
    
    % ramp: valori 0..255 distribuiti linearmente su ramp_dim+1 campioni
    % (alpha crescente dalla parte "sopra" alla parte "sotto" la superficie).
    ramp = round((0:ramp_dim) / ramp_dim * 255);
    
    % Q: offset di profondità centrati in 0 (da -ramp_dim/2 a +ramp_dim/2),
    % usati per applicare la rampa intorno alla superficie.
    Q = (-ramp_dim/2) : 1 : (ramp_dim/2);
    
    % Replico la superficie 2D (surf_filt) lungo z per poter fare confronti voxel-per-voxel.
    % surf_filt_matrix ha dimensioni [Nz, Nx, Ny] come M.
    surf_filt_matrix = repmat(reshape(surf_filt, [1, size(surf_filt)]), [size(M,1), 1, 1]);
    
    % Imposto i due "piatti" della maschera:
    % - sopra la fascia (più lontano di ramp_dim/2 dalla superficie): A = 0
    % - sotto la fascia (più lontano di ramp_dim/2): A = 255
    A((DPTH_IND - ramp_dim/2) > surf_filt_matrix) = 0;
    A((DPTH_IND + ramp_dim/2) < surf_filt_matrix) = 255;
    
    % Se abilitata la trasparenza (trans_flag), applico la rampa nella fascia centrale:
    % per i voxel che stanno esattamente a distanza Q(i) dalla superficie,
    % assegno ad A un valore intermedio ramp(i) per una transizione graduale 0->255.
    if trans_flag == 1
        for i = 1:length(Q)
            A((DPTH_IND + Q(i)) == surf_filt_matrix) = ramp(i);
        end
    end
    
    % Visualizzazione del volume di partenza
    Mstart = M;
    mascheraAcqua = (A <= tresh);
    Mstart(mascheraAcqua) = 0;

    % Ri-oriento il volume e la maschera per portarli nella convenzione attesa dalle
    % funzioni di visualizzazione/elaborazione successive:
    % 1) flip(...,1): inverto l'asse della profondità (dim 1) per avere il verso z coerente
    %    (es. superficie in alto / profondità crescente nel verso desiderato).
    % 2) permute(...,[3 2 1]): riordino le dimensioni da [z, x, y] a [y, x, z]
    %    (cioè scambio gli assi in modo che la terza dimensione diventi la profondità).
    % Le stesse trasformazioni vanno applicate anche a mascheraAcqua per mantenerla allineata a Mstart.
    Mstart = flip(Mstart, 1);
    Mstart = permute(Mstart, [3,2,1]);
    mascheraAcqua = flip(mascheraAcqua, 1);
    mascheraAcqua = permute(mascheraAcqua, [3,2,1]);
    
    % Visualizzo il volume di partenza (già ripulito dall'acqua) nel nuovo orientamento
    graficoVolshow(Mstart, 'Mstart - post rimozione acqua', utente, acquisizione, show);

    %Calcolo le maschere e il volume palmo 
    offsetPelle = 10;
    [volumePalmo,mascheraNeroPalmo,mascheraNeroTotale] = calcolaMaschere(Mstart,mascheraAcqua,offsetPalmo,offsetPelle);
    mascheraNeroPalmoAcqua = mascheraNeroPalmo | mascheraAcqua;
    Mnp = Mstart;
    Mnp(mascheraNeroPalmoAcqua) = 0;
    graficoVolshow(Mnp,'Mnp - post rimozione nero palmo', utente, acquisizione, show);

    % Trova l'indice del primo elemento diverso da zero lungo la terza dimensione
    [~, indiciPalmo] = max(volumePalmo ~= 0, [], 3);
    indiciPalmoNoPelle = indiciPalmo-offsetPelle;

end


function [movingRotGpu] = rotTemplate(movingGpu,orientation_f,orientation_m)
%%ROTTEMPLATE Ruota un volume 3D (su GPU) in base alla differenza tra due orientamenti.
%
%   Dati due orientamenti (target e moving) espressi come angoli di Eulero,
%   calcola la differenza tra i due e ruota il volume "movingGpu" di tali
%   angoli, applicando tre rotazioni successive attorno agli assi X, Y e Z.
%
%   INPUT:
%     movingGpu      - Volume 3D (tipicamente gpuArray) da ruotare.
%     orientation_f  - Orientamento di riferimento/target (vettore 1x3).
%                      Convenzione usata qui: [z, x, y] (vedi mapping sotto).
%     orientation_m  - Orientamento del volume moving (vettore 1x3).
%                      Stessa convenzione di orientation_f.
%
%   OUTPUT:
%     movingRotGpu   - Volume ruotato (stessa classe/device di movingGpu).
%
%   NOTE:
%   - Il mapping a struct impone l'ordine: z <- (1), x <- (2), y <- (3).
%     Quindi i vettori orientation_* sono interpretati come:
%       z = orientation_*(1), x = orientation_*(2), y = orientation_*(3).
%   - Le rotazioni sono eseguite con imrotate3 in modalità 'crop':
%     l'output mantiene la stessa dimensione del volume di input, ma
%     porzioni del contenuto possono venire tagliate agli estremi.
%   - L'ordine delle rotazioni (X poi Y poi Z) influenza il risultato
%     (le rotazioni 3D non commutano).
%

    % Costruisco le terne di angoli in una struct per chiarezza, rimappando
    % il vettore [?, ?, ?] nella convenzione scelta: x=2, y=3, z=1.
    euler_f = struct('x', orientation_f(2), 'y', orientation_f(3), 'z', orientation_f(1));
    euler_m = struct('x', orientation_m(2), 'y', orientation_m(3), 'z', orientation_m(1));

    % Differenza tra orientamento target e orientamento moving:
    % questi sono gli angoli (in gradi) con cui ruotare il volume.
    diff = struct('x', euler_f.x - euler_m.x, ...
                  'y', euler_f.y - euler_m.y, ...
                  'z', euler_f.z - euler_m.z);

    % Rotazione attorno all'asse X (vettore direzione [1 0 0]).
    % 'crop' mantiene le dimensioni originali del volume.
    movingRotGpu = imrotate3(movingGpu, diff.x, [1 0 0], 'crop');

    % Rotazione attorno all'asse Y.
    movingRotGpu = imrotate3(movingRotGpu, diff.y, [0 1 0], 'crop');

    % Rotazione attorno all'asse Z.
    movingRotGpu = imrotate3(movingRotGpu, diff.z, [0 0 1], 'crop');

end

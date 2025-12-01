%--------------------------------------------------------------------------
%         
% Fonction d'extraction de la position à partir d'un fichier d'observation
% Rinex v2.11
%
%--------------------------------------------------------------------------
% Fonction qui permet de récupérer les coordonnées contenues dans un
% fichier d'observation Rinexe
% Données d'entrée : obsfile (correspond au nom du fichier d'observation)

function  PosXYZ = rinexeobs2p11_pos(obsfile)

fide = fopen(obsfile);

% Dans le header on va chercher l'information qui nous intéresse

numlign = 1;

line = fgetl(fide);                                         % On récupère la première ligne
TrouveObs = strfind(line,'APPROX POSITION XYZ');            % Condition d'arrêt

while isempty(TrouveObs)
    line = fgetl(fide);                                     % recherche ligne à ligne
    numlign = numlign+1;                                    % à chaque fois qu'on lit une ligne on ajoute 1 au nombre de lignes
    TrouveObs = strfind(line,'APPROX POSITION XYZ');        % on cherche la première chaîne de caractères indiquant la ligne où se trouve le nombre d'observables
    
    
end

X = str2double(line(1:14));                              % On récupère X
Y = str2double(line(15:28));                             % On récupère Y
Z = str2double(line(29:42));                             % On récupère Z

PosXYZ = [X;Y;Z];

fclose all;

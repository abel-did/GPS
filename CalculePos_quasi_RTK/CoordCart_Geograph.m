% -------------------------------------------------------------------------
% 
%   Fonction pour convertir les coordonnées cartésiennes (m)
%   en coordonnées géographiques (en dégrés)
% 
% -------------------------------------------------------------------------

function [lat, long, alt] = CoordCart_Geograph(X,Y,Z)

a = 6378137;
b = 6356752.3142;
ec = 0.00669437999014;
eprimec = 0.00673949674228;
Pi = 3.14159265358979;

% Calcul de la longitude
lambda = atan2(Y, X);

% Calcul de la Latitude
p = (X ^ 2 + Y ^ 2) ^ 0.5;

tanu = (Z / p) * (a / b);

finboucle = 0;

while finboucle == 0

    cosu = (1 / (1 + tanu ^ 2)) ^ 0.5;
    sinu = (1 - cosu ^ 2) ^ 0.5;

    tanPhi = (Z + eprimec * b * sinu ^ 3) / (p - ec * a * cosu ^ 3);

    if abs(tanu - (b / a) * tanPhi) < 0.0000000001 

        finboucle = 1;
        
    else
        
        tanu = (b / a) * tanPhi;
    
    end

end

phi = atan(a / b * tanu);

% Calcul de l'altitude
N = a / (1 - ec * sin(phi) ^ 2) ^ 0.5;

h = p / cos(phi) - N;

lat = 180 / Pi * phi;
long = 180 / Pi * lambda;
alt = h;
% -------------------------------------------------------------------------
% 
%   Fonction pour convertir les coordonnées géographiques (en dégrés) 
%   en coordonnées cartésiennes
% 
% -------------------------------------------------------------------------

function [X, Y, Z] = CoordGeograph_Cart(lat,long,alt)

a = 6378137;
ec = 0.00669437999014;
Pi = 3.14159265358979;

phi = lat * Pi / 180;
lambda = long * Pi / 180;

% Calcul de X

X = a * cos(lambda) / (1 + (1 - ec) * tan(phi) ^ 2) ^ 0.5 + alt * cos(lambda) * cos(phi);

% Calcul de Y

Y = a * sin(lambda) / (1 + (1 - ec) * tan(phi) ^ 2) ^ 0.5 + alt * sin(lambda) * cos(phi);

% Calcul de Y

Z = a * (1 - ec) * sin(phi) / (1 - ec * sin(phi) ^ 2) ^ 0.5 + alt * sin(phi);


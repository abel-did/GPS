%--------------------------------------------------------------------------
% Fonction pour Calculer la Dilution de précision géométrique
%
%--------------------------------------------------------------------------

function [GDOP, PDOP, HDOP, VDOP, TDOP] = CalculDOP(CoordSats,nSat)

H = zeros(nSat,4);

% le repère est centré sur la position

X = 0;
Y = 0;
Z = 0;

% Calcul des distances Satellites/Récepteur
    
% Formation de la matrice H
    
for i=1:nSat
    Dist = (( CoordSats(3*(i-1)+1,1) - X)^2 + ( CoordSats(3*(i-1)+2,1) - Y)^2 + ( CoordSats(3*(i-1)+3,1) - Z)^2)^0.5;
    
    H(i,1)= ( CoordSats(3*(i-1)+1,1) - X)/Dist;
    H(i,2)= ( CoordSats(3*(i-1)+2,1) - Y)/Dist;        
    H(i,3)= ( CoordSats(3*(i-1)+3,1) - Z)/Dist;
    H(i,4) = 1;
end

MDop = inv(H'*H);

GDOP = (MDop(1,1)^2+MDop(2,2)^2+MDop(3,3)^2+MDop(4,4)^2)^0.5;
PDOP = (MDop(1,1)^2+MDop(2,2)^2+MDop(3,3)^2)^0.5;
HDOP = (MDop(2,2)^2+MDop(3,3)^2)^0.5;
VDOP = (MDop(1,1)^2)^0.5;
TDOP = (MDop(4,4)^2)^0.5;




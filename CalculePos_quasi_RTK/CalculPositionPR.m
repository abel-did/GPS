%--------------------------------------------------------------------------
% Fonction pour Calculer le point de manière classique
%
%--------------------------------------------------------------------------

function [X, Y, Z, T] = CalculPositionPR(CoordSats,nSat,PosInit,PRptLis)

H = zeros(nSat,4);
DistEst = zeros(nSat,1);
Epsilon = 0.0001;

SommeDelta = 1;

Xest = PosInit(1);
Yest = PosInit(2);
Zest = PosInit(3);
Test = PosInit(4);

n=1;            % nombre de tours de boucle

while SommeDelta > Epsilon && n < 10
    
   % Calcul des Distances estimées
    for i=1:nSat
    
        DistEst(i) = ( (CoordSats(3*(i-1)+1,1) - Xest)^2 + (CoordSats(3*(i-1)+2,1) - Yest)^2 + (CoordSats(3*(i-1)+3,1) - Zest)^2 )^0.5;
        
    end
    
    % Formation de la matrice H
    
    for i=1:nSat
        H(i,1)= ( CoordSats(3*(i-1)+1,1) - Xest)/DistEst(i);
        H(i,2)= ( CoordSats(3*(i-1)+2,1) - Yest)/DistEst(i);        
        H(i,3)= ( CoordSats(3*(i-1)+3,1) - Zest)/DistEst(i);
        H(i,4) = 1;
    end
    
    VectDelta = ((inv(H'*H))*H')*(DistEst + Test*ones(nSat,1) - PRptLis);  % inv(Ht*H)*Ht*VecteurMesures
    
    Xest = Xest + VectDelta(1);
    Yest = Yest + VectDelta(2);
    Zest = Zest + VectDelta(3);
    Test = Test - VectDelta(4);
    
    SommeDelta = norm(VectDelta);
    n =n+1;

end

X = Xest;
Y = Yest;
Z = Zest;
T = Test;




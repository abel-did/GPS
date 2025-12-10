% -------------------------------------------------------------------------
%
%                   Calcul des positions des satellites
% 
% -------------------------------------------------------------------------



temps = DonneesPRbase(1:t_total,1);   % on a une variable "Temps" qui contient les instants de calcul de chaque satellite

% Préparation du tableau des coordonnées

CoordSats = zeros(nSat*3,t_total);

Diffdist_pdist = zeros(nSat,t_total);

% Initialisation du Calcul

CorPRHorlSatbase = zeros(nSat,t_total);

corPR = 0;

PRCodebase = zeros(nSat,t_total);
PRCodemobile = zeros(nSat,t_total);

% Calcul des positions des satellites pour la station de base

for t=0:t_total-1
    for i = 1:nSat
        if SatDispo(t+1,i) == 1 % Pour que le calcul soit fait, il faut qu'il y ait une pseudodistance pour la station et le mobile, donc que le satellite soit disponible sinon les coordonnées seront égales à 0,0,0
        
            % Boucle pour calculer la position des satellites tenant compte de la propagation  
        
            % On calcule les erreurs d'horloge et effets relativistes
            corPR = Correction_Horloge_Satellite(temps(t+1), Ephem(i,:));
        
            CorPRHorlSatbase(i,t+1) = corPR;              % On stocke la correction
            pseudodist = DonneesPRbase(t+1,2*i)+c*corPR;  % On récupère la pseudodistance corrigée     
            PRCodebase(i,t+1) = pseudodist;               % On stocke la pseudodistance corrigée de ces effets        
            dpropag = pseudodist;                         % On utilise la pseudodistance (pas terrible sans calculer le point)
            
            pseudodist = DonneesPRmobile(t+1,2*i)+c*corPR;% Pareil pour le mobile 
            PRCodemobile(i,t+1) = pseudodist;             % 

            % On fait un premier calcul des coordonnées du satellite      
        
            [Xs, Ys, Zs] = CalculEphemeride(temps(t+1)-pseudodist/299792458,Ephem(i,:));
            
            % Calcul de la position du satellite (dans le repère ECEF actuel qui a tourné entre l'émission et l'envoi)
        
            Rot_X = e_r_corr(dpropag/c, [Xs;Ys;Zs]);
    
            Xs = Rot_X(1);
            Ys = Rot_X(2);
            Zs = Rot_X(3);
        
                          
            CoordSats(1+(i-1)*3,t+1) = Xs;
            CoordSats(2+(i-1)*3,t+1) = Ys;
            CoordSats(3+(i-1)*3,t+1) = Zs;
        end
   
    end
end






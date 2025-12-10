% -------------------------------------------------------------------------
%
%                   Formater les données du ublox M8T
% 
% -------------------------------------------------------------------------

% Les fichiers d'entrée s'appellent :
%
%        - "Donnees_Ephem.xlsx"
%        - "Donnees_PR_Mob.xlsx"
%        - "Donnees_PR_Base.xlsx"
%
% On les récupère dans le dossier dédié appelé Fichiers xlsx

nechmax = 1200;    % nombre d'échantillons correspondant à 20 minutes d'enregistrement

% On lit les fichiers
Ephem = zeros(32,24);
Eph_reel = readmatrix('..\Fichiers xlsx\Donnees_Ephem.xlsx');
nligne = length(Eph_reel(:,1));
Ephem(1:nligne,:) = Eph_reel; 

% Ephem est prête à servir pour le calcul des positions des satellites

% On récupère les PR code et phase du mobile

DonneesPRmobile = readmatrix("..\Fichiers xlsx\Donnees_PR_Mob.xlsx");

% On récupère les PR code et phase de la station de base

DonneesPRbase = readmatrix("..\Fichiers xlsx\Donnees_PR_Base.xlsx");

% On prend le plus petit des nombres de satellites des deux récepteurs
nbase = DonneesPRbase(1,1);
nmob  = DonneesPRmobile(1,1);

% Récupère les numéros de satellites visibles de la base
numeroSatbase = zeros(1,32);
for n=1:nbase    
    numeroSatbase(DonneesPRbase(1,1+2*(n-1)+1)) = 1;
end
numeroSatmobile = zeros(1,32);
for n=1:nmob
    numeroSatmobile(DonneesPRmobile(1,1+2*(n-1)+1)) = 1;
end


% On détermine t0_GPS en prenant le plus grand entre les deux premières
% valeur de temps GPS pour chaque récepteur

t0_GPS = max(DonneesPRbase(2,1),DonneesPRmobile(2,1));

% On détermine la taille exacte, ainsi que le tinitial de chacun des
% enregistrements
t_init_base = 2;
t_init_mobile = 2;
t_fin_mobile = 0;
t_fin_base = 0;

for t=2:nechmax+1
    if DonneesPRmobile(t,1) < t0_GPS && DonneesPRmobile(t,1) ~= 0
        t_init_mobile = t_init_mobile +1;
    end

    if t == nechmax+1 && DonneesPRmobile(t,1)
        t_fin_mobile = t;

    elseif DonneesPRmobile(t,1) == 0 && DonneesPRmobile(t-1,1) ~= 0
        t_fin_mobile = t-1;
    end

    if DonneesPRbase(t,1) < t0_GPS && DonneesPRbase(t,1) ~= 0
        t_init_base = t_init_base +1;
    end

    if t == nechmax+1 && DonneesPRbase(t,1) ~= 0 
        t_fin_base = t;

    elseif DonneesPRbase(t,1) == 0 && DonneesPRbase(t-1,1) ~= 0
        t_fin_base = t-1;
    end
end

T_fin_mobile = DonneesPRmobile(t_fin_mobile,1);
T_fin_base = DonneesPRbase(t_fin_base,1);

DonneesPRbaseformat =  [ DonneesPRbase(1,:); DonneesPRbase(t_init_base:t_fin_base,:)];
DonneesPRmobileformat =  [ DonneesPRmobile(1,:); DonneesPRmobile(t_init_mobile:t_fin_mobile,:)];

DonneesPRbaseformat1 = DonneesPRbaseformat(:,1);
DonneesPRmobileformat1 = DonneesPRmobileformat(:,1);

Liste_Sat = 0;
nSat = 0;
for n=1:32

    if numeroSatmobile(n) == 1 && numeroSatbase(n) == 1
        k=0;
        while DonneesPRbaseformat(1,2*k +2) ~= n
            k=k+1;
        end
        DonneesPRbaseformat1 = [DonneesPRbaseformat1, DonneesPRbaseformat(:,2*k +2:2*k +3)];

        k=0;
        while DonneesPRmobileformat(1,2*k +2) ~= n
            k=k+1;
        end
        DonneesPRmobileformat1 = [DonneesPRmobileformat1, DonneesPRmobileformat(:,2*k +2:2*k +3)];
       
        nSat = nSat+1;

        Liste_Sat(nSat) = n; % On dresse la liste des satellites
    end

end


%%%%% Formatage des données ensemble : on prend les éphémérides des
%%%%% satellites effectivement disponibles 

% Comme on peut récupérer plus d'éphémerides qu'il n'y a de satellites (ou inversement) , on
% doit faire coincider le tableau d'éphémérides avec le tableau de données satellites et 
% sélectionner ceux qu'on va utiliser

DonneesPRbaseformat = DonneesPRbaseformat1(:,1);
DonneesPRmobileformat = DonneesPRmobileformat1(:,1);

Ephembis = zeros(32,24);
u=1;
for i = 1:nSat
    k=1;
    while k < 33 && Ephem(k,1) ~= 0
        if Ephem(k,1) == Liste_Sat(i)       % A chaque fois qu'on en rencontre un
            Ephembis(u,:) = Ephem(k,:);     % On remplit le fichier d'éphémérides
            DonneesPRbaseformat = [DonneesPRbaseformat,DonneesPRbaseformat1(:,2*(i-1)+2:2*(i-1)+3)];   % On récupère les données pour la base 
            DonneesPRmobileformat = [DonneesPRmobileformat,DonneesPRmobileformat1(:,2*(i-1)+2:2*(i-1)+3)]; % On récupère les données pour le mobile
            Liste_Satformat(u) = Liste_Sat(i);   % on récupère le numéro du satellite pour la nouvelle liste
            u=u+1;
        end
        k=k+1;
    end
end
nSat = u-1;                                               % le nouveau nombre de satellites
Ephem = Ephembis(1:nSat,:);                               % mise à jour des éphémérides
numeroSat = Liste_Satformat(1:nSat);                      % mise à jour des numéros de satellites

DonneesPRmobile = zeros(nechmax,2*nSat+1);
DonneesPRbase = zeros(nechmax,2*nSat+1);

taille_mob = length(DonneesPRmobileformat(:,1));
taille_base = length(DonneesPRbaseformat(:,1));

DonneesPRmobile(1:taille_mob-1,:) = DonneesPRmobileformat(2:taille_mob,:);    % mise à jour des PR mobile
DonneesPRbase(1:taille_base-1,:) = DonneesPRbaseformat(2:taille_base,:);       % mise à jour des PR base


%%%% On doit maintenant gérer les éventuelles pertes de données lors de la
%%%% récupération.


% On doit vérifier que les données sont bien calées sur le même
% temps, des erreurs pouvant survenir (on rate un échantillon ou on a un doublon)
DonneesPRbaseformat = zeros(nechmax,2*nSat+1);
DonneesPRmobileformat = zeros(nechmax,2*nSat+1);

t=1;
for T=t0_GPS:T_fin_mobile
    DonneesPRmobileformat(t,1)=T;

    for u=1:taille_mob-1
        if DonneesPRmobile(u,1) == T
             DonneesPRmobileformat(t,:)=DonneesPRmobile(u,:);
        end
    end
    t=t+1;   
end
t_total_mob=t-1;

t=1;
for T=t0_GPS:T_fin_base
    DonneesPRbaseformat(t,1)=T;

    for u=1:taille_base-1
        if DonneesPRbase(u,1) == T
             DonneesPRbaseformat(t,:)=DonneesPRbase(u,:);
        end
    end
    t=t+1;   
end
t_total_base=t-1;

t_total = min(t_total_base,t_total_mob);


%%%% On constitue un tableau qui indique lorsque les satellites
%%%% seront disponibles ou pas

SatDispo = ones(t_total,nSat);

for i=1:t_total
    for j=1:nSat
        if DonneesPRbase(i,2*j) == 0 || DonneesPRmobile(i,2*j) == 0   % Si l'une des pseudodistances n'est pas pas disponible, alors on met un 0
            SatDispo(i,j) = 0;
        end
    end
end


%%%% On prépare les mesures de phase de la porteuse qui tient compte de la
%%%% disponiblité des satellites

% On commence par formater les PR phase pour les rendre exploitables (en ne
% considérant que leurs variations)

PR_phaseSB = zeros(nSat,t_total);
PR_phaseMob = zeros(nSat,t_total);

for n = 1:nSat              % pour chaque satellite

    for t=2:t_total        % pour chaque instant, on calcule la différence voulue
        
        if SatDispo(t,n) ~= 0   % si le satellite est disponible

            PR_phaseSB(n,t) = (DonneesPRbase(t,2*n+1) - DonneesPRbase(1,2*n+1))*lambda;     % On calcule les valeurs d'évolution de la phase depuis la première mesure
            PR_phaseMob(n,t) = (DonneesPRmobile(t,2*n+1) - DonneesPRmobile(1,2*n+1))*lambda;

        end
       
    end
end



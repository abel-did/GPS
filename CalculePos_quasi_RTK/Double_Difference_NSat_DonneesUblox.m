% ---------------------------------------------------------------------------
% 
% Programme de calcul d'un point à partir de mesures de double différence
% Pour un nombre d'émetteurs fournissant N équations avec le point de départ 
% connu. 
% ---------------------------------------------------------------------------
clear
format long

load '.\Config\Config.mat'

disp("PROGRAM TO CALCULATE THE POSITION WITH RTK APPROACH.")

fprintf("The coordinates of the Base station is : %d %d %d \n",StationBase(1),StationBase(2),StationBase(3))

Com = input("Do you want to want to change ? (0 if not)");

if Com ~= 0
    Com = input("Do you want to get the position of the base station from the last Rinex file ? (0 if not)");

    if Com ~= 0
        % On récupère la valeur depuis les fichiers Rinex dernièrement
        % récupéré        
        load '..\Recupere Donnees_Rinex\MatfilestoRead\StationB.mat'
        %StationBase = StationB.StationBase;
        disp( "Position of the has been extracted.")

    else
        lat = input("Write the latitude (in deg): ");
        long = input("Write the longitude (in deg): ");
        alt = input("Write the altitude (in m): "); 
        [StationBase(1), StationBase(2), StationBase(3)] = CoordGeograph_Cart(lat,long,alt);;
    end

end

fprintf("The coordinates of the Base station is : %d %d %d \n",StationBase(1),StationBase(2),StationBase(3))

fprintf("The coordinates of the initial point (Cartesian) is : %d , %d , %d \n",VraisPoints(1),VraisPoints(2),VraisPoints(3))

[lat, long, alt] = CoordCart_Geograph(VraisPoints(1),VraisPoints(2),VraisPoints(3));

fprintf("The coordinates of the initial point (WGS84) is : %d °, %d °, %d m \n",lat,long,alt)

Com = input("Do you want to want to change ? (0 if not)");

if Com ~= 0

    lat = input("Write the latitude (in deg): ");
    long = input("Write the longitude (in deg): ");
    alt = input("Write the altitude (in m): ");
end

fprintf("The coordinates of the initial point (WGS84) is now : %d °, %d °, %d m \n",lat,long,alt)

VraisPoints_WGS84 =[lat;long;alt];

disp( "Conversion in cartesian coordinates")

[VraisPoints(1),VraisPoints(2),VraisPoints(3)] = CoordGeograph_Cart(lat,long,alt);

fprintf("The coordinates of the initial point (Cartesian) is now : %d , %d , %d \n",VraisPoints(1),VraisPoints(2),VraisPoints(3))

% On sauve les coordonnées des points dans le répertoire de config

save(".\Config\Config.mat","StationBase","VraisPoints");  %VraisPoints = [4212020.6150  ; 212020.4570 ; 4769002.0090];

% Masque d'élévation (degrés)

Masque = 20;

% Choix des Double différences à retirer manuellement (0 si retiré)

Choix_DD = [1 1 1 1 1 1 1 1 1 1];

% Longueur d'onde

lambda = 299792458/1575420000;

% vitesse de la lumière

c = 299792458;

% Nombre d'émetteurs (déterminé par le programme)

nSat = 0;

% Temps total (déterminé par le programme) :

t_total = 0;

% Instants en temps GPS (en s) pour indiquer le démarrage des mesures

t0_GPS = 1;    % temps GPS initial en secondes (déterminé par le programme)

% On formate les données de pseudodistances pour le mobile et la base,
% ainsi que les éphémérides

disp("Data are extracted from the xlsx files in the repertory ""Fichiers xlsx"" ")

FormaterDonneesM8

%Vectdir = VraisPoints - StationBase;

% Coordonnées des satellites

disp("Calculation of the positions of the satellites.")

CalculerPositionSat

% Initialisation des variables (certaines sont inutiles)

DOP = zeros(5,t_total);

CoordSatNr = zeros(nSat*3,t_total);
Elevation_deg = zeros(nSat,t_total);


Azim = zeros(nSat,1);
Elev = zeros(nSat,1);

Xtrace = zeros(nSat,1);
Ytrace = zeros(nSat,1);

VecteursSBSat = zeros(nSat*3,t_total);
VecteursRecSat = zeros(nSat*3,t_total); 
ProdScalVrecVsb = zeros(nSat,t_total);

% Changement de repère

% On centre le repère sur le vrai point
Xcent = VraisPoints(1);
Ycent = VraisPoints(2);
Zcent = VraisPoints(3);
[lat, long, alt] = CoordCart_Geograph(Xcent,Ycent,Zcent);

% On place les coordonnées satellite dans un repère centré sur le point et tangent à
% la Terre

for t=1:t_total
    for i =1:nSat

        if SatDispo(t,i) == 1          % Condition pour éviter les PR non disponibles
    
            X = CoordSats((i-1)*3+1,t);
            Y = CoordSats((i-1)*3+2,t);
            Z = CoordSats((i-1)*3+3,t);
    
            [X,Y,Z] = ChangeRep(X,Y,Z,Xcent,Ycent,Zcent,long,lat);
            CoordSatNr((i-1)*3+1,t) = X;
            CoordSatNr((i-1)*3+2,t) = Y;
            CoordSatNr((i-1)*3+3,t) = Z;
    
            % projection dans le plan YZ
    
            % Calcul de l'élévation
    
            d = norm([Y,Z]);
            Elevation = atan(X/d);
            Azimut = atan2(Z,Y);
    
            ElAzim((i-1)*2+1,t) = Elevation;
            Elevation_deg(i,t) = Elevation*180/pi;
            ElAzim((i-1)*2+2,t) = Azimut;
        end
    end
end



% tracé du premier instant
for i=1:nSat

    X = CoordSatNr((i-1)*3+1,1);
    Y = CoordSatNr((i-1)*3+2,1);
    Z = CoordSatNr((i-1)*3+3,1);    
    d = norm([Y,Z]);
    Elevation = atan(X/d);
    Azimut = atan2(Z,Y);
    
    % mise en forme pour tracé 
    Azim(i)= Azimut;
    Elev(i)=Elevation*180/pi;
    
    Xtrace(i) = (90-Elev(i))*cos(Azim(i));
    Ytrace(i) = (90-Elev(i))*sin(Azim(i));
    
end

disp("Horizontal projection figure of the satellites.")

% Préparation du tracé

val = (1:101)/(100);
figure ("Name",'Projection horizontale des satellites')
plot(Xtrace,Ytrace,'o')

axis([-90 90 -90 90])
hold on
plot(90*cos(2*pi*val),90*sin(2*pi*val))
plot(45*cos(2*pi*val),45*sin(2*pi*val))
plot(20*cos(2*pi*val),20*sin(2*pi*val))

for i = 1:nSat
    textesat = ['S' num2str(numeroSat(i),'%02d')];
    text(Xtrace(i),Ytrace(i),textesat)
end

hold off

% Caldul de la DOP

for t = 1:t_total
    CoordSatNrutile= zeros(3*nSat,1);  % variable tableau qui va nous servir à stocker ce qu'on va utiliser
    % On doit tenir compte des cas où les satellites ne donnent pas leurs PR

    u=1;      % indice qui suit les satellites disponibles
    for i = 1:nSat
        if SatDispo(t,i) == 1                                           % Si le satellite est disponible
            CoordSatNrutile(3*(u-1)+1:3*(u-1)+3,1) = CoordSatNr(3*(i-1)+1:3*(i-1)+3,t);   % On récupère les coordonnées calculées
            u=u+1;
        end
    end
    nSatutile = u -1;      % On décompte le nombre de satellites finalement utilisables

    if nSatutile > 3       % Si ce nombre est supérieure à 3, le calcul de DOP peut être réalisé

        [GDOP, PDOP, HDOP, VDOP, TDOP] = CalculDOP(CoordSatNrutile(1:3*nSatutile,1),nSatutile);  % On utilise la partie du tableau qui nous intéresse
        DOP(:,t) = [GDOP; PDOP; HDOP; VDOP; TDOP];
    end

end

disp("Calculation of the Dilution Of Precision.")

% On affiche la dilution de précision Horizontale
figure("Name",'Horizontal Dilution of Precision')
plot(temps,DOP(3,:),'-*')
xlabel('Temps (s)')
ylabel('HDOP')
title('Horizontal Dilution Of Precision')
axis([ temps(1) temps(t_total) 0 round(2*mean(DOP(3,:)))])
grid

% Calcul de la position de la base avec les pseudodistances code normales

disp("Calculation of the position of the base station with pseudoranges.")

PositionbasePRCode = zeros(4,t_total);
ErreurbasePRCode = zeros(1,t_total);

Erreur2D = zeros(1,t_total);

Positioncentree = zeros(3,t_total);

% On centre le repère sur la station de base
Xcent = StationBase(1);
Ycent = StationBase(2);
Zcent = StationBase(3);
[lat, long, alt] = CoordCart_Geograph(Xcent,Ycent,Zcent);

for t = 1:t_total
    
    % On doit tenir compte des cas où les satellites ne donnent pas leurs PR
    CoordSatutile= zeros(3*nSat,1);  % variable tableau qui va nous servir à stocker les coordonnées sat utiles
    PRCodebaseutile = zeros(nSat,1); % variable tableau qui va nous servir à stocker les PR utiles pour la base
    PRCodemobutile = zeros(nSat,1); % variable tableau qui va nous servir à stocker les PR utiles pour la double différence code (attention le temps n'est pas corrigé)

    u=1;      % indice qui suit les satellites disponibles
    for i = 1:nSat
        if SatDispo(t,i) == 1                                                          % Si le satellite est disponible
            CoordSatutile(3*(u-1)+1:3*(u-1)+3,1) = CoordSats(3*(i-1)+1:3*(i-1)+3,t);   % On récupère les coordonnées calculées
            PRCodebaseutile(u) = PRCodebase(i,t);                                      % On récupère les pseudodistances code
            u=u+1;
        end
    end
    nSatutile = u -1;      % On décompte le nombre de satellites finalement utilisables

    if nSatutile > 3 
        [X, Y, Z, b] = CalculPositionPR(CoordSatutile(1:3*nSatutile,1),nSatutile,[StationBase;0],PRCodebaseutile(1:nSatutile,1));
        PositionbasePRCode(1,t) = X;
        PositionbasePRCode(2,t) = Y;
        PositionbasePRCode(3,t) = Z;
        PositionbasePRCode(4,t) = b;

        ErreurbasePRCode(t) = ( (X-StationBase(1))^2 + (Y-StationBase(2))^2 + (Z-StationBase(3))^2)^0.5;
     
        % changement de repère :
    
        [X,Y,Z] = ChangeRep(X,Y,Z,Xcent,Ycent,Zcent,long,lat);
     
        Positioncentree(1,t) = X;
        Positioncentree(2,t) = Y;
        Positioncentree(3,t) = Z;
     
        Erreur2D(t) = ( (Y)^2 + (Z)^2)^0.5;
    end
   
     
end

% On affiche l'erreur en 2D, juste pour rigoler
figure("Name",'Erreur 2D Calcul PR Code')
plot(temps,Erreur2D,'-*')
xlabel('Temps (s)')
ylabel('Erreur (m)')
title('Erreur 2D PR Code Station de Base')
axis([ temps(1) temps(t_total) 0 round(2*mean(Erreur2D))])
grid

% Calcul des doubles différences

disp("Calculation of position with RTK approach with Code and Phase measurements.")

% choix du pivot (on prend le satellite qui a l'élévation maximum au début)

[Elpivot, Satpivot]= max(Elevation_deg(:,1));

% En fonction du choix du pivot, on le met en première position dans toutes
% les variables utiles

PR_codeSB = [ PRCodebase(Satpivot,:) ; PRCodebase(1:Satpivot-1,:) ; PRCodebase(Satpivot+1:nSat,:)];
PR_codeMob = [ PRCodemobile(Satpivot,:) ; PRCodemobile(1:Satpivot-1,:) ; PRCodemobile(Satpivot+1:nSat,:)];

PR_phaseSB = [ PR_phaseSB(Satpivot,:) ; PR_phaseSB(1:Satpivot-1,:) ; PR_phaseSB(Satpivot+1:nSat,:)];
PR_phaseMob = [ PR_phaseMob(Satpivot,:) ; PR_phaseMob(1:Satpivot-1,:) ; PR_phaseMob(Satpivot+1:nSat,:)];

CoordSats = [CoordSats(3*(Satpivot-1)+1:3*(Satpivot-1)+3,:) ; CoordSats(1:3*(Satpivot-1),:) ; CoordSats(3*(Satpivot-1)+4:3*nSat,:)];
SatDispo = [ SatDispo(:,Satpivot) SatDispo(:,1:Satpivot-1) SatDispo(:,Satpivot+1:nSat)];
Elevation_deg = [Elevation_deg(Satpivot,:); Elevation_deg(1:Satpivot-1,:) ;Elevation_deg(Satpivot+1:nSat,:)];

% On mène les différences Simples :

DS_phase = zeros(nSat,t_total);
DS_code = zeros(nSat,t_total);

for i= 1:t_total
    for n = 1:nSat
        DS_phase(n,i) = PR_phaseSB(n,i) - PR_phaseMob(n,i);
        DS_code(n,i) = PR_codeSB(n,i) - PR_codeMob(n,i);
    end
end

% On mène les double différences en prenant le premier satellite comme
% pivot

% On applique des mécaniques de correction quand cela a un sens.

DD_phase = zeros(nSat-1,t_total);
DD_code = zeros(nSat-1,t_total);
DDdispo = zeros(t_total,nSat-1);

DDvar = zeros(nSat-1,t_total-1);
TailleTrous = zeros(nSat-1,t_total-1);
OffSet = zeros(nSat-1,t_total-1);
for t= 1:t_total
    for n = 2:nSat
        if SatDispo(t,n) ~= 0

            DD_code(n-1,t) = DS_code(n,t) - DS_code(1,t);
            DDdispo(t,n-1) = 1;

            if t>1 
                
                if TailleTrous(n-1,t-1) > 0     % on vient de récupérer les données
                    if n == 6
                        buc =1;
                    end 
                    OffSet(n-1,t) = OffSet(n-1,t-1)+DDvar(n-1,t-1);

                    DD_phase(n-1,t) = OffSet(n-1,t);   % L'offset qu'on appliquera est donné en DD, un peu comme un nous DDinit
                    
                    OffSet(n-1,t) = OffSet(n-1,t)-(DS_phase(n,t) - DS_phase(1,t));
                    DDvar(n-1,t) = DDvar(n-1,t-1);      % On n'a pas de nouvelle valeur, on est obligé de prendre celle d'avant 

                else
                    OffSet(n-1,t) = OffSet(n-1,t-1);    % le même offset sera appliqué à la donnée qui vient
                    DD_phase(n-1,t) = DS_phase(n,t) - DS_phase(1,t) + OffSet(n-1,t);
                    DDvar(n-1,t)= DD_phase(n-1,t)-DD_phase(n-1,t-1);
                end                                            
                              
            end

        elseif t>1        % On met le dernier DDvar correct

            if SatDispo(t-1,n) == 1     % les données viennent de se perdre

                OffSet(n-1,t) = DD_phase(n-1,t-1)+DDvar(n-1,t-1);  % on récupère celle d'avant
            else

                OffSet(n-1,t) = OffSet(n-1,t-1)+DDvar(n-1,t-1);
            end

            DDvar(n-1,t) = DDvar(n-1,t-1);
            TailleTrous(n-1,t) = TailleTrous(n-1,t-1)+1;
            

        end
    end
end



% On calcule les distances Satellite/Station de base (pour initialiser la
% mesure de phase, la première fois qu'elle arrive)

DistSB_Sat = zeros(nSat,t_total);

for t = 1:t_total

    for n=1:nSat
        if SatDispo(t,n) == 1

            Xs = CoordSats(3*(n-1)+1,t);
            Ys = CoordSats(3*(n-1)+2,t);
            Zs = CoordSats(3*(n-1)+3,t);
            
            X = StationBase(1);
            Y = StationBase(2);
            Z = StationBase(3);
            
            DistSB_Sat(n,t)= ( (Xs-X)^2+(Ys-Y)^2+(Zs-Z)^2 ) ^0.5;
        end
    end    
end

% Avant de calculer les premières distances Sat/Mobile, on a à déterminer si
% des satellites apparaissent pendant l'enregistrement

for n=1:nSat
    t=1;
    while t < t_total+1 && SatDispo(n,t) == 0

        t=t+1;
    end
    SatDispo(t,n) = 2; % On signale la première apparition par la valeur 2

end

% On calcule les premières distances Satellite/Point init

DistPtMob_Sat = zeros(nSat,t_total);

for n=1:nSat

    if SatDispo(1,n) == 2

        Xs = CoordSats(3*(n-1)+1,1);
        Ys = CoordSats(3*(n-1)+2,1);
        Zs = CoordSats(3*(n-1)+3,1);
            
        X = VraisPoints(1);
        Y = VraisPoints(2);
        Z = VraisPoints(3);
            
        DistPtMob_Sat(n,1)= ( (Xs-X)^2+(Ys-Y)^2+(Zs-Z)^2 ) ^0.5;    
    end
end

% On commence le calcul du point (vecteur baseline), et on va calculer les
% Différences simple et les doubles différences au fur et à mesure

% Initialisation du calcul du vecteur de base

VecteurBaseline_Phase = zeros(3,t_total);     % Pour stocker les différents vecteurs du vecteur Baseline Phase
VecteurBaseline_Code  = zeros(3,t_total);     % Pour faire de même pour le code

Residus_Phase = zeros(nSat-1,t_total);        % Pour stocker les résidus calculés
Residus_Code = zeros(nSat-1,t_total);         % Pour stocker les résidus calculés

DDutile_Phase = zeros(nSat-1,t_total);        % Pour stocker les doubles différences utilisées au fur et à mesure
DDutile_Code = zeros(nSat-1,t_total);         % Pour stocker les doubles différences utilisées au fur et à mesure

PointCalcule_Phase = zeros(3,t_total);        % Pour stocker les points calculés
PointCalcule_Code = zeros(3,t_total);         % Pour stocker les points calculés

PointCalcule_Phase(:,1) = VraisPoints;        % le premier point phase est connu

% Calcul des simples différences initiales (si disponible)

DSinit = zeros(nSat,1);

for n=1:nSat

    if SatDispo(1,n) == 2
    
        DSinit(n) = DistSB_Sat(n,1)-DistPtMob_Sat(n,1);    % On connait les distances initiales, on calcule donc les différences simples correspondantes
    
    end
end

% Calcul des doubles différences initiales
DDinit = zeros(nSat-1,1);
for n=2:nSat
    if SatDispo(1,n) == 2
        DDinit(n-1,1) = DSinit(n,1)-DSinit(1,1);   % La première double différence est connue, elle changera si on perd une données
    end
end


for t= 1:t_total

    nbDDcalcl = 0;

    % Avant de construire la matrice H, on prépare les double
    % différences

    for n = 1:nSat-1
            flag_NouvSat = 0;
            if DDdispo(t,n) == 1 && Elevation_deg(n+1,t) > Masque && Choix_DD(n) == 1       % si la DD est disponible Et que l'élévation est supérieure au masque Et qu'on l'autoriste à être là
                
                if SatDispo(t,n+1) == 2 && t > 1                        % C'est la première fois que ce satellite apparaît
                    DDdispo(t,n) = 2;                                   % On le signale en mettant DDdispo à 2 car il va falloir caluler la distance après avoir calculé le point une première fois
                    flag_NouvSat = 1;
                else
                    nbDDcalcl = nbDDcalcl+1;                             % On incrémente le nombre de DD disponibles
                    DDutile_Phase(n,t) = DDinit(n,1)  + DD_phase(n,t);   % la DD utile pour le calcul correspond à la somme de DD phase et DDinit                    
                    DDutile_Code(n,t) = DD_code(n,t);
                end
            else 
                DDdispo(t,n) = 0;
                
            end

    end
    
    % Construction de la matrice H avec les vecteurs de directions des
    % satellites pivot et autres

    H = zeros(nbDDcalcl,3);
    DDutileCalc_phase = zeros(nbDDcalcl,1);
    DDutileCalc_code = zeros(nbDDcalcl,1); 
    u = 1;
    for i = 1:nSat-1

        if DDdispo(t,i) == 1      % si la double différence est disponible

            % On calcule la matrice H
            H(u,1) = (CoordSats(1+i*3,t)- StationBase(1,1))/DistSB_Sat(i+1,t) - (CoordSats(1,t) - StationBase(1,1))/DistSB_Sat(1,t);
            H(u,2) = (CoordSats(2+i*3,t)- StationBase(2,1))/DistSB_Sat(i+1,t) - (CoordSats(2,t) - StationBase(2,1))/DistSB_Sat(1,t);
            H(u,3) = (CoordSats(3+i*3,t)- StationBase(3,1))/DistSB_Sat(i+1,t) - (CoordSats(3,t) - StationBase(3,1))/DistSB_Sat(1,t);
            
            % On récupère la DD correspondant

            DDutileCalc_phase(u,1) = DDutile_Phase(i,t);
            DDutileCalc_code(u,1) = DDutile_Code(i,t);
            u=u+1;

        end
  
    end

    if nbDDcalcl > 2    % si on a plus de 3 mesures valables, on peut lancer le calcul
    
        % Détermination du vecteur baseline (moindres carrés):
        
        VecteurBaseline_Phase(:,t) =((inv(H'*H))*H')*DDutileCalc_phase;
        VecteurBaseline_Code(:,t) =((inv(H'*H))*H')*DDutileCalc_code;

        % On calcule le point
        
        PointCalcule_Phase(:,t) =  StationBase + VecteurBaseline_Phase(:,t);   % On ajoute le vecteur de base aux coordonnées de la station de base pour obtenir le point                
        PointCalcule_Code(:,t) = StationBase + VecteurBaseline_Code(:,t);   % On ajoute le vecteur de base aux coordonnées de la station de base pour obtenir le point                
        

        % On gère les éventuelles apparitions de satellites

        if flag_NouvSat == 1

            for n=1:nSat-1

                if DDdispo(t,n) == 2      % Si c'est la première fois que ce satellite apparaît
                                          % On calcule sa double différence initiale
                    Xs = CoordSats(3*(n-1)+1,t);
                    Ys = CoordSats(3*(n-1)+2,t);
                    Zs = CoordSats(3*(n-1)+3,t);
                        
                    X = PointCalcule_Phase(1,t);
                    Y = PointCalcule_Phase(2,t);
                    Z = PointCalcule_Phase(3,t);
            
                    DistPtMob_Sat(n,t)= ( (Xs-X)^2+(Ys-Y)^2+(Zs-Z)^2 ) ^0.5; 

                    DDinit(n,1) = (DistSB_Sat(n,t)-DistPtMob_Sat(n,t)) - (DistSB_Sat(1,t)-DistPtMob_Sat(1,t));
                    
                end
            end

        end

    else    % Si on n'a pas assez de DD pour calculer la position
        if t > 1
            PointCalcule_Phase(:,t) = PointCalcule_Phase(:,t-1);               % On remet le point précédent
            PointCalcule_Code(:,t) = PointCalcule_Code(:,t-1);
            if flag_NouvSat == 1  && t < t_total                              % Si manque de pot un nouveau satellite arrive

                DDdispo(t,n) = 2; % On remet le calcul de DDinit pour ce satellite au coup d'après

            end
        end
    end 
   
end

% On formate pour le tracé
VBL_phase = zeros(3,t_total);
VBL_code = zeros(3,t_total);

lat_point = VraisPoints_WGS84(1);
lon_point = VraisPoints_WGS84(2);

% La position initiale est au centre du repère
Xcent = VraisPoints(1);
Ycent = VraisPoints(2);
Zcent = VraisPoints(3);

for t=1:t_total


    [X,Y,Z] = ChangeRep(PointCalcule_Phase(1,t),PointCalcule_Phase(2,t),PointCalcule_Phase(3,t),Xcent,Ycent,Zcent,lon_point,lat_point);
    VBL_phase(:,t)=[X;Y;Z];

    [X,Y,Z] = ChangeRep(PointCalcule_Code(1,t),PointCalcule_Code(2,t),PointCalcule_Code(3,t),Xcent,Ycent,Zcent,lon_point,lat_point);
    VBL_code(:,t)=[X;Y;Z];


end
        
figure('Name','Position DD phase')
plot3(VBL_phase(1,:),VBL_phase(2,:),VBL_phase(3,:))
grid
title('Position 3D RTK phase')

figure('Name','Position DD phase Horizontale')
plot(VBL_phase(2,:),VBL_phase(3,:),'-*','MarkerSize',1)
grid
xlabel('Longitude (m)')
ylabel('Latitude (m)')
title('Position 2D RTK phase')

figure('Name','Position DD Code')
plot3(VBL_code(1,:),VBL_code(2,:),VBL_code(3,:))
grid
title('Position 3D RTK code')

figure('Name','Position DD Code Horizontale')
plot(VBL_code(2,:),VBL_code(3,:),'-*','MarkerSize',1)
grid
xlabel('Longitude (m)')
ylabel('Latitude (m)')
title('Position 2D RTK code')

% Calcul des positions en WGS84 (pour affichage dans Google Earth)

disp("Creation of xlsx files for Google earth format")

Lat_Lon_Phase = zeros(t_total,2);
Lat_Lon_Code = zeros(t_total,2);

for t=1:t_total

    if PointCalcule_Phase(1,t) ~= 0 && PointCalcule_Phase(2,t) ~= 0 && PointCalcule_Phase(3,t) ~= 0
        [Lat_Lon_Phase(t,1),Lat_Lon_Phase(t,2)] = CoordCart_Geograph(PointCalcule_Phase(1,t),PointCalcule_Phase(2,t),PointCalcule_Phase(3,t));
    end

    if PointCalcule_Code(1,t) ~= 0 && PointCalcule_Code(2,t) ~= 0 && PointCalcule_Code(3,t) ~= 0
        [Lat_Lon_Code(t,1),Lat_Lon_Code(t,2)] = CoordCart_Geograph(PointCalcule_Code(1,t),PointCalcule_Code(2,t),PointCalcule_Code(3,t));
    end
end

delete 'PosWGS84_phase.xlsx' 'PosWGS84_code.xlsx'

writematrix(Lat_Lon_Phase,'PosWGS84_phase.xlsx');
writematrix(Lat_Lon_Code,'PosWGS84_code.xlsx');



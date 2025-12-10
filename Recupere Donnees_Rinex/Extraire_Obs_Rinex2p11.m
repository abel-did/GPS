%--------------------------------------------------------------------------
%         
%  Extraction des données d'observation sous format Matlab depuis un fichier 
%                    RINEX v2.11.
%
%--------------------------------------------------------------------------
%	 
%        We read the corresponding RINEX observation file (fichier RINEX d'observation, suffixe O) 
%        and reformat the data into the Matlab matrix Tabdonnees.

%Depuis Kai Borre 27-07-2002
%Copyright (c) by Kai Borre
%$Revision: 1.0 $  $Date: 2002/07/27  $
% Nécessite les programmes : julday.m, gps_time.m, get_obs.m

% Read RINEX observation file and convert to
% internal Matlab format

nsat = rinexeobs2p11(nomRinexObservation,'obs.dat',1,1,0,1,0,1,0);   % On indique les observables qu'on veut voir (C1, L1, L2, D1, D2, S1 et S2)

TabdonneesGPS = get_obs('obs.dat', nsat);

if round(T_GPS) < TabdonneesGPS(1,1) || round(T_GPS) > TabdonneesGPS(length(TabdonneesGPS(:,1))-1,1)  % le T_GPS n'est pas dans l'enregistrement

    T_GPS = TabdonneesGPS(1,1);

end

t_total = 1200;   % Nombre d'échantillons qu'on récupère

TabGPS = zeros(t_total,1+32*4);   % Tableau de données GPS

ind=1;

while TabdonneesGPS(ind,1) < T_GPS   % Boucle pour trouver l'indice du premier échantillon à récupérer

    ind=ind+1;

end
indmin = ind;
indmax = length(TabdonneesGPS(:,1))-1;

% On sécurise l'enregistrement (si le restant du fichier Rinex contient moins de t_total échantillons)

if indmax - indmin < 1200

    t_total = indmax- indmin + 1;

end

for t=1:t_total

    TabGPS(t,1) = TabdonneesGPS(indmin+t-1,1);
    
    for nSat =1:32
        TabGPS(t,(nSat-1)*4+2) = TabdonneesGPS(indmin+t-1,(nSat-1)*7+2); % PR
        TabGPS(t,(nSat-1)*4+3) = TabdonneesGPS(indmin+t-1,(nSat-1)*7+3); % PR phase
        TabGPS(t,(nSat-1)*4+4) = TabdonneesGPS(indmin+t-1,(nSat-1)*7+5); % Doppler
        TabGPS(t,(nSat-1)*4+5) = TabdonneesGPS(indmin+t-1,(nSat-1)*7+7); % CN0
    end
end

DonneesPR = struct("TabGPS",TabGPS,"t_total",length(TabGPS(:,1)));


%%%%%%%%%%%%%%%%%%%%% end ExtraireObs_Rinex2p11.m %%%%%%%%%%%%%%%

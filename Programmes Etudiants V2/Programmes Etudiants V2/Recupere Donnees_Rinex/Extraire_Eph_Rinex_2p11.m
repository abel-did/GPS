%--------------------------------------------------------------------------
%         
%       Extraction des Données d'éphémérides depuis un fichier Rinex v2.11
%
%--------------------------------------------------------------------------
% Extraction des Ephémérides sous format Matlab depuis un fichier RINEX v2.02.
%        We read the corresponding RINEX navigation file (fichier RINEX de Navigation, suffixe N) 
%        and reformat the data into the Matlab matrix Eph.
%Depuis Kai Borre 27-07-2002
%Copyright (c) by Kai Borre
%$Revision: 1.0 $  $Date: 2002/07/27  $

% Read RINEX ephemerides file and convert to
% internal Matlab format

%T_GPS = 306785;  % Temps GPS (pour récupérer la bonne éphémérides)

   
rinexe_eph_2p11(Nom_Rinex_Nav,'eph.dat'); 

Eph = get_eph_2p11('eph.dat');

% On le formate pour qu'il soit exploitable

Ephformat = zeros(length(Eph(1,:)),24); % on le formate à 24 pour ajouter iodc et iode

% On ne peut pas automatiser grand chose

Ephformat(:,1) = Eph(1,:)';    % On,met d'abord les numéros dePRN
Ephformat(:,2) = Eph(18,:)';   % TOE
Ephformat(:,3) = Eph(6,:)';    % eccentricité
Ephformat(:,4) = Eph(12,:)';   % i0
Ephformat(:,5) = Eph(16,:)';   % omega0
Ephformat(:,6) = Eph(7,:)';    % omega
Ephformat(:,7) = Eph(3,:)';    % M0
Ephformat(:,8) = Eph(13,:)';   % idot
Ephformat(:,9) = Eph(17,:)';   % omegadot
Ephformat(:,10) = Eph(5,:)';   % deltan
Ephformat(:,11) = Eph(8,:)';   % cuc
Ephformat(:,12) = Eph(9,:)';   % cus
Ephformat(:,13) = Eph(10,:)';  % crc
Ephformat(:,14) = Eph(11,:)';  % crs
Ephformat(:,15) = Eph(14,:)';  % cic
Ephformat(:,16) = Eph(15,:)';  % cis
Ephformat(:,17) = Eph(4,:)';   % racine(a)
Ephformat(:,18) = Eph(19,:)';  % af0
Ephformat(:,19) = Eph(20,:)';  % af1
Ephformat(:,20) = Eph(2,:)';   % af2
Ephformat(:,21) = Eph(21,:)';  % toc
Ephformat(:,22) = Eph(22,:)';  % tgd


% Une fois les éphémérides récupérées, elles sont déjà rassemblées par TOE,
% on les trie par ordre de PRN croissant

for pluspetit= 1:length(Ephformat(:,1))
    for j = pluspetit+1:length(Ephformat(:,1))
        if Ephformat(j,1) <= Ephformat(pluspetit,1)
            a = Ephformat(pluspetit,:);
            Ephformat(pluspetit,:) = Ephformat(j,:);
            Ephformat(j,:) = a;
        end
    end 
end

% On peut donc créer la structure correspondante

DonneesEphemerides = struct("TrameGPS",zeros(32,4),"TabEph_GPS",[ (1:32)',zeros(32,21)],"EphemDispo",zeros(32,1),"Iono",zeros(1,16));

% On remplit satellite par satellite
i=1;
for nSat=1:32
    trouve = 0;
    while i <= length(Ephformat(:,1)) && Ephformat(i,1) == nSat

        if Ephformat(i,2) > T_GPS
            i=i+1;
        elseif trouve == 0

            DonneesEphemerides.TabEph_GPS(nSat,:) = Ephformat(i-1,1:22);
            DonneesEphemerides.EphemDispo(nSat) = 1;
            trouve = 1;
        end
        if trouve == 1 
            i=i+1;
        end
    end
end

Iono = rinexe_iono_2p11(Nom_Rinex_Nav);   % On récupère les données iono

DonneesEphemerides.Iono(1:8) = Iono;    % On les place dans les données d'éphémérides





%%%%%%%%%%%%%%%%%%%%% end ExtraireEph_Rinex2.11%%%%%%%%%%%%%%%




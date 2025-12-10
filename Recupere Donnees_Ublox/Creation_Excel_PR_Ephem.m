% -------------------------------------------------------------------------
%
%              Création des fichiers Excel contenant les éphémérides
%              et les pseudodistances code et phase 
% 
% -------------------------------------------------------------------------

% Il faut en entrée la structure DonneesEphem et le tableau TabGPS

% Données d'entrée : 
%                   - TabGPS : tableau contenant le temps GPS sur la première colonne et pour chaque satellite : PR (m), PRphase(cycle), Doppler (Hz), C/N0 (dB) 
%                   - DonneesEphemerides est une structure qui contient :
%                           - "TrameGPS" : Un Tableau qui recense les 3 premières trames du GPS, sa quatrième valeur est un compteur indiquant 3 lorsque les éphémérides sont disponibles pour le satellite 
%                           - "TabEph_GPS" : tableau contenant les 21 paramètres d'éphémérides pour les 32 satellites
%                           - "EphemDispo" : tableau indiquant si les éphémérides sont utilisables ou en cours de récupération
%                           - "Iono" : paramètres de correction iono fournis par le récepteur

% On commence par s'assurer que les fichiers xlsx ont été retirés

delete './Filesxlsx/Donnees_Ephem.xlsx' './Filesxlsx/Donnees_PR_Mob.xlsx'

% Nombre d'échantillons maximum

Nechmax = 1200;

% Nombre de satellites maximum

NSatmax =12;

% On commence par les pseudodistances

diff = TabGPS(length(TabGPS(:,1)),1)-TabGPS(1,1);  % on récupère la différence entre le premier et le dernier instant GPS


if diff > 0     % on n'est pas à cheval d'une semaine sur l'autre
    t_total = diff+1;
else
    t_total = 604800-TabGPS(1,1)+TabGPS(length(TabGPS(:,1)),1)+1;   % on est à cheval, donc on adapte
end

% On balaye le tableau pour savoir quels satellites sont là

SatDispos = zeros(1,32);
for t=1:t_total
    for n=1:32    
        if TabGPS(t,1+4*(n-1)+1) ~= 0 && DonneesEphemerides.EphemDispo(n) == 1
            SatDispos(n) = 1;     
        end
    end 
end
nSatDispos = sum(SatDispos);
PR_Code_Phase = zeros(Nechmax+1,1+NSatmax*2);  % cette variable va contenir les PR code et Phase

for t=1:t_total
    PR_Code_Phase(t+1,1) = round(TabGPS(t,1));
    u=1;
    for n=1:32    
        if SatDispos(n) == 1
            PR_Code_Phase(t+1,1+2*(u-1)+1) = TabGPS(t,1+4*(n-1)+1);  % Pr code
            PR_Code_Phase(t+1,1+2*(u-1)+2) = TabGPS(t,1+4*(n-1)+2);  % Pr phase
            u=u+1;
        end
    end 
end

% En haut du tableau on met une ligne qui contient le nombre de satellites
% disponibles et le numéro de chacun
PR_Code_Phase(1,1) = nSatDispos;
u=1;
for n=1:32    
    if SatDispos(n) == 1
        PR_Code_Phase(1,1+2*(u-1)+1) = n;  % numSat
        u=u+1;
    end
end


% On récupère les éphémérides pour le fichier

Ephem = zeros(nSatDispos,24);
u=1;
for n =1:32
    if SatDispos(n)==1
        Ephem(u,1:22) = DonneesEphemerides.TabEph_GPS(n,1:22); % numero de PRN        
        u=u+1;
    end
end

% On crée le fichier d'éphémérides à récupérer
nomfichier = './Filesxlsx/Donnees_Ephem.xlsx';
writematrix(Ephem,nomfichier);

nomfichier = './Filesxlsx/Donnees_PR_Mob.xlsx';
writematrix(PR_Code_Phase,nomfichier);


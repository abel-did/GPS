%% 
%% 
%--------------------------------------------------------------------------
%         
%       Reading Data from Rinex files v2.10
%
%--------------------------------------------------------------------------
clear

disp("PROGRAM TO EXTRACT DATA FROM Rinex FILES")

disp("If there is more than one file of each, only the most recent will be considered.")

Test = input("Do you want to extract the GPS Time of the first sample from the last Ublox measurements (0 if not)?");
if Test ~= 0
    load('..\Recupere Donnees_Ublox\MatfilestoRead\GPS_Time.mat');
    T_GPS = round(T_GPS);
else
    disp("Indicate manualy the GPS time (Time Of Week) you want to take")
    T_GPS = input("(if the entered time is not valid, the first sample of the observation file will be considered) : ");
end 

% On commence par récupérer les noms des fichiers à extension *n et *o dans
% le répertoire dédié (Attention il faut qu'il n'y en ait qu'un de chaque, sinon on prendra les plus récents)

cd RinexfilestoRead
Repertoire = dir;

nomRinexEphem = '0';
nomRinexObservation = '0';

i=1;
date_eph = 0;
date_obs = 0;
while i <length(Repertoire)+1
    l = length(Repertoire(i).name);
    if (Repertoire(i).name(l) == 'n' )  % on récupère un fichier d'éphémérides
        if date_eph == 0
            nomRinexEphem = Repertoire(i).name;
            date_eph = datenum(Repertoire(i).date,'dd-mmm-yyyy HH:MM:SS');
        elseif date_eph < datenum(Repertoire(i).date,'dd-mmm-yyyy HH:MM:SS')   % si on en a un plus récent, on le prend
            nomRinexEphem = Repertoire(i).name;         
            date_eph = datenum(Repertoire(i).date,'dd-mmm-yyyy HH:MM:SS');
        end
    end
    if (Repertoire(i).name(l) == 'o' )   % on récupère un fichier d'observation
        if date_obs == 0
            nomRinexObservation = Repertoire(i).name;
            date_obs = datenum(Repertoire(i).date,'dd-mmm-yyyy HH:MM:SS');
        elseif date_obs < datenum(Repertoire(i).date,'dd-mmm-yyyy HH:MM:SS')  % si on en a un plus récent, on le prend
            nomRinexObservation = Repertoire(i).name;
            date_obs = datenum(Repertoire(i).date,'dd-mmm-yyyy HH:MM:SS');
        end       
    end    
    i=i+1;
end

cd ..

disp("Extraction of the observation data.")

fprintf("The file we read is : %s\n",nomRinexObservation);

nomRinexObservation = ['.\RinexfilestoRead\' nomRinexObservation];

Extraire_Obs_Rinex2p11

% Extract the position of the base from the file

disp("Extraction of the exact position in the observation file.")

StationBase = rinexeobs2p11_pos(nomRinexObservation);

save(".\MatfilestoRead\StationB.mat","StationBase");

disp("End of the extraction of the observation data.")

fprintf("T_GPS = %d \n",T_GPS)

disp("Extraction of the navigation data.")

fprintf("The file we read is : %s\n",nomRinexEphem);

Nom_Rinex_Nav = ['.\RinexfilestoRead\' nomRinexEphem];  % Nom du fichier Rinexe d'éphémérides (navigation)

Extraire_Eph_Rinex_2p11

disp("End of the extraction of the navigation data.")

% Creation of the Data files for the Mobile

disp("Creation of xlsx files")

Creation_Excel_PR_Ephem

disp("Donnees_Ephem.xlsx and Donnees_PR_Base.xlsx created.")

disp(" End of the extraction of data from Rinex file.")

%--------------------------------------------------------------------------
%         
%           Program to get Data from Ublox M8T
%
%--------------------------------------------------------------------------
clear

Config =open(".\Config\Config.mat");


disp(" PROGRAM TO RECORD DATA FROM UBLOX M8T RECEIVER")

% Input Data :

% Total time for recording data (in seconds):

t_total = input("Time for recording in seconds (will be round to the nearest minute, if 0 or negative, time = 300s): ");

t_total = round(t_total/60);

% Number of COM port :

NumPortCom = Config.NumPortCom;

fprintf("The Port Com number is now %i\n",NumPortCom);

Change = input(" Do you want to change it ? (0 if no, other if yes)");

if Change ~= 0
    NumPortCom_new= input("Number ot the port com (if 0 or negative, it will remain the same) :");
    NumPortCom_new = round(NumPortCom_new);
    if NumPortCom_new > 0
        NumPortCom = NumPortCom_new;
        save(".\Config\Config.mat","NumPortCom");
    end
end

% Reading of the data on ublox

Lire_ublox

% Save the files in a specific folder

date = char(datetime,"uuuu-MM-dd-hh-mm-ss");
nomdossier = ['.\SavedRecords\' date ];

mkdir(nomdossier)

copyfile('*.mat',nomdossier)
nomfichier = [nomdossier '\nombfichier.mat'];
save(nomfichier,"cpt_fichier")

% Put the data to the appropriate format

Formater_ublox

% Processing of the Data to extract Ephemerids 

disp("Extraction of the ephemerids.")

Extraire_Eph_ublox

disp("Ephemerids extracted.")

% Processing of the Data to extract the pseudoranges

disp("Extraction of the Pseudoranges.")

Extraire_PR_ublox

disp("Pseudoranges extracted.")

% Creation of the Data files for the Mobile

disp("Creation of xlsx files")

Creation_Excel_PR_Ephem

disp("Donnees_Ephem.xlsx and Donnees_PR_Mob.xlsx created.")
T_GPS = TabGPS(2,1);
save('.\MatfilestoRead\GPS_Time.mat',"T_GPS")

% Archive the xls file in a folder

% Save the files in a specific folder

date = char(datetime,"uuuu-MM-dd-hh-mm-ss");
nomdossier = ['.\Filesxlsx\Archives\' date ];

mkdir(nomdossier)

copyfile('.\Filesxlsx\*.xlsx',nomdossier)


disp(" End of the extraction of data from UBX receiver.")






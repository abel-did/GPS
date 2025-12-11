%--------------------------------------------------------------------------
%         
%           Programme de récupération des données Ublox
%
%--------------------------------------------------------------------------

% Données d'entrée : 

%        - t_total : temps total de simulation en secondes (écrêté à 20 minutes)
%        - NumportCom : numéro de port Com

% On fait le ménage des fichiers .mat avant de lancer le programme

delete *.mat       

% On arrondit t_total pour les petits malins qui auraient mis une décimale 

t_total = round(t_total);

% Écrêtage à 20 minutes (1200 secondes)


if t_total > 1200

    t_total = 1200;

elseif t_total <= 0

    t_total = 300;

end

% Port Com

Port_Com = convertStringsToChars(sprintf("COM%i", NumPortCom));

% Variables utiles

% Variable qui récupère les trames issues du ublox sous forme d'octets par
% paquet de 60 secondes

str = zeros(1,60*1200); % en octets, donc avec un débit de 9600 bauds ça fait 1200 par seconde


disp(" Start of the recording of the Data.")

% Appel de la fonction pour ouvrir le port série

device=serialport(Port_Com,9600); % bien vérifier qu'on est sur le bon COMx


flush(device);               % pour s'assurer que tous les buffers d'entrée et de sortie sont bien vides
device.UserData = struct("Data",zeros(5,1200),"Count",0,"BigCount",0,"T_total",t_total);  % une structure pour contenir les éléments utiles
configureCallback(device,"byte",1200,@readSerialData);   % Définition du script qui va gérer la récupération des données en tâche de fond

% messageUBX = Creation_UBX_POLL_MSG(11,49);     % Appel d'un message de classe 11, numéro 49 UBX-AID-EPH, permet de récupérer les sous trames des messages de navigation GPS pour avoir les éphémérides 
% write(device,messageUBX,"uint8");

% On récupère les éphémérides et les pseudodistances

messageUBX = Creation_UBX_CFG_MSG(2,19,2);    % Appel d'un message de classe 2, numéro 19 UBX-RXM-SFRBX, permet de récupérer les trames du messages de navigation
write(device,messageUBX,"uint8");

messageUBX = Creation_UBX_CFG_MSG(2,21,1);     % Appel d'un message de classe 2, numéro 21 (rawxdata multiconstellation), un taux de 1 (qui correspond à 1 par seconde) permettant de récupérer les données de pseudodistances
write(device,messageUBX,"uint8");


% Lancement de la récupération des données
% On remplit str toutes les 5 secondes
% Les pauses de 200 ms servent à éviter de faire tourner le programme pour rien

n = 1;              % juste un compteur de secondes pour la variable str
flag = 0;           % flag pour signaler qu'on n'a pas encore 
cpt_fichier = 1;    % un compteur pour le nom des fichiers à sauvegarder

while device.UserData.BigCount < t_total+1   % Tant qu'on n'est pas au bout du temps, on continue
    while device.UserData.Count < 5 && device.UserData.BigCount < t_total+1   % Tant qu'
        pause(0.2);                                     

    end
    if device.UserData.Count == 5

        % On remplit str
        for u=1:5
            str(1+(n-1)*1200:1200*n) = device.UserData.Data(u,:);
            n=n+1;
        end 

        % Une fois qu'on a atteint 61, on peut sauvegarder sous forme de
        % fichier.dat

        if n == 61
            nomfichier = sprintf("str%.2d.mat", cpt_fichier);
            save(nomfichier,"str");
            str = zeros(1,60*1200);    % On remet str à 0
            cpt_fichier=cpt_fichier+1;
            n=1;
        end
        
    end
    while device.UserData.Count == 5 && device.UserData.BigCount < t_total+1
        pause(0.2);
    end
end

% Une fois qu'on a fini,on sauve ce qui reste de str

nomfichier = sprintf("str%.2d.mat", cpt_fichier);
save(nomfichier,"str");


delete(device)

disp("End of Data recording.")

% Script qui tourne en parallèle du programme principal de matlab et qui
% lit les données toutes les secondes en les mettant dans "data"

function readSerialData(src,~)
    data = read(src,1200,"uint8");     % 1200 correspond à 1 seconde pour le débit de 9600 bauds (1 octet = 8 bits)
    
    if src.UserData.Count == 5
        src.UserData.Count = 0;   % si le compteur est à 5 on le remet à 0
    end


    src.UserData.Data(src.UserData.Count+1,:) = data; % On copie les données dans le tableau par paquet de 5 secondes
    src.UserData.Count = src.UserData.Count + 1;   % On avance le compteur
    src.UserData.BigCount = src.UserData.BigCount +1;    % On avance le gros compteur  

    fprintf("BC = %f \n",src.UserData.BigCount);
    fprintf("C = %f \n",src.UserData.Count);

    if src.UserData.BigCount == src.UserData.T_total+1
        configureCallback(src, "off");   % on coupe le callback au bout de T_total secondes
    end
    
       
end
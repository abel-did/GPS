%------------------------------------------------------
%         
%       Extraction des Données d'éphémérides du ublox
%
%------------------------------------------------------
% Avec ce programme on extrait les éphémérides du récepteur
%
% DonneesEphemerides est une structure qui contient :
%       - "TrameGPS" : Un Tableau qui recense les 3 premières trames du GPS, sa quatrième valeur est un compteur indiquant 3 lorsque les éphémérides sont disponibles pour le satellite 
%       - "TabEph_GPS" : tableau contenant les 21 paramètres d'éphémérides pour les 32 satellites
%       - "EphemDispo" : tableau indiquant si les éphémérides sont utilisables ou en cours de récupération
%       - "Iono" : paramètres de correction iono fournis par le récepteur
%
% On extrait les données à partir du tableau "trames" dont chaque lignes
% correspond à une trame. Le premier élément de chaque ligne donne le
% nombre d'octets de la trame à récupérer.

DonneesEphemerides = struct("TrameGPS",zeros(32,4),"TabEph_GPS",[ (1:32)',zeros(32,21)],"EphemDispo",zeros(32,1),"Iono",zeros(1,16));

for k=1:length(trames(:,1))
    tailletrame = trames(k,1);
    str = trames(k,2:tailletrame+1);
    for t=4:length(str)
    
        if (str(t) == 19 && str(t-1) == 2 && str(t-2) == 98 && str(t-3) == 181) && length(str(1,t:length(str))) >= 56  % 56 octets est la taille d'une sous trame pour le GPS 
            numsat = str(t+4);  % numéro du satellite
            
            if t < length(str)-1   % la dernière trame est coupée après les bytes indiquant la taille du payload
                
                taillepayload = bin2dec([dec2bin(str(t+2),8) dec2bin(str(t+1),8)]);
    
                if t < length(str)-taillepayload-1  % si la trame qui reste est plus grande que la taille du payload + les deux octets indiquant sa taille
    
                    mots = dec2bin(zeros(10,1),30);   % Tableau qui contiendra tous les mots binaires d'une sous trame GPS (10 mots de 30 bit)
                    
                    if str(t+3) == 0     % On a affaire à une trame GPS
                        % On récupère les mots et on les mets en forme            
                        % le premier octet de données est à t+11
            
                        for i=1:10
                            mot = dec2bin([str(t+14+4*(i-1)),str(t+13+4*(i-1)),str(t+12+4*(i-1)),str(t+11+4*(i-1))],8);  % on convertit les octets en binaire
                            mot = [mot(1,3:8) mot(2,:) mot(3,:) mot(4,:)];     % On en fait un seul mot en retirant les deux premiers bit de pading
                            mots(i,:) = mot;
                        end
                                   
                        % L'identifiant de la trame est dans les 3 derniers bits du
                        % 3ième octet du 2ième mot
            
                        idtrame = bin2dec(mots(2,20:22));
            
                        if idtrame == 1 && DonneesEphemerides.TrameGPS(numsat,1) == 0    % Si on a affaire à la trame 1 et qu'elle n'a pas encore été lue, on récupère les données correspondantes
                                                            
                            DonneesEphemerides.TabEph_GPS(numsat,18) = ConvertBintoNumMesNavGPS(mots(10,1:22),-31,1); % af0
                            DonneesEphemerides.TabEph_GPS(numsat,19) = ConvertBintoNumMesNavGPS(mots(9,9:24),-43,1);  % af1
                            DonneesEphemerides.TabEph_GPS(numsat,20) = ConvertBintoNumMesNavGPS(mots(9,1:8),-55,1);   % af2
                            DonneesEphemerides.TabEph_GPS(numsat,21) = ConvertBintoNumMesNavGPS(mots(8,9:24),4,0);    % toc
                            DonneesEphemerides.TabEph_GPS(numsat,22) = ConvertBintoNumMesNavGPS(mots(7,17:24),-31,1); % Tgd
            
                            DonneesEphemerides.TrameGPS(numsat,1) = 1;    % On indique qu'on a lu la trame
                            DonneesEphemerides.TrameGPS(numsat,4) = DonneesEphemerides.TrameGPS(numsat,4)+1; % On incrémente le compteur de trames
            
                        end
            
                        if idtrame == 2 && DonneesEphemerides.TrameGPS(numsat,2) == 0  % Si on a affaire à la trame 2 et qu'elle n'a pas encore été lue, on récupère les données correspondantes
                            
                            DonneesEphemerides.TabEph_GPS(numsat,14) = ConvertBintoNumMesNavGPS(mots(3,9:24),-5,1);    % crs
                            DonneesEphemerides.TabEph_GPS(numsat,10) = ConvertBintoNumMesNavGPS(mots(4,1:16),-43,1)*pi;   % deltan on multiplie par pi car c'est exprimé en demi cercle (donc en nombre de fois pi)
                            DonneesEphemerides.TabEph_GPS(numsat,7) = ConvertBintoNumMesNavGPS([mots(4,17:24) mots(5,1:24)],-31,1)*pi; % M0 on multiplie par pi car c'est exprimé en demi cercle (donc en nombre de fois pi)
                            DonneesEphemerides.TabEph_GPS(numsat,11) = ConvertBintoNumMesNavGPS(mots(6,1:16),-29,1); % cuc
                            DonneesEphemerides.TabEph_GPS(numsat,3) = ConvertBintoNumMesNavGPS([mots(6,17:24) mots(7,1:24)],-33,0); % ecc
                            DonneesEphemerides.TabEph_GPS(numsat,12) = ConvertBintoNumMesNavGPS(mots(8,1:16),-29,1); % cus
                            DonneesEphemerides.TabEph_GPS(numsat,17) = ConvertBintoNumMesNavGPS([mots(8,17:24) mots(9,1:24)],-19,0); % racine(a)
                            DonneesEphemerides.TabEph_GPS(numsat,2) = ConvertBintoNumMesNavGPS(mots(10,1:16),4,0); % toe
            
                            DonneesEphemerides.TrameGPS(numsat,2) = 1;    % On indique qu'on a lu la trame
                            DonneesEphemerides.TrameGPS(numsat,4) = DonneesEphemerides.TrameGPS(numsat,4)+1; % On incrémente le compteur de trames
            
                        end
            
                        if idtrame == 3 && DonneesEphemerides.TrameGPS(numsat,3) == 0   % Si on a affaire à la trame 3 et qu'elle n'a pas encore été lue, on récupère les données correspondantes
                          
                            DonneesEphemerides.TabEph_GPS(numsat,15) = ConvertBintoNumMesNavGPS(mots(3,1:16),-29,1);    % cic
                            DonneesEphemerides.TabEph_GPS(numsat,5) = ConvertBintoNumMesNavGPS([mots(3,17:24) mots(4,1:24)],-31,1)*pi;    % omega0 on multiplie par pi car c'est exprimé en demi cercle (donc en nombre de fois pi)
                            DonneesEphemerides.TabEph_GPS(numsat,16) = ConvertBintoNumMesNavGPS(mots(5,1:16),-29,1);    % cis
                            DonneesEphemerides.TabEph_GPS(numsat,4) = ConvertBintoNumMesNavGPS([mots(5,17:24) mots(6,1:24)],-31,1)*pi;    % i0 on multiplie par pi car c'est exprimé en demi cercle (donc en nombre de fois pi)
                            DonneesEphemerides.TabEph_GPS(numsat,13) = ConvertBintoNumMesNavGPS(mots(7,1:16),-5,1);    % crc
                            DonneesEphemerides.TabEph_GPS(numsat,6) = ConvertBintoNumMesNavGPS([mots(7,17:24) mots(8,1:24)],-31,1)*pi;    % omega on multiplie par pi car c'est exprimé en demi cercle (donc en nombre de fois pi)
                            DonneesEphemerides.TabEph_GPS(numsat,9) = ConvertBintoNumMesNavGPS(mots(9,1:24),-43,1)*pi;    % omegadot on multiplie par pi car c'est exprimé en demi cercle (donc en nombre de fois pi)
                            DonneesEphemerides.TabEph_GPS(numsat,8) = ConvertBintoNumMesNavGPS(mots(10,9:22),-43,1)*pi;    % idot on multiplie par pi car c'est exprimé en demi cercle (donc en nombre de fois pi)
                            
                            DonneesEphemerides.TrameGPS(numsat,3) = 1;    % On indique qu'on a lu la trame
                            DonneesEphemerides.TrameGPS(numsat,4) = DonneesEphemerides.TrameGPS(numsat,4)+1; % On incrémente le compteur de trames
              
                        end
            
                        if DonneesEphemerides.TrameGPS(numsat,4) == 3    % Si le compteur de trames est à 3, les éphémérides sont disponibles pour numsat
                            DonneesEphemerides.EphemDispo(numsat,1) = 1;  % On indique la disponibilité
                        end
            
                        if idtrame == 4 && bin2dec(mots(3,3:8)) == 56    % la seule page intéressante de la sous trame 4 est celle contenant les paramètres ionosphériques (page 18, identifiant 56)
                                            
                            DonneesEphemerides.Iono(1,1) = ConvertBintoNumMesNavGPS(mots(3,9:16),-30,1);  % alpha0
                            DonneesEphemerides.Iono(1,2) = ConvertBintoNumMesNavGPS(mots(3,17:24),-27,1); % alpha1 
                            DonneesEphemerides.Iono(1,3) = ConvertBintoNumMesNavGPS(mots(4,1:8),-24,1); % alpha2
                            DonneesEphemerides.Iono(1,4) = ConvertBintoNumMesNavGPS(mots(4,9:16),-24,1); % alpha3
                            DonneesEphemerides.Iono(1,5) = ConvertBintoNumMesNavGPS(mots(4,17:24),11,1); % beta0
                            DonneesEphemerides.Iono(1,6) = ConvertBintoNumMesNavGPS(mots(5,1:8),14,1); % beta1
                            DonneesEphemerides.Iono(1,7) = ConvertBintoNumMesNavGPS(mots(5,9:16),16,1); % beta2
                            DonneesEphemerides.Iono(1,8) = ConvertBintoNumMesNavGPS(mots(5,17:24),16,1); % beta3
                            DonneesEphemerides.Iono(1,9) = ConvertBintoNumMesNavGPS([mots(7,1:24) mots(8,1:8)],-30,1); %A0
                            DonneesEphemerides.Iono(1,10) = ConvertBintoNumMesNavGPS(mots(6,1:24),-50,1); % A1
                            DonneesEphemerides.Iono(1,11) = ConvertBintoNumMesNavGPS(mots(9,1:8),0,1); % deltatLS
                            DonneesEphemerides.Iono(1,12) = ConvertBintoNumMesNavGPS(mots(8,9:16),12,0); % tot
                            DonneesEphemerides.Iono(1,13) = ConvertBintoNumMesNavGPS(mots(8,17:24),0,0); % WNt
                            DonneesEphemerides.Iono(1,14) = ConvertBintoNumMesNavGPS(mots(9,9:16),0,0);   % WNLSF          
                            DonneesEphemerides.Iono(1,15) = ConvertBintoNumMesNavGPS(mots(9,17:24),0,1); % DN
                            DonneesEphemerides.Iono(1,16) = ConvertBintoNumMesNavGPS(mots(10,1:8),0,1); % deltatLSF
                        end
            
                    end 
    
                else        % la trame est coupée avant d'être finie :         
                    Fin_trame = str(t-3:length(t));   % on la garde pour jointage éventuel avec la mesure suivante
                    flag_coup =1;                     % flag pour signaler qu'on a un bout en plus
                end
    
            else
                Fin_trame = str(t-3:length(t));   % on la garde pour jointage éventuel avec la mesure suivante
                flag_coup =1;                     % flag pour signaler qu'on a un bout en plus
            end
        end
    end
    
    % Ultime cas particulier à traiter : si la trame a commencé sur un des 3
    % derniers octets
    
    if str(length(str)-2) == 181 && str(length(str)-1) == 98 && str(length(str)) == 2 &&flag_coup == 0 % si les trois derniers éléments de la trame sont 181, 98 et 2, cela peut être le début d'une nouvelle trame
    
        Fin_trame = str(t-2:length(t));   % on la garde pour jointage éventuel avec la mesure suivante
        flag_coup =1;  
    
    end
    
    if str(length(str)-1) == 181 && str(length(str)) == 98 && flag_coup == 0 % si les deux derniers éléments de la trame sont 181 et 98, cela peut être le début d'une nouvelle trame
    
        Fin_trame = str(t-1:length(t));   % on la garde pour jointage éventuel avec la mesure suivante
        flag_coup =1;  
    
    end
               
    if str(length(str)) == 181 && flag_coup == 0 % si le dernier élément de la trame est 181, cela peut être le début d'une nouvelle trame
    
        Fin_trame = str(length(t));   % on la garde pour jointage éventuel avec la mesure suivante
        flag_coup =1;  
    
    end
    
end


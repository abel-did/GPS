%------------------------------------------------------
%         
%       Extraction des Données d'observation du ublox
%
%------------------------------------------------------

% Avec ce programme on extrait : 
% 
%           - les PR (m) 
%           - PR_phases (cycles)
%           - Dopplers (Hz) 
%           - C/N0 (dB-Hz)
%
% sous la forme de tableaux, exemple TabGPS, avec la première colonne qui
% donne le TOW, ensuite 4 colonnes par satellite de 1 à 32 pour GPS, les
% colonnes étant égales à 0 si les données satellite ne sont pas présentes
% On extrait les données à partir du tableau "trames" dont chaque lignes
% correspond à une trame. Le premier élément de chaque ligne donne le
% nombre d'octet de la trame à récupérer.

% On commence par compter les occurences des données
cpt =0;
for i=1:length(trames(:,1))
    tailletrame = trames(i,1);
    str = trames(i,2:tailletrame+1);
    for t=4:length(str)
        if (str(t) == 21 && str(t-1) == 2 && str(t-2) == 98 && str(t-3) == 181)
            cpt = cpt+1;    
        end
    end
end

TabGPS = zeros(cpt-1,1+32*4);    % Le tableau contient TOW (s)/ PRcode (m)/ PRphase (cycles) / Doppler (Hz) /CN0 (dBHz)
TabGLonass = zeros(cpt-1,1+32*4);
u=1; % pour les mesures
for i=1:length(trames(:,1))
    tailletrame = trames(i,1);
    str = trames(i,2:tailletrame+1);
    % On cherche les trames qui nous intéressent
    t = 4;
    flag_coup = 0; % flag qui nous indique si la dernière trame est coupée ou pas
    while t < length(str)
    
        if (str(t) == 21 && str(t-1) == 2 && str(t-2) == 98 && str(t-3) == 181) && u <cpt+1    % On a trouvé une trame
            
            if t < length(str)-1   % la dernière trame est coupée après les bytes indiquant la taille du payload
                
                taillepayload = bin2dec([dec2bin(str(t+2),8) dec2bin(str(t+1),8)]);
    
                if t < length(str)-taillepayload-1  % si la trame qui reste est plus grande que la taille du payload + les deux octets indiquant sa taille
    
                    % On extrait le TOW 
                    tmp = dec2bin([str(t+10) str(t+9) str(t+8) str(t+7) str(t+6) str(t+5) str(t+4) str(t+3)],8);   % t+3 = offset byte = 0
                    TOWbin = reshape(tmp.',1,[]);
                    TOW = ConvertBintoNumR8(TOWbin);
            
                    TabGPS(u,1) = TOW;
                    TabGLonass(u,1) = TOW;
                        
                    nbmesures = str(t+14);   % nombre de mesures à offset byte = 11 
            
                    % chaque bloc de mesures fait 32 octets
                    debut = t+19;   % 1ière octet de mesure
                    for n = 1:nbmesures
                    
                        % La pseudodistance d'abord
                        tmp = dec2bin([str(debut+7+(n-1)*32) str(debut+6+(n-1)*32) str(debut+5+(n-1)*32) str(debut+4+(n-1)*32) str(debut+3+(n-1)*32) str(debut+2+(n-1)*32) str(debut+1+(n-1)*32) str(debut+(n-1)*32)],8);
                        prMesbin = reshape(tmp.',1,[]);
                        PRcode = ConvertBintoNumR8(prMesbin);
                        % La phase
                        tmp = dec2bin([str(debut+15+(n-1)*32) str(debut+14+(n-1)*32) str(debut+13+(n-1)*32) str(debut+12+(n-1)*32) str(debut+11+(n-1)*32) str(debut+10+(n-1)*32) str(debut+9+(n-1)*32) str(debut+8+(n-1)*32)],8);
                        prphaseMesbin = reshape(tmp.',1,[]);
                        PRphase = ConvertBintoNumR8(prphaseMesbin);
                        % Le doppler
                        tmp = dec2bin([str(debut+19+(n-1)*32) str(debut+18+(n-1)*32) str(debut+17+(n-1)*32) str(debut+16+(n-1)*32)],8);
                        DopMesbin = reshape(tmp.',1,[]);
                        Doppler = ConvertBintoNumR4(DopMesbin);
                        % Le GNSS correspondant (GPS, Galileo, Glonass, Beidou)
                        GNSSid = str(debut+20+(n-1)*32);
                        % Le numéro de satellite
                        SVnum = str(debut+21+(n-1)*32);
                        % Le C/N0
                        CN0 = str(debut+26+(n-1)*32);
            
                        if GNSSid == 0  % Pour GPS
                            TabGPS(u,(SVnum-1)*4+2) = PRcode;
                            TabGPS(u,(SVnum-1)*4+3) = PRphase;
                            TabGPS(u,(SVnum-1)*4+4) = Doppler;
                            TabGPS(u,(SVnum-1)*4+5) = CN0;
                        end
            
                        if GNSSid == 6 % Pour Glonass
                            TabGLonass(u,(SVnum-1)*4+2) = PRcode;
                            TabGLonass(u,(SVnum-1)*4+3) = PRphase;
                            TabGLonass(u,(SVnum-1)*4+4) = Doppler;
                            TabGLonass(u,(SVnum-1)*4+5) = CN0;
                        end
                            
                    end
                    u=u+1;
                    t = t + 2 + 16+32*nbmesures + 2 + 3; % si on a trouvé une trame, on avance t jusqu'à la fin soit : 
                                                         % à t on est sur le deuxième byte d'identifiant, 
                                                         % on a donc t+2 pour se trouver sur le deuxième byte 
                                                         % de taille payload + taille du payload + 2 octets de checksum :
                                                         % t est sur le dernier octet de la trame
                                                         % + 3 octets pour se retrouver juste où il faut
                                                         % pour la recherche de la trame suivante
    
                else        % la trame est coupée avant d'être finie :         
                    Fin_trame = str(t-3:length(t));   % on la garde pour jointage éventuel avec la mesure suivante
                    flag_coup =1;                     % flag pour signaler qu'on a un bout en plus
                end
            else
                Fin_trame = str(t-3:length(t));   % on la garde pour jointage éventuel avec la mesure suivante
                flag_coup =1;                     % flag pour signaler qu'on a un bout en plus
            end
        end
        t=t+1; % On avance au début de recherche de la trame suivante
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

% On fait une structure qui contient TabGPS et le temps

DonneesPR = struct("TabGPS",TabGPS,"t_total",length(TabGPS(:,1)));








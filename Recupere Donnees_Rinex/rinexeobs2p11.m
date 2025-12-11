%--------------------------------------------------------------------------
%         
% Fonction d'extraction des données d'observation depuis un fichier Rinex v2.11
%
%--------------------------------------------------------------------------
% Lit un fichier d'observation RINEX au format 2.11 
% il réécrit les données  sous forme matricielle 
% The matrix is stored in outputfile

% Réécriture quasi intégrale de Kai Borre 04-18-96
%
%$Revision: 2023/04/20  $

% Units are either seconds, meters, or radians
% obsC1,obsL1,obsL2,obsD1,obsD2,obsS1,obsS2 sont des booléens qui permettent de définir si on veut
% ou pas récupérer l'observable en question
% d'information pour un satellite

% Nécessite les fonctions julday et gps_time

function nsat = rinexeobs2p11(obsfile,outputfile,obsC1,obsL1,obsL2,obsD1,obsD2,obsS1,obsS2)
% variables locales utiles

fide = fopen(obsfile);
head_lines = 0;
nbsats = 32;

% Dans le header on va chercher l'information sur le nombre d'observables et où
% se situent ceux qui nous intéressent

numlign = 1;

line = fgetl(fide);                                         % On récupère la première ligne
TrouveObs = strfind(line,'# / TYPES OF OBSERV');            % Condition d'arrêt

while isempty(TrouveObs)
    line = fgetl(fide);                                     % recherche ligne à ligne
    numlign = numlign+1;                                    % à chaque fois qu'on lit une ligne on ajoute 1 au nombre de lignes
    TrouveObs = strfind(line,'# / TYPES OF OBSERV');        % on cherche la première chaîne de caractères indiquant la ligne où se trouve le nombre d'observables
    
    
end

nbobs = str2double(line(1:6));                              % On récupère le nombre d'observables


% Ce qui nous intéresse ici est C1, L1, L2, D1, D2, S1 et S2
% (respectivement la pseudodistance sur L1 (m), la phase sur L1 (cycles),
% la phase sur L2 (cycles), le Doppler sur L1 (Hz), le Doppler sur L2 (Hz),
% le C/N0 sur L1 (dB) et le C/N0 sur L2 (dB)

% On cherche la position de chacune des valeurs qui nous intéressent sur la
% ligne d'observables. On va concaténer toutes les lignes en un seul
% tableau
ligneobs = line(7:length(line)-19);                                            % On affecte la première
TrouveObs = strfind(line,'# / TYPES OF OBSERV');            % Condition d'arrêt
line = fgetl(fide);
numlign = numlign+1;
while contains(line,'# / TYPES OF OBSERV')
    ligneobs = [ligneobs line(7:length(line)-19)];          % On concatène pour n'avoir qu'un tableau pour tester
    line = fgetl(fide);
    numlign = numlign+1;    
end

C1 = 0;
L1 = 0;
L2 = 0;
D1 = 0;
D2 = 0;
S1 = 0;
S2 = 0;

if obsC1 == 1                       % On veut récupérer la pseudodistance sur L1
    C1 = (strfind(ligneobs,'C1')+1)/6;    % On a bien la position de C1 dans la liste des observables (6 caractères par emplacement)
end

if obsL1 == 1                       % On veut récupérer la phase sur L1
    L1 = (strfind(ligneobs,'L1')+1)/6;      
end

if obsL2 == 1                       % On veut récupérer la phase sur L2
    L2 = (strfind(ligneobs,'L2')+1)/6;  
end

if obsD1 == 1                       % On veut récupérer le Doppler sur L1
    D1 = (strfind(ligneobs,'D1')+1)/6;      
end

if obsD2 == 1                       % On veut récupérer le Doppler sur L2
    D2 = (strfind(ligneobs,'D2')+1)/6;  
end

if obsS1 == 1                       % On veut récupérer le SNR sur L1
    S1 = (strfind(ligneobs,'S1')+1)/6;  
end

if obsS2 == 1                       % On veut récupérer le SNR sur L2
    S2 = (strfind(ligneobs,'S2')+1)/6;  
end

while 1  % We skip header
   line = fgetl(fide);
   numlign = numlign+1;
   answer = findstr(line,'END OF HEADER');
   if ~isempty(answer)
       break;	
   end
end

head_lines=numlign;                             % number of lines of the RINEX navigation file header

% Notre premier objectif est de compter les lignes de données pour nos
% observables, soit le nombre d'instants.

nbinstants = 0;                                 % le nombre de ligne de données à récupérer qui correspond au nombre d'instants récupérés
line = fgetl(fide);                             % On lit la toute première ligne de données
numlign =numlign+1;
nblignesat = fix(nbobs/5)+1;                    % Le nombre d'observables nous donne le nombre de ligne de données par satellite
Debutligne = line(1:6);                         % On récupère le début de la ligne correspondant à la date sous format 'année mois' pour s'assurer qu'on lit la bonne ligne et qu'on squizze les lignes inutile insérées

while ~feof(fide)

    nbsatlign = str2double(line(31:32));        % On récupère le nombre de satellites dans l'occurence présente
    if nbsatlign >12
       line = fgetl(fide);                      % si le nombre de satellites est plus grand que 12, on doit passer une ligne de plus
       numlign =numlign+1;        
    end
    
    for i=1:nblignesat*nbsatlign
       line = fgetl(fide);                      % On passe les lignes jusqu'à l'instant suivant
       numlign =numlign+1;
    end

    nbinstants = nbinstants+1;   
    
    if ~feof(fide)                              % Si on n'est pas à la fin du fichier
        line = fgetl(fide);                     % On lit la toute première ligne de données pour le coup d'après
        numlign =numlign+1;
        while ~strcmp(Debutligne,line(1:6))
            line = fgetl(fide);                  % tant qu'on est pas à nouveau sur une ligne de données, on passe les lignes
            numlign =numlign+1;           
        end
    end

end

% Dans le tableau de données on veut récupérer 7 paramètres : PR code L1,
% PR phase L1, PR phase L2, Doppler L1, Doppler L2, C/N0 L1, C/N0 L2

TableauDonneesGPS = zeros(nbinstants+1,7*32+1);       % On a un tableau qui a nbinstants lignes (+1 pour l'en-tête) et 7*32 colonnes (+1 pour le TOW)
TableauDonneesGalileo = zeros(nbinstants+1,7*32+1);    % On a un tableau qui a nbinstants lignes (+1 pour l'en-tête) et 2*32 colonnes (+1 pour le TOW)

% On repart pour un tour

fide = fopen(obsfile);
for i =1:head_lines
    line = fgetl(fide);
end

line = fgetl(fide);                             % On lit la toute première ligne de données
Debutligne = line(1:6);                         % On récupère le début de la ligne correspondant à la date sous format 'année mois' pour s'assurer qu'on lit la bonne ligne et qu'on squizze les lignes inutile insérées
n = 1;                                          % n correspond à l'instant considéré

while ~feof(fide)

    TabIndSatGPS = zeros(1,32);                 % Mise à 0 du tableau indiquant les numéros de satellite GPS
    TabIndSatGalileo = zeros(1,32);             % Mise à 0 du tableau indiquant les numéros de satellites Galileo

    nbsatlign = str2double(line(31:32));        % On récupère le nombre de satellites dans l'occurence présente

   % On récupère la date
   year = str2double(line(2:3))+2000;
   month = str2double(line(5:6));
   day = str2double(line(8:9));
   hour = str2double(line(11:12));
   minute = str2double(line(14:15));
   second = str2double(line(17:26));
   jd = julday(year,month,day,hour + minute/60 + second/3600); % conversion de la date en temps GPS
   [week,tow] = gps_time(jd);
   TableauDonneesGPS(n,1) = mod(tow,604800);
   TableauDonneesGalileo(n,1) = mod(tow,604800);
   
   nbsatGPS = 0;
   nbsatGalileo = 0;

   if nbsatlign <= 12                       % Il y a moins de 12 satellites ou exactement 12 satellites
      for i=1:nbsatlign                            
            
        if line(33+3*(i-1)) == 'G'
            TabIndSatGPS(1+nbsatGPS) = str2double(line(31+3*i:32+3*i));   % G pour les satellite GPS
            nbsatGPS = nbsatGPS+1;
        elseif line(33+3*(i-1)) == 'E'
            TabIndSatGalileo(1+nbsatGalileo) = str2double(line(31+3*i:32+3*i)); % E pour les satellite Galileo
            nbsatGalileo = nbsatGalileo+1;
       end

     end

   end

   if 12 < nbsatlign && nbsatlign<= 24        % Il y a entre 13 et 24 satellites
    for i=1:12                             % On remplit la première ligne
                
        if line(33+3*(i-1)) == 'G'
            TabIndSatGPS(1+nbsatGPS) = str2double(line(31+3*i:32+3*i));   % G pour les satellite GPS
            nbsatGPS = nbsatGPS+1;
        elseif line(33+3*(i-1)) == 'E'
            TabIndSatGalileo(1+nbsatGalileo) = str2double(line(31+3*i:32+3*i)); % E pour les satellite Galileo
            nbsatGalileo = nbsatGalileo+1;
        end

    end
    line = fgetl(fide);                     % On passe à la ligne d'après

    for i=1:nbsatlign-12                             % On remplit la deuxième ligne
                
        if line(33+3*(i-1)) == 'G'
            TabIndSatGPS(1+nbsatGPS) = str2double(line(31+3*i:32+3*i));   % G pour les satellite GPS
            nbsatGPS = nbsatGPS+1;
        elseif line(33+3*(i-1)) == 'E'
            TabIndSatGalileo(1+nbsatGalileo) = str2double(line(31+3*i:32+3*i)); % E pour les satellite Galileo
            nbsatGalileo = nbsatGalileo+1;
        end

    end

   end


   if 24 < nbsatlign && nbsatlign<= 36        % Il y a entre 25 et 36 satellites
    
     for i=1:12                             % On remplit la première ligne
                
        if line(33+3*(i-1)) == 'G'
            TabIndSatGPS(1+nbsatGPS) = str2double(line(31+3*i:32+3*i));   % G pour les satellite GPS
            nbsatGPS = nbsatGPS+1;
        elseif line(33+3*(i-1)) == 'E'
            TabIndSatGalileo(1+nbsatGalileo) = str2double(line(31+3*i:32+3*i)); % E pour les satellite Galileo
            nbsatGalileo = nbsatGalileo+1;
        end

    end
    line = fgetl(fide);                     % On passe à la ligne d'après

    for i=1:nbsatlign-12                             % On remplit la deuxième ligne
                
        if line(33+3*(i-1)) == 'G'
            TabIndSatGPS(1+nbsatGPS) = str2double(line(31+3*i:32+3*i));   % G pour les satellite GPS
            nbsatGPS = nbsatGPS+1;
        elseif line(33+3*(i-1)) == 'E'
            TabIndSatGalileo(1+nbsatGalileo) = str2double(line(31+3*i:32+3*i)); % E pour les satellite Galileo
            nbsatGalileo = nbsatGalileo+1;
        end

    end
    line = fgetl(fide);                     % On passe à la ligne d'après
    for i=1:nbsatlign-24                             % On remplit la deuxième ligne
                
        if line(33+3*(i-1)) == 'G'
            TabIndSatGPS(1+nbsatGPS) = str2double(line(31+3*i:32+3*i));   % G pour les satellite GPS
            nbsatGPS = nbsatGPS+1;
        elseif line(33+3*(i-1)) == 'E'
            TabIndSatGalileo(1+nbsatGalileo) = str2double(line(31+3*i:32+3*i)); % E pour les satellite Galileo
            nbsatGalileo = nbsatGalileo+1;
        end

    end


   end



   for i=1:nbsatGPS                        % On commence par les satellites GPS (ils sont toujours en premier)
        % On récupère le nombre de lignes total correspondant à ce
        % satellite qu'on met dans un tableau
       Tabligne = char('                                                                                ');   % Un tableau de lignes vides pour gérer les cas où les données sont absentes et le nombre de caractères est inférieur à 80
       Tablignes = Tabligne;

       if nblignesat > 1
           for k =2:nblignesat
                Tablignes = [Tablignes;Tabligne]; 
           end
       end
       
       % à ce stade, on a normalement un tableau prêt à être rempli

       for l=1:nblignesat
            
            line = fgetl(fide);                                 % On récupère la ligne de données            
            longligne = size(line,2);                           % On récupère la taille de la ligne

            if longligne > 0

                Tablignes(l,1:longligne) = line;                % On remplit la ligne si elle existe

            end

       end

       
       % On récupère les données voulues (si l'observable > 0, alors c'est
       % qu'on le veut

       if C1 > 0
        
            ValObs = str2double(Tablignes(fix(C1/5)+1,1+(mod(C1,6)+fix(C1/6)-1)*16:1+(mod(C1,6)+fix(C1/6)-1)*16+13));
            if ~isnan(ValObs)
                TableauDonneesGPS(n,1+(TabIndSatGPS(i)-1)*7+1) = ValObs;
            end  
       end

       if L1 > 0
            ValObs = str2double(Tablignes(fix(L1/5)+1,1+(mod(L1,6)+fix(L1/6)-1)*16:1+(mod(L1,6)+fix(L1/6)-1)*16+13));
            if ~isnan(ValObs)
                TableauDonneesGPS(n,1+(TabIndSatGPS(i)-1)*7+2) = ValObs;
            end 
       end

       if L2 > 0 
            ValObs = str2double(Tablignes(fix(L2/5)+1,1+(mod(L2,6)+fix(L2/6)-1)*16:1+(mod(L2,6)+fix(L2/6)-1)*16+13));
            if ~isnan(ValObs)
                TableauDonneesGPS(n,1+(TabIndSatGPS(i)-1)*7+3) = ValObs;
            end   
       end
       if D1 > 0 
            ValObs = str2double(Tablignes(fix(D1/5)+1,1+(mod(D1,6)+fix(D1/6)-1)*16:1+(mod(D1,6)+fix(D1/6)-1)*16+13));
            if ~isnan(ValObs)
                TableauDonneesGPS(n,1+(TabIndSatGPS(i)-1)*7+4) = ValObs;
            end 
       end
       if D2 > 0
            ValObs = str2double(Tablignes(fix(D2/5)+1,1+(mod(D2,6)+fix(D2/6)-1)*16:1+(mod(D2,6)+fix(D2/6)-1)*16+13));
            if ~isnan(ValObs)
                TableauDonneesGPS(n,1+(TabIndSatGPS(i)-1)*7+5) = ValObs;
            end 
       end

       if S1 > 0 
            ValObs = str2double(Tablignes(fix(S1/5)+1,1+(mod(S1,6)+fix(S1/6)-1)*16:1+(mod(S1,6)+fix(S1/6)-1)*16+13));
            if ~isnan(ValObs)
                TableauDonneesGPS(n,1+(TabIndSatGPS(i)-1)*7+6) = ValObs;
            end 
       end

       if S2 > 0 
            ValObs = str2double(Tablignes(fix(S2/5)+1,1+(mod(S2,6)+fix(S2/6)-1)*16:1+(mod(S2,6)+fix(S2/6)-1)*16+13));
            if ~isnan(ValObs)
                TableauDonneesGPS(n,1+(TabIndSatGPS(i)-1)*7+7) = ValObs;
            end  
       end

   end

   if nbsatGalileo > 0                         % S'il y a des satellites Galileo
       for i=1:nbsatGalileo                       % On poursuit avec Galiléo
            % On récupère le nombre de lignes total correspondant à ce
            % satellite qu'on met dans un tableau
           Tabligne = char('                                                                                ');   % Un tableau de lignes vides pour gérer les cas où les données sont absentes et le nombre de caractères est inférieur à 80
           Tablignes = Tabligne;
    
           if nblignesat > 1
               for k =2:nblignesat
                    Tablignes = [Tablignes;Tabligne]; 
               end
           end
           
           % à ce stade, on a normalement un tableau prêt à être rempli
    
           for l=1:nblignesat
                
                line = fgetl(fide);                                 % On récupère la ligne de données            
                longligne = size(line,2);                           % On récupère la taille de la ligne
    
                if longligne > 0
    
                    Tablignes(l,1:longligne) = line;                % On remplit la ligne si elle existe
    
                end
    
           end
           
           % On récupère les données voulues
            if C1 > 0
                ValObs = str2double(Tablignes(fix(C1/5)+1,1+(mod(C1,6)+fix(C1/6)-1)*16:1+(mod(C1,6)+fix(C1/6)-1)*16+13));
                if ~isnan(ValObs)
                    TableauDonneesGalileo(n,1+(TabIndSatGalileo(i)-1)*7+1) = ValObs;
                end
            end
            if L1 > 0 
                ValObs = str2double(Tablignes(fix(L1/5)+1,1+(mod(L1,6)+fix(L1/6)-1)*16:1+(mod(L1,6)+fix(L1/6)-1)*16+13));
                if ~isnan(ValObs)
                    TableauDonneesGalileo(n,1+(TabIndSatGalileo(i)-1)*7+2) = ValObs;
                end 
            end
            if L2 > 0 
                ValObs = str2double(Tablignes(fix(L2/5)+1,1+(mod(L2,6)+fix(L2/6)-1)*16:1+(mod(L2,6)+fix(L2/6)-1)*16+13));
                if ~isnan(ValObs)
                    TableauDonneesGalileo(n,1+(TabIndSatGalileo(i)-1)*7+3) = ValObs;
                end  

            end
            if D1 > 0
                ValObs = str2double(Tablignes(fix(D1/5)+1,1+(mod(D1,6)+fix(D1/6)-1)*16:1+(mod(D1,6)+fix(D1/6)-1)*16+13));
                if ~isnan(ValObs)
                    TableauDonneesGalileo(n,1+(TabIndSatGalileo(i)-1)*7+4) = ValObs;
                end 
                
            end
            if D2 > 0
                ValObs = str2double(Tablignes(fix(D2/5)+1,1+(mod(D2,6)+fix(D2/6)-1)*16:1+(mod(D2,6)+fix(D2/6)-1)*16+13));
                if ~isnan(ValObs)
                    TableauDonneesGalileo(n,1+(TabIndSatGalileo(i)-1)*7+5) = ValObs;
                end 
            end
            if S1 > 0 
                ValObs = str2double(Tablignes(fix(S1/5)+1,1+(mod(S1,6)+fix(S1/6)-1)*16:1+(mod(S1,6)+fix(S1/6)-1)*16+13));
                if ~isnan(ValObs)
                    TableauDonneesGalileo(n,1+(TabIndSatGalileo(i)-1)*7+6) = ValObs;
                end
            end
            if S2 > 0    
                ValObs = str2double(Tablignes(fix(S2/5)+1,1+(mod(S2,6)+fix(S2/6)-1)*16:1+(mod(S2,6)+fix(S2/6)-1)*16+13));
                if ~isnan(ValObs)
                    TableauDonneesGalileo(n,1+(TabIndSatGalileo(i)-1)*7+7) = ValObs;
                end
            end
       end

   end
    n = n+1;
    if ~feof(fide)                              % Si on n'est pas à la fin du fichier
        line = fgetl(fide);                     % On lit la toute première ligne de données pour le coup d'après

        while ~strcmp(line(1:6),Debutligne)    % On saute les lignes lorsque celles-ci ne correspondent pas à celle qu'on attend
             line = fgetl(fide); 
        end
    end    
end


status = fclose(fide);

fidu = fopen(outputfile,'w');
count = fwrite(fidu,TableauDonneesGPS,'double');
nsat = nbsats;
fclose all;
%%%%%%%%% end rinexeobs2p11.m %%%%%%%%%
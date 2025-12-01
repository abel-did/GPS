%--------------------------------------------------------------------------
%         
%           Fonction qui extrait les données ionosphériques
%           à partir d'un fichier de navigation Rinex 2.11
%
%--------------------------------------------------------------------------

% Données d'entrée : 

%        fichier Rinex

function [Iono] = rinexe_iono_2p11(ephemerisfile)

fide = fopen(ephemerisfile);            % On ouvre le fichier

% Section pour lire l'en-tête (header)

line = fgetl(fide);
cpt = 1;
while contains(line,'END OF HEADER') ~= 1 && cpt < 10 % tant qu'on n'a pas atteint la fin du header
   
    if contains(line,'ION ALPHA') == 1

        Iono(1) = str2num(line(3:14));  % alpha0
        Iono(2) = str2num(line(15:26)); % alpha1
        Iono(3) = str2num(line(27:38)); % alpha2
        Iono(4) = str2num(line(39:50)); % alpha3
    end

    if contains(line,'ION BETA') == 1

        Iono(5) = str2num(line(3:14)); % beta0
        Iono(6) = str2num(line(15:26)); % beta1
        Iono(7) = str2num(line(27:38)); % beta2
        Iono(8) = str2num(line(39:50)); % beta3
    end
   line = fgetl(fide);
   cpt=cpt+1;
end

